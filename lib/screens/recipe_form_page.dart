import 'dart:async';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../exceptions/free_recipe_limit_exception.dart';
import '../exceptions/generation_limit_exception.dart';
import '../services/ai_settings_service.dart';
import '../services/openai_service.dart';
import '../services/auth_service.dart';
import '../services/recipe_generation_service.dart';
import '../services/pending_generation_request_store.dart';
import '../services/audio_settings_service.dart';
import '../services/recipe_access_service.dart';
import '../models/recipe_model.dart';
import '../utils/app_message_dialog.dart';
import '../widgets/cooking_animation.dart';
import '../widgets/premium_audio_button.dart';
import 'pricing_page.dart';
import 'recipe_detail_page.dart';
import '../services/voice_guide_service.dart';
import '../widgets/voice_guide_route_aware.dart';

class RecipeFormPage extends StatefulWidget {
  const RecipeFormPage({super.key});

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage>
    with SingleTickerProviderStateMixin, VoiceGuideRouteAware {
  final AISettingsService _settingsService = AISettingsService();
  final AuthService _authService = AuthService();
  final RecipeGenerationService _recipeGenerationService =
      RecipeGenerationService();

  final TextEditingController _cravingController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController(
    text: '2',
  );
  String? _selectedMealType;
  String? _selectedDietary;
  String? _selectedPortion;

  bool _isGenerating = false;
  bool _isOpeningPaywall = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;

  static const _inspirationChips = <MapEntry<String, String>>[
    MapEntry('🍝', 'Italian'),
    MapEntry('🍗', 'Chicken'),
    MapEntry('🥗', 'Healthy'),
    MapEntry('🍰', 'Dessert'),
    MapEntry('🌮', 'Mexican'),
    MapEntry('🍜', 'Asian'),
    MapEntry('🥩', 'BBQ'),
    MapEntry('🥣', 'Soup'),
  ];

  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.createRecipe;

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
    _cravingController.dispose();
    _servingsController.dispose();
    super.dispose();
  }

  Future<void> _resumePendingGenerationIfReady() async {
    final pending = await PendingGenerationRequestStore.instance.load();
    if (pending == null || pending.source != 'craving') return;
    if (!await _recipeGenerationService.hasPaidSubscription()) return;

    _cravingController.text = pending.craving;
    _selectedMealType = pending.mealType;
    _selectedDietary = pending.dietary;
    _selectedPortion = pending.portionSize;
    _servingsController.text = (pending.servings ?? 2).toString();

    await PendingGenerationRequestStore.instance.clear();
    if (!mounted) return;
    await _executeGeneration();
  }

  PendingGenerationRequest _currentRequest() {
    return PendingGenerationRequest(
      source: 'craving',
      craving: _cravingController.text.trim(),
      mealType: _selectedMealType,
      dietary: _selectedDietary,
      servings: int.tryParse(_servingsController.text) ?? 2,
      portionSize: _selectedPortion,
    );
  }

