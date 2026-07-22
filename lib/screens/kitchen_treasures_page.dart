import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../config/feature_flags.dart';
import '../theme/app_theme.dart';
import '../exceptions/free_recipe_limit_exception.dart';
import '../exceptions/generation_limit_exception.dart';
import '../services/ai_settings_service.dart';
import '../services/audio_settings_service.dart';
import '../services/openai_service.dart';
import '../services/auth_service.dart';
import '../services/pending_generation_request_store.dart';
import '../services/recipe_generation_service.dart';
import '../services/recipe_access_service.dart';
import '../models/recipe_model.dart';
import '../utils/app_message_dialog.dart';
import '../utils/image_picker_helper.dart';
import '../utils/ingredient_emoji_resolver.dart';
import '../widgets/cooking_animation.dart';
import '../widgets/kitchen_savings_card.dart';
import '../widgets/premium_audio_button.dart';
import '../widgets/web_image.dart';
import 'detected_ingredients_page.dart';
import 'kitchen_savings_details_page.dart';
import 'pricing_page.dart';
import 'recipe_detail_page.dart';
import '../services/voice_guide_service.dart';
import '../widgets/voice_guide_route_aware.dart';

class KitchenTreasuresPage extends StatefulWidget {
  /// When true, immediately opens the Scan Fridge camera/gallery chooser.
  final bool openScanFridge;

  const KitchenTreasuresPage({super.key, this.openScanFridge = false});

  @override
  State<KitchenTreasuresPage> createState() => _KitchenTreasuresPageState();
}