  Future<void> _generateRecipe() async {
    if (_cravingController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tell us what you\'re craving!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isGenerating || _isOpeningPaywall) return;

    // Check free/paid access BEFORE any loading UI or AI API call.
    try {
      await _recipeGenerationService.ensureCanGenerate(source: 'craving');
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
      await PendingGenerationRequestStore.instance.save(_currentRequest());

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
      // Cancelled / closed paywall: keep form data, do not generate.
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
            message: 'Creating your perfect recipe...',
          ),
        );
      },
    );

    await AudioSettingsService.instance.startCookingGenerationSound();

    try {
      // Re-check immediately before spending API credits.
      await _recipeGenerationService.ensureCanGenerate(source: 'craving');

      final settings = await _settingsService.getSettings();

      if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
        throw Exception(
          'OpenAI API key not configured. Please ask admin to configure it in Admin Settings.',
        );
      }

      final user = _authService.currentUser;
      final isRegistered = user != null && !user.isAnonymous;

      final openaiService = OpenAIService(settings);

      // Map original form fields onto the current OpenAIService signature
      // (required for compile only — UI remains the historical HEAD design).
      final selectedMeal = _selectedMealType;
      final mealTypeForApi =
          (selectedMeal != null && selectedMeal.trim().isNotEmpty)
              ? selectedMeal.trim()
              : 'Surprise Me';
      final dietaryForApi = (_selectedDietary != null &&
              _selectedDietary!.trim().isNotEmpty)
          ? <String>[_selectedDietary!.trim()]
          : <String>['None'];
      final cravingForApi = _selectedPortion == null
          ? _cravingController.text.trim()
          : '${_cravingController.text.trim()} (portion: $_selectedPortion)';

      final recipe = await openaiService.generateRecipe(
        craving: cravingForApi,
        mealType: mealTypeForApi,
        mainGoal: 'Just Enjoy',
        dietaryPreferences: dietaryForApi,
        allergies: const ['No Allergies'],
        servings: int.tryParse(_servingsController.text) ?? 2,
      );

      String? imageUrl;
      try {
        imageUrl = await openaiService.generateRecipeImage(
          recipe.title,
          'Professional food photography, high quality, well-lit, appetizing ${recipe.cuisine} cuisine dish, restaurant presentation, realistic, natural lighting, detailed texture',
          userId: user == null || user.isAnonymous ? 'guest' : user.uid,
        );
        print('✅ Image generated: $imageUrl');
      } catch (e) {
        print('⚠️ Image generation failed: $e');
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

      if (mounted) {
        Navigator.of(context).pop();

        try {
          final savedRecipe = await _recipeGenerationService
              .persistGeneratedRecipe(recipeWithUser, source: 'craving');
          await PendingGenerationRequestStore.instance.clear();

          if (!mounted) return;

          if (isRegistered) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        imageUrl != null
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

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RecipeDetailPage(recipe: savedRecipe),
            ),
          );
        } catch (e) {
          if (!mounted) return;
          // Free quota is only consumed after a successful save; do not mark used here.
          await _showGenerationError(e);
        }
      }
    } on FreeRecipeLimitException {
      if (mounted) {
        Navigator.of(context).pop();
        setState(() => _isGenerating = false);
        await _openPaywallThenMaybeGenerate();
      }
    } catch (e) {
      await RecipeAccessService.instance.recordSuccessfulGeneration(
        source: 'craving',
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;

    double horizontalPadding;
    double verticalPadding;

    if (isMobile) {
      horizontalPadding = 16.0;
      verticalPadding = 12.0;
    } else if (isTablet) {
      horizontalPadding = 48.0;
      verticalPadding = 28.0;
    } else {
      horizontalPadding = screenWidth * 0.08;
      verticalPadding = 40.0;
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF061018), Color(0xFF0A1826), Color(0xFF081421)],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
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
                            'AI Recipe Generator',
                            style: TextStyle(
                              fontSize: isMobile ? 26 : 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isMobile ? 8 : 10),
                          Text(
                            'Create personalized recipes in seconds using AI.',
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
                    SizedBox(height: isMobile ? 24 : 32),
                    _buildForm(isMobile),
                    const SizedBox(height: 24),
                    _buildCreateButton(isMobile),
                    const SizedBox(height: 20),
                    _buildFooter(isMobile),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: AppTheme.greyText.withValues(alpha: 0.85),
        fontSize: 14,
      ),
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: AppTheme.darkBackground.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECIPE NAME',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _cravingController,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _fieldDecoration(
              hint: 'What would you like to cook today?',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: Creamy Chicken Pasta · Healthy Breakfast · High Protein Dinner',
            style: TextStyle(
              fontSize: 11.5,
              color: AppTheme.greyText.withValues(alpha: 0.9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Need inspiration?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _inspirationChips.map((chip) {
                  return _InspirationChip(
                    emoji: chip.key,
                    label: chip.value,
                    onTap: () {
                      setState(() {
                        _cravingController.text = chip.value;
                        _cravingController
                            .selection = TextSelection.fromPosition(
                          TextPosition(offset: _cravingController.text.length),
                        );
                      });
                    },
                  );
                }).toList(),
          ),
          SizedBox(height: isMobile ? 18 : 22),
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealTypeField(),
                const SizedBox(height: 16),
                _buildDietaryField(),
                const SizedBox(height: 16),
                _buildServingsField(),
                const SizedBox(height: 16),
                _buildPortionField(),
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMealTypeField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDietaryField()),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _buildServingsField()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildPortionField()),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.primaryGreen,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildMealTypeField() {
    final mealLabels = <String, String>{
      'Breakfast': '🍳 Breakfast',
      'Lunch': '🍝 Lunch',
      'Dinner': '🍽 Dinner',
      'Snack': '🍿 Snack',
      'Dessert': '🍰 Dessert',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('MEAL TYPE'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedMealType,
          isExpanded: true,
          decoration: _fieldDecoration(
            hint: 'Choose Meal Type...',
            prefixIcon: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          dropdownColor: AppTheme.cardBackground,
          items:
              mealLabels.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedMealType = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDietaryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('DIETARY'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDietary,
          isExpanded: true,
          decoration: _fieldDecoration(
            hint: 'Choose Dietary...',
            prefixIcon: const Icon(
              Icons.eco_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          dropdownColor: AppTheme.cardBackground,
          items:
              const [
                    'None',
                    'Vegetarian',
                    'Vegan',
                    'Gluten-Free',
                    'Keto',
                    'Paleo',
                  ]
                  .map(
                    (dietary) => DropdownMenuItem(
                      value: dietary,
                      child: Text(dietary, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedDietary = value;
            });
          },
        ),
      ],
    );
  }

  void _adjustServings(int delta) {
    final current = int.tryParse(_servingsController.text) ?? 2;
    final next = (current + delta).clamp(1, 20);
    setState(() {
      _servingsController.text = next.toString();
    });
  }

  Widget _buildServingsField() {
    final servings = int.tryParse(_servingsController.text) ?? 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('SERVINGS'),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.darkBackground.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                onPressed: () => _adjustServings(-1),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  transitionBuilder:
                      (child, animation) => ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                  child: Text(
                    '$servings',
                    key: ValueKey(servings),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                onPressed: () => _adjustServings(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PORTION QUANTITY'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPortion,
          isExpanded: true,
          decoration: _fieldDecoration(
            hint: 'Choose Portion...',
            prefixIcon: const Icon(
              Icons.straighten_rounded,
              color: AppTheme.primaryGreen,
              size: 20,
            ),
          ),
          dropdownColor: AppTheme.cardBackground,
          items:
              const ['Small', 'Medium', 'Large', 'Extra Large']
                  .map(
                    (portion) => DropdownMenuItem(
                      value: portion,
                      child: Text(portion, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              _selectedPortion = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCreateButton(bool isMobile) {
    return _GenerateAiButton(
      isGenerating: _isGenerating,
      isMobile: isMobile,
      onPressed: _isGenerating ? null : _generateRecipe,
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Center(
      child: Column(
        children: [
          Text(
            '⚡ Ready in about 20 seconds',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppTheme.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No credit card required',
            style: TextStyle(
              fontSize: isMobile ? 12.5 : 13,
              color: AppTheme.greyText.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: const [
              _TrustBadge(
                icon: Icons.auto_awesome_rounded,
                label: 'Personalized Recipes',
              ),
              _TrustBadge(
                icon: Icons.favorite_rounded,
                label: 'Healthy Meal Ideas',
              ),
              _TrustBadge(
                icon: Icons.checklist_rounded,
                label: 'Easy Step-by-Step',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Loved by thousands of home cooks',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppTheme.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '4.8/5 average satisfaction',
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: AppTheme.greyText.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspirationChip extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _InspirationChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '$emoji $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StepperButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 22),
        ),
      ),
    );
  }
}

class _GenerateAiButton extends StatefulWidget {
  final bool isGenerating;
  final bool isMobile;
  final VoidCallback? onPressed;

  const _GenerateAiButton({
    required this.isGenerating,
    required this.isMobile,
    required this.onPressed,
  });

  @override
  State<_GenerateAiButton> createState() => _GenerateAiButtonState();
}

class _GenerateAiButtonState extends State<_GenerateAiButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final scale = _pressed && enabled ? 0.97 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow:
              enabled
                  ? [
                    BoxShadow(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color:
              enabled
                  ? AppTheme.primaryGreen
                  : AppTheme.primaryGreen.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onPressed,
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(14),
            splashColor: Colors.white.withValues(alpha: 0.16),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: widget.isMobile ? 14 : 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.isGenerating) ...[
                      SizedBox(
                        width: widget.isMobile ? 18 : 20,
                        height: widget.isMobile ? 18 : 20,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.darkBackground,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Generating Your Recipe...',
                        style: TextStyle(
                          fontSize: widget.isMobile ? 14.5 : 16.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBackground,
                        ),
                      ),
                    ] else ...[
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Generate with AI',
                        style: TextStyle(
                          fontSize: widget.isMobile ? 15.5 : 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.darkBackground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