class _KitchenTreasuresPageState extends State<KitchenTreasuresPage>
    with SingleTickerProviderStateMixin, VoiceGuideRouteAware {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  final AISettingsService _settingsService = AISettingsService();
  final AuthService _authService = AuthService();
  final RecipeGenerationService _recipeGenerationService =
      RecipeGenerationService();

  bool _isGenerating = false;
  bool _isOpeningPaywall = false;
  bool _isDetecting = false;

  /// True when the current ingredient list came from Scan Fridge / image detect.
  bool _ingredientsFromScan = false;
  List<RecipeModel> _generatedRecipes = [];
  bool _showRecipes = false;

  String get _accessSource =>
      _ingredientsFromScan ? 'scanFridge' : 'kitchenTreasures';

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.scanIngredients;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _fadeController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resumePendingGenerationIfReady();
      if (widget.openScanFridge) {
        _promptScanFridgeActions();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initVoiceGuide();
  }

  @override
  void dispose() {
    unawaited(AudioSettingsService.instance.stopCookingGenerationSound());
    disposeVoiceGuide();
    _fadeController.dispose();
    _ingredientController.dispose();
    super.dispose();
  }

  Future<void> _resumePendingGenerationIfReady() async {
    final pending = await PendingGenerationRequestStore.instance.load();
    if (pending == null || pending.source != 'ingredients') return;
    if (!await _recipeGenerationService.hasPaidSubscription()) return;

    setState(() {
      _ingredients
        ..clear()
        ..addAll(pending.ingredients);
    });

    await PendingGenerationRequestStore.instance.clear();
    if (!mounted) return;
    await _executeGeneration();
  }

  Future<void> _generateRecipes() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ingredient!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isGenerating || _isOpeningPaywall) return;

    try {
      await _recipeGenerationService.ensureCanGenerate(source: _accessSource);
    } on FreeRecipeLimitException {
      await _openPaywallThenMaybeGenerate();
      return;
    } on GenerationLimitException catch (e) {
      await _showGenerationError(e);
      return;
    } catch (e) {
      await _showGenerationError(e);
      return;
    }

    await _executeGeneration();
  }

  Future<void> _openPaywallThenMaybeGenerate() async {
    if (_isOpeningPaywall) return;
    _isOpeningPaywall = true;

    try {
      await PendingGenerationRequestStore.instance.save(
        PendingGenerationRequest(
          source: 'ingredients',
          ingredients: List<String>.from(_ingredients),
        ),
      );

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PricingPage()),
      );

      if (!mounted) return;

      if (await _recipeGenerationService.hasPaidSubscription()) {
        await PendingGenerationRequestStore.instance.clear();
        await _executeGeneration();
      }
    } finally {
      _isOpeningPaywall = false;
    }
  }

  Future<void> _executeGeneration() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: AppTheme.darkBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const CookingAnimation(
            message: 'Finding recipes with your ingredients...',
          ),
        );
      },
    );

    await AudioSettingsService.instance.startCookingGenerationSound();

    try {
      await _recipeGenerationService.ensureCanGenerate(source: _accessSource);

      final settings = await _settingsService.getSettings();

      if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
        throw Exception(
          'OpenAI API key not configured. Please ask admin to configure it in Admin Settings.',
        );
      }

      final user = _authService.currentUser;

      final openaiService = OpenAIService(settings);

      final recipes = await openaiService.generateRecipesFromIngredients(
        ingredients: _ingredients,
        numberOfRecipes: 1,
      );

      List<RecipeModel> recipesWithImages = [];
      for (var recipe in recipes) {
        String? imageUrl;

        try {
          imageUrl = await openaiService.generateRecipeImage(
            recipe.title,
            'Professional food photography, high quality, well-lit, appetizing ${recipe.cuisine} cuisine dish, restaurant presentation, realistic, natural lighting, detailed texture',
            userId: user == null || user.isAnonymous ? 'guest' : user.uid,
          );
        } catch (e) {
          debugPrint('⚠️ Image generation failed: $e');
        }

        final recipeWithUser = RecipeModel(
          id: recipe.id,
          userId: user == null || user.isAnonymous ? 'guest' : user.uid,
          title: recipe.title,
          description: recipe.description,
          cuisine: recipe.cuisine,
          mealType: recipe.mealType,
          difficulty: recipe.difficulty,
          prepTime: recipe.prepTime,
          cookTime: recipe.cookTime,
          totalTime: recipe.prepTime + recipe.cookTime,
          servings: recipe.servings,
          ingredients: recipe.ingredients,
          instructions: recipe.instructions,
          dietary: recipe.dietary,
          nutrition: recipe.nutrition,
          imageUrl: imageUrl,
          createdAt: recipe.createdAt,
        );

        RecipeModel savedRecipe = await _recipeGenerationService
            .persistGeneratedRecipe(recipeWithUser, source: _accessSource);
        recipesWithImages.add(savedRecipe);
      }

      await PendingGenerationRequestStore.instance.clear();

      if (mounted) {
        Navigator.of(context).pop();

        // Same post-success flow as standard Generate Recipe: open the locked
        // RecipeDetailPage (image visible; ingredients/instructions/nutrition
        // blurred until subscription) instead of an unlocked inline preview.
        final savedRecipe = recipesWithImages.first;
        final isRegistered = user != null && !user.isAnonymous;
        final missingIngredients = _getMissingIngredients(savedRecipe);

        if (isRegistered) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      savedRecipe.imageUrl != null &&
                              savedRecipe.imageUrl!.isNotEmpty
                          ? 'Recipe saved to My Recipes!'
                          : 'Recipe saved! (Image generation skipped)',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.visibility_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recipe preview generated! Sign in to save it to My Recipes.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => RecipeDetailPage(
                  recipe: savedRecipe,
                  missingIngredients:
                      missingIngredients.isNotEmpty ? missingIngredients : null,
                ),
          ),
        );
      }
    } on FreeRecipeLimitException {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isGenerating = false);
        await _openPaywallThenMaybeGenerate();
      }
    } catch (e) {
      await RecipeAccessService.instance.recordSuccessfulGeneration(
        source: _accessSource,
        generationSucceeded: false,
      );
      if (mounted) {
        Navigator.of(context).pop();
        await _showGenerationError(e);
      }
    } finally {
      await AudioSettingsService.instance.stopCookingGenerationSound();
      if (mounted && _isGenerating) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _showGenerationError(Object error) async {
    final message = AppMessageDialog.cleanErrorMessage(error);

    if (error is FreeRecipeLimitException) {
      await _openPaywallThenMaybeGenerate();
      return;
    }

    if (AppMessageDialog.isGenerationLimitError(error)) {
      await AppMessageDialog.showGenerationLimit(
        context: context,
        message: message,
        onViewPlans: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PricingPage()),
          );
        },
      );
      return;
    }

    await AppMessageDialog.showError(context: context, message: message);
  }

  Future<void> _scanFromCamera() async {
    try {
      final image = await ImagePickerHelper.pickXFileFromCamera();
      if (image != null) await _detectFromXFile(image);
    } catch (e) {
      if (!mounted) return;
      await AppMessageDialog.showError(
        context: context,
        message: AppMessageDialog.cleanErrorMessage(e),
      );
    }
  }

  Future<void> _scanFromGallery() async {
    try {
      final image = await ImagePickerHelper.pickXFileFromGallery();
      if (image != null) await _detectFromXFile(image);
    } catch (e) {
      if (!mounted) return;
      await AppMessageDialog.showError(
        context: context,
        message: AppMessageDialog.cleanErrorMessage(e),
      );
    }
  }

  /// Opens the Scan Fridge entry actions (camera / gallery) used by the
  /// center nav Scan shortcut. Reuses the same scan handlers as the card.
  Future<void> _promptScanFridgeActions() async {
    if (!mounted || _isDetecting) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan Fridge',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Scan ingredients with your camera or choose a photo from your gallery.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.greyText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _PolishedActionButton(
                  label: 'Scan with Camera',
                  icon: Icons.photo_camera_outlined,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _scanFromCamera();
                  },
                  filled: true,
                  isMobile: true,
                ),
                const SizedBox(height: 10),
                _PolishedActionButton(
                  label: 'Choose from Gallery',
                  icon: Icons.photo_library_outlined,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _scanFromGallery();
                  },
                  filled: false,
                  isMobile: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _detectFromXFile(XFile image) async {
    if (_isDetecting) return;

    setState(() => _isDetecting = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            backgroundColor: AppTheme.darkBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.primaryGreen),
                  SizedBox(height: 20),
                  Text(
                    'Scanning ingredients with AI...',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
    );

    try {
      final settings = await _settingsService.getSettings();
      if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
        throw Exception(
          'OpenAI API key not configured. Please ask admin to configure it in Admin Settings.',
        );
      }

      final bytes = await image.readAsBytes();
      final mimeType = image.mimeType ?? 'image/jpeg';
      final openaiService = OpenAIService(settings);
      final detected = await openaiService.detectIngredientsFromImage(
        imageBytes: bytes,
        mimeType: mimeType,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (detected.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No ingredients detected. Try another photo.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final reviewedIngredients = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder: (_) => DetectedIngredientsPage(initialIngredients: detected),
        ),
      );

      if (!mounted || reviewedIngredients == null) return;

      setState(() {
        _ingredients
          ..clear()
          ..addAll(reviewedIngredients);
        _ingredientsFromScan = true;
        _showRecipes = false;
      });

      await _generateRecipes();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        await AppMessageDialog.showError(
          context: context,
          message: AppMessageDialog.cleanErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetecting = false);
    }
  }

  void _openKitchenSavings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                kKitchenSavingsFreeForTesting
                    ? const KitchenSavingsDetailsPage()
                    : const PricingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;

    double horizontalPadding;
    double verticalPadding;

    if (isMobile) {
      horizontalPadding = 16.0;
      verticalPadding = 16.0;
    } else if (isTablet) {
      horizontalPadding = 48.0;
      verticalPadding = 32.0;
    } else {
      horizontalPadding = screenWidth * 0.08;
      verticalPadding = 48.0;
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 12 : verticalPadding * 0.75,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const PremiumAudioButton(size: 40, iconSize: 20),
                    ],
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Kitchen Treasures',
                          style: TextStyle(
                            fontSize: isMobile ? 25.5 : 33,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isMobile ? 8 : 10),
                        Text(
                          'Turn your ingredients into delicious AI-powered recipes.',
                          style: TextStyle(
                            fontSize: isMobile ? 13.5 : 15,
                            color: AppTheme.greyText,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 22 : 28),
                  if (!_showRecipes) ...[
                    _buildScanSection(isMobile),
                    SizedBox(height: isMobile ? 18 : 22),
                    _buildOrDivider(),
                    SizedBox(height: isMobile ? 18 : 22),
                    _buildManualSection(isMobile),
                    SizedBox(height: isMobile ? 22 : 28),
                    KitchenSavingsCard(onTap: _openKitchenSavings),
                    if (_ingredients.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildRevealButton(isMobile),
                    ],
                  ] else ...[
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showRecipes = false;
                              _generatedRecipes = [];
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.primaryGreen,
                          ),
                          label: const Text(
                            'Back to Ingredients',
                            style: TextStyle(color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildRecipesList(isMobile),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.document_scanner_rounded,
              size: isMobile ? 20 : 22,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(width: 8),
            Text(
              'Scan Your Fridge',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Take a photo and let AI detect your ingredients instantly.',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: AppTheme.greyText,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Material(
          color: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _isDetecting ? null : _scanFromCamera,
            borderRadius: BorderRadius.circular(20),
            splashColor: AppTheme.primaryGreen.withValues(alpha: 0.10),
            highlightColor: AppTheme.primaryGreen.withValues(alpha: 0.05),
            child: Ink(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                isMobile ? 18 : 24,
                isMobile ? 18 : 22,
                isMobile ? 18 : 24,
                isMobile ? 16 : 20,
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: isMobile ? 58 : 64,
                    height: isMobile ? 58 : 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryGreen.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
                          blurRadius: 14,
                          spreadRadius: 0.5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.document_scanner_rounded,
                      size: isMobile ? 26 : 28,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 14),
                  Text(
                    'Scan Ingredients',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Point your camera at ingredients and let AI identify them instantly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 13.5,
                      color: AppTheme.greyText,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: isMobile ? 16 : 18),
                  _PolishedActionButton(
                    label: 'Scan with Camera',
                    icon: Icons.photo_camera_outlined,
                    onPressed: _isDetecting ? null : _scanFromCamera,
                    filled: true,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 10),
                  _PolishedActionButton(
                    label: 'Choose from Gallery',
                    icon: Icons.photo_library_outlined,
                    onPressed: _isDetecting ? null : _scanFromGallery,
                    filled: false,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: AppTheme.primaryGreen.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppTheme.greyText,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: AppTheme.primaryGreen.withValues(alpha: 0.18),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildManualSection(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Ingredients Manually',
            style: TextStyle(
              fontSize: isMobile ? 16.5 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter the ingredients you already have.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.greyText,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Salmon, Spinach...',
                    hintStyle: TextStyle(
                      color: AppTheme.greyText.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackground.withValues(alpha: 0.55),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: _PolishedActionButton(
                  label: 'Add',
                  icon: Icons.add_rounded,
                  onPressed: _addIngredient,
                  filled: true,
                  isMobile: isMobile,
                  compact: true,
                ),
              ),
            ],
          ),
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _ingredients.map((ingredient) {
                    final emoji = IngredientEmojiResolver.resolve(ingredient);
                    return Chip(
                      avatar: Text(emoji, style: const TextStyle(fontSize: 14)),
                      label: Text(ingredient),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                      onDeleted: () {
                        setState(() {
                          _ingredients.remove(ingredient);
                        });
                      },
                      backgroundColor: AppTheme.primaryGreen.withValues(
                        alpha: 0.18,
                      ),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.45),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevealButton(bool isMobile) {
    return _PolishedActionButton(
      label: _isGenerating ? 'Finding Recipes...' : 'Generate Recipes',
      icon: _isGenerating ? null : Icons.auto_awesome_rounded,
      onPressed: _isGenerating ? null : _generateRecipes,
      filled: true,
      isMobile: isMobile,
      fullWidth: true,
      loading: _isGenerating,
    );
  }

  Widget _buildRecipesList(bool isMobile) {
    if (_generatedRecipes.isEmpty) {
      return const Center(
        child: Text(
          'No recipes generated yet',
          style: TextStyle(color: AppTheme.greyText),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Recipe',
          style: TextStyle(
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Based on your available ingredients',
          style: TextStyle(fontSize: 14, color: AppTheme.greyText),
        ),
        const SizedBox(height: 32),
        ..._generatedRecipes.map((recipe) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildRecipeCard(
              context,
              recipe: recipe,
              isMobile: isMobile,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRecipeCard(
    BuildContext context, {
    required RecipeModel recipe,
    required bool isMobile,
  }) {
    final missingIngredients = _getMissingIngredients(recipe);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => RecipeDetailPage(
                  recipe: recipe,
                  missingIngredients:
                      missingIngredients.isNotEmpty ? missingIngredients : null,
                ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child:
                  recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? kIsWeb
                          ? WebImage(
                            imageUrl: recipe.imageUrl!,
                            height: isMobile ? 200 : 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage(isMobile);
                            },
                          )
                          : Image.network(
                            recipe.imageUrl!,
                            height: isMobile ? 200 : 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: isMobile ? 200 : 250,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: AppTheme.cardBackground,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage(isMobile);
                            },
                          )
                      : _buildPlaceholderImage(isMobile),
            ),
            Padding(
              padding: EdgeInsets.all(isMobile ? 20.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'READY TO COOK',
                          style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (missingIngredients.isEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.amber,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'ALL INGREDIENTS',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe.title,
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.greyText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${recipe.prepTime + recipe.cookTime} min',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (missingIngredients.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_basket,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Missing ${missingIngredients.length} ingredient${missingIngredients.length > 1 ? 's' : ''}:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                missingIngredients.take(5).map((ingredient) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      ingredient,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                          if (missingIngredients.length > 5) ...[
                            const SizedBox(height: 4),
                            Text(
                              '+${missingIngredients.length - 5} more',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.withValues(alpha: 0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(bool isMobile) {
    return Container(
      height: isMobile ? 200 : 250,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen.withValues(alpha: 0.3),
            AppTheme.cardBackground,
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.restaurant, size: 80, color: AppTheme.primaryGreen),
      ),
    );
  }

  List<String> _getMissingIngredients(RecipeModel recipe) {
    final userIngredientsLower =
        _ingredients.map((i) => i.toLowerCase()).toList();
    final missing = <String>[];

    for (var ingredient in recipe.ingredients) {
      final ingredientName = ingredient['name']?.toString().toLowerCase() ?? '';

      bool hasIngredient = userIngredientsLower.any((userIng) {
        return ingredientName.contains(userIng) ||
            userIng.contains(ingredientName);
      });

      if (!hasIngredient && ingredientName.isNotEmpty) {
        missing.add(ingredient['name']?.toString() ?? '');
      }
    }

    return missing;
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientsFromScan = false;
        _ingredientController.clear();
      });
    }
  }
}

class _PolishedActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool isMobile;
  final bool compact;
  final bool fullWidth;
  final bool loading;

  const _PolishedActionButton({
    required this.label,
    this.icon,
    required this.onPressed,
    required this.filled,
    required this.isMobile,
    this.compact = false,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  State<_PolishedActionButton> createState() => _PolishedActionButtonState();
}

class _PolishedActionButtonState extends State<_PolishedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = _pressed && enabled ? 0.97 : 1.0;
    final radius = BorderRadius.circular(12);

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: widget.compact ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (widget.loading) ...[
          SizedBox(
            width: widget.isMobile ? 16 : 18,
            height: widget.isMobile ? 16 : 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color:
                  widget.filled
                      ? AppTheme.darkBackground
                      : AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.icon != null) ...[
          Icon(
            widget.icon,
            size: 18,
            color:
                widget.filled ? AppTheme.darkBackground : AppTheme.primaryGreen,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontSize: widget.compact ? 14 : (widget.isMobile ? 14.5 : 15.5),
            fontWeight: FontWeight.w600,
            color:
                widget.filled ? AppTheme.darkBackground : AppTheme.primaryGreen,
          ),
        ),
      ],
    );

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow:
              widget.filled && enabled
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color:
              widget.filled
                  ? (enabled
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withValues(alpha: 0.45))
                  : Colors.transparent,
          borderRadius: radius,
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: radius,
            splashColor:
                widget.filled
                    ? Colors.white.withValues(alpha: 0.16)
                    : AppTheme.primaryGreen.withValues(alpha: 0.12),
            highlightColor:
                widget.filled
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppTheme.primaryGreen.withValues(alpha: 0.06),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                border:
                    widget.filled
                        ? null
                        : Border.all(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.45),
                        ),
              ),
              child: Container(
                width:
                    widget.fullWidth || !widget.compact
                        ? double.infinity
                        : null,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 14 : 16,
                  vertical: widget.compact ? 12 : (widget.isMobile ? 12 : 13),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
