import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/web_image.dart';
import '../models/recipe_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/pending_image_completion_service.dart';
import '../services/pending_recipe_service.dart';
import '../services/recipe_deletion_service.dart';
import '../services/recipe_generation_service.dart';
import '../utils/app_message_dialog.dart';
import '../utils/recipe_navigation.dart';
import 'pricing_page.dart';
import '../services/voice_guide_service.dart';
import '../widgets/voice_guide_route_aware.dart';
import '../widgets/premium_audio_button.dart';
import '../services/measurement_service.dart';

class RecipeDetailPage extends StatefulWidget {
  final RecipeModel recipe;
  final List<String>? missingIngredients;

  const RecipeDetailPage({
    super.key,
    required this.recipe,
    this.missingIngredients,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage>
    with VoiceGuideRouteAware {
  late Map<int, bool> _checkedIngredients;
  late Map<int, bool> _checkedInstructions;
  final AuthService _authService = AuthService();
  final RecipeGenerationService _recipeGenerationService =
      RecipeGenerationService();
  final FirestoreService _firestoreService = FirestoreService();

  late RecipeModel _recipe;
  bool _isTogglingSave = false;
  bool _isRetryingImage = false;
  bool _isDeleting = false;
  StreamSubscription<RecipeModel?>? _recipeSub;

  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.generatedRecipe;

  @override
  void initState() {
    super.initState();
    _recipe = widget.recipe;
    _checkedIngredients = {
      for (var i = 0; i < _recipe.ingredients.length; i++) i: false,
    };
    _checkedInstructions = {
      for (var i = 0; i < _recipe.instructions.length; i++) i: false,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final ensured =
            await _recipeGenerationService.ensureInMyRecipes(_recipe);
        if (mounted && ensured.id != null) {
          setState(() => _recipe = ensured);
          _watchRecipe(ensured.id!);
        }
      } catch (error, stackTrace) {
        debugPrint('Recipe auto-save failed: $error\n$stackTrace');
      }
      await _resumeImageIfNeeded();
    });
  }

  void _watchRecipe(String recipeId) {
    _recipeSub?.cancel();
    _recipeSub = _firestoreService.watchRecipe(recipeId).listen((updated) {
      if (!mounted) return;
      if (updated == null) {
        // Recipe was deleted (this device or another). Leave detail safely.
        RecipeNavigation.goBackFromRecipeDetail(context);
        return;
      }
      setState(() => _recipe = updated);
    });
  }

  Future<void> _resumeImageIfNeeded() async {
    final hasImage =
        _recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty;
    if (hasImage) return;

    final pending = await PendingImageCompletionService.instance.loadPending();
    if (pending == null) return;
    if (!PendingImageCompletionService.instance
        .matchesRecipe(pending, _recipe)) {
      return;
    }

    if (!mounted) return;
    setState(() => _isRetryingImage = true);
    try {
      final url =
          await PendingImageCompletionService.instance.resumePendingIfNeeded();
      if (!mounted) return;
      if (url != null && url.isNotEmpty) {
        setState(() => _recipe = _recipe.copyWith(imageUrl: url));
      }
    } finally {
      if (mounted) setState(() => _isRetryingImage = false);
    }
  }

  Future<void> _toggleSave() async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to save recipes to your Saved tab.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final recipeId = _recipe.id;
    if (recipeId == null || recipeId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save this recipe to My Recipes first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isTogglingSave || _isDeleting) return;
    setState(() => _isTogglingSave = true);

    final next = !_recipe.isSaved;
    try {
      await _firestoreService.setRecipeSaved(recipeId, next);
      if (!mounted) return;
      setState(() => _recipe = _recipe.copyWith(isSaved: next));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next ? 'Saved to your Saved tab' : 'Removed from Saved'),
          backgroundColor: AppTheme.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update Saved: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingSave = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sign in to delete recipes.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_recipe.id == null || _recipe.id!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This recipe cannot be deleted yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_isDeleting) return;

    final confirmed = await AppMessageDialog.confirmDestructive(
      context: context,
      title: 'Delete this recipe?',
      message:
          'This recipe will be permanently removed from your account.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await RecipeDeletionService.instance.deleteOwnedRecipe(_recipe);
      if (!mounted) return;
      // Success only after persistence confirmed gone — then leave this screen.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe deleted'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
      RecipeNavigation.goBackFromRecipeDetail(context);
    } catch (e) {
      if (!mounted) return;
      await AppMessageDialog.showError(
        context: context,
        title: 'Could not delete',
        message: AppMessageDialog.cleanErrorMessage(e),
      );
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initVoiceGuide();
  }

  @override
  void dispose() {
    _recipeSub?.cancel();
    disposeVoiceGuide();
    super.dispose();
  }

  bool _isAuthenticated = false;
  bool _hasFullAccess = false;
  bool _isUnlocking = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _authService.userProfileStream,
      builder: (context, profileSnapshot) {
        final user = _authService.currentUser;
        _isAuthenticated = user != null && !user.isAnonymous;
        final isCheckingAccess =
            _isAuthenticated &&
            profileSnapshot.connectionState == ConnectionState.waiting &&
            !profileSnapshot.hasData;
        _hasFullAccess =
            _isAuthenticated &&
            _authService.hasPaidSubscription(profileSnapshot.data);

        if (isCheckingAccess || _isUnlocking) {
          return PopScope(
            canPop: Navigator.of(context).canPop(),
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) {
                RecipeNavigation.goBackFromRecipeDetail(context);
              }
            },
            child: const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            ),
          );
        }

        return PopScope(
          canPop: Navigator.of(context).canPop(),
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              RecipeNavigation.goBackFromRecipeDetail(context);
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: _hasFullAccess ? 40 : 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        _buildRecipePreviewMeta(),
                        if (!_hasFullAccess)
                          _buildUnlockCard(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          ),
                        _buildNutrition(),
                        if (widget.missingIngredients != null &&
                            widget.missingIngredients!.isNotEmpty)
                          _buildMissingIngredients(),
                        _buildIngredients(),
                        _buildInstructions(),
                      ],
                    ),
                  ),
                  if (!_hasFullAccess)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _buildStickyUnlockBar(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryGreen.withOpacity(0.3),
                AppTheme.cardBackground,
              ],
            ),
          ),
          child:
              _recipe.imageUrl != null && _recipe.imageUrl!.isNotEmpty
                  ? kIsWeb
                      ? WebImage(
                        imageUrl: _recipe.imageUrl!,
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 120,
                              color: AppTheme.primaryGreen,
                            ),
                          );
                        },
                      )
                      : Image.network(
                        _recipe.imageUrl!,
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.restaurant,
                              size: 120,
                              color: AppTheme.primaryGreen,
                            ),
                          );
                        },
                      )
                  : Center(
                    child: _isRetryingImage
                        ? const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              SizedBox(height: 14),
                              Text(
                                'Finishing recipe image…',
                                style: TextStyle(
                                  color: AppTheme.greyText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : const Icon(
                            Icons.restaurant,
                            size: 120,
                            color: AppTheme.primaryGreen,
                          ),
                  ),
        ),
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.darkBackground.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => RecipeNavigation.goBackFromRecipeDetail(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: IconButton(
                  tooltip: 'Delete recipe',
                  onPressed: (_isDeleting || _isTogglingSave)
                      ? null
                      : _confirmAndDelete,
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.redAccent,
                          ),
                        )
                      : const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.darkBackground.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _recipe.isSaved
                        ? AppTheme.primaryGreen
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: IconButton(
                  tooltip: _recipe.isSaved ? 'Unsave recipe' : 'Save recipe',
                  onPressed: (_isTogglingSave || _isDeleting)
                      ? null
                      : _toggleSave,
                  icon: Icon(
                    _recipe.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: _recipe.isSaved
                        ? AppTheme.primaryGreen
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const PremiumAudioButton(size: 40, iconSize: 20),
            ],
          ),
        ),
        Positioned(
          bottom: 24,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _recipe.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecipePreviewMeta() {
    final calories = '${_recipe.nutrition['calories'] ?? 450}';
    final difficulty =
        _recipe.difficulty.isNotEmpty
            ? _recipe.difficulty[0].toUpperCase() +
                _recipe.difficulty.substring(1)
            : 'Intermediate';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_recipe.description.isNotEmpty) ...[
            Text(
              _recipe.description,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeInfo(
                Icons.access_time,
                'Prep',
                '${_recipe.prepTime} min',
              ),
              _buildTimeInfo(
                Icons.restaurant,
                'Cook',
                '${_recipe.cookTime} min',
              ),
              _buildTimeInfo(
                Icons.calendar_today,
                'Total',
                '${_recipe.totalTime} min',
              ),
            ],
          ),
          if (!_hasFullAccess) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildPreviewStatChip(
                    Icons.local_fire_department_outlined,
                    'Calories',
                    '$calories kcal',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPreviewStatChip(
                    Icons.speed_outlined,
                    'Difficulty',
                    difficulty,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutrition() {
    final calories = '${_recipe.nutrition['calories'] ?? 450}';

    if (_hasFullAccess) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildNutritionCard('Calories', calories, 'kcal'),
                const SizedBox(width: 12),
                _buildNutritionCard(
                  'Protein',
                  '${_recipe.nutrition['protein'] ?? 40}g',
                  'grams',
                ),
                const SizedBox(width: 12),
                _buildNutritionCard(
                  'Carbs',
                  '${_recipe.nutrition['carbs'] ?? 70}g',
                  'grams',
                ),
                const SizedBox(width: 12),
                _buildNutritionCard(
                  'Fats',
                  '${_recipe.nutrition['fat'] ?? 25}g',
                  'grams',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMacroIndicator('Protein', 0.4, Colors.blue),
                  _buildMacroIndicator('Carbs', 0.35, Colors.orange),
                  _buildMacroIndicator('Fats', 0.25, Colors.pink),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrition',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 12),
          // First nutrition summary visible
          Row(
            children: [
              _buildNutritionCard('Calories', calories, 'kcal'),
              const SizedBox(width: 12),
              const Spacer(),
              const Spacer(),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      _buildNutritionCard(
                        'Protein',
                        '${_recipe.nutrition['protein'] ?? 40}g',
                        'grams',
                      ),
                      const SizedBox(width: 12),
                      _buildNutritionCard(
                        'Carbs',
                        '${_recipe.nutrition['carbs'] ?? 70}g',
                        'grams',
                      ),
                      const SizedBox(width: 12),
                      _buildNutritionCard(
                        'Fats',
                        '${_recipe.nutrition['fat'] ?? 25}g',
                        'grams',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMacroIndicator('Protein', 0.4, Colors.blue),
                        _buildMacroIndicator('Carbs', 0.35, Colors.orange),
                        _buildMacroIndicator('Fats', 0.25, Colors.pink),
                      ],
                    ),
                  ),
                ],
              ),
              _buildSoftLockOverlay(borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewStatChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(String label, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroIndicator(String label, double value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: color.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
              Center(
                child: Text(
                  '${(value * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
        ),
      ],
    );
  }

  Widget _buildTimeInfo(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryGreen, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.greyText),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMissingIngredients() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_basket, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Missing Ingredients',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll need to get these ${widget.missingIngredients!.length} ingredient${widget.missingIngredients!.length > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 14, color: AppTheme.greyText),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: List.generate(widget.missingIngredients!.length, (
                index,
              ) {
                final ingredient = widget.missingIngredients![index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          color: Colors.orange,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          ingredient,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
    final ingredients = _recipe.ingredients;
    final previewCount =
        _hasFullAccess ? ingredients.length : ingredients.length.clamp(0, 3);
    final lockedIngredients =
        _hasFullAccess
            ? const <Map<String, dynamic>>[]
            : ingredients.skip(previewCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ingredients',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          if (previewCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: List.generate(previewCount, (index) {
                  return _buildIngredientRow(index, ingredients[index]);
                }),
              ),
            ),
          if (lockedIngredients.isNotEmpty) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: List.generate(lockedIngredients.length, (i) {
                      final index = previewCount + i;
                      return _buildIngredientRow(index, lockedIngredients[i]);
                    }),
                  ),
                ),
                _buildSoftLockOverlay(borderRadius: 16),
              ],
            ),
          ] else if (!_hasFullAccess && ingredients.isEmpty) ...[
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                _buildSoftLockOverlay(borderRadius: 16),
              ],
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIngredientRow(int index, Map<String, dynamic> ingredient) {
    final isChecked = _checkedIngredients[index] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          GestureDetector(
            onTap:
                _hasFullAccess
                    ? () {
                      setState(() {
                        _checkedIngredients[index] = !isChecked;
                      });
                    }
                    : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isChecked ? AppTheme.primaryGreen : Colors.transparent,
                border: Border.all(color: AppTheme.primaryGreen, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child:
                  isChecked
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ListenableBuilder(
              listenable: MeasurementService.instance,
              builder: (context, _) {
                final label = MeasurementService.instance.formatIngredient(
                  amount: ingredient['amount'],
                  unit: ingredient['unit'],
                  name: ingredient['name'],
                );
                return Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isChecked ? AppTheme.greyText : Colors.white,
                    decoration:
                        isChecked
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    final instructions = _recipe.instructions;
    final previewCount =
        _hasFullAccess ? instructions.length : (instructions.isEmpty ? 0 : 1);
    final lockedInstructions =
        _hasFullAccess
            ? const <Map<String, dynamic>>[]
            : instructions.skip(1).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 16),
          if (previewCount > 0)
            Column(
              children: List.generate(previewCount, (index) {
                return _buildInstructionCard(index, instructions[index]);
              }),
            ),
          if (lockedInstructions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Stack(
              children: [
                Column(
                  children: List.generate(lockedInstructions.length, (i) {
                    final index = i + 1;
                    return _buildInstructionCard(index, lockedInstructions[i]);
                  }),
                ),
                _buildSoftLockOverlay(borderRadius: 16),
              ],
            ),
          ] else if (!_hasFullAccess && instructions.isEmpty) ...[
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                _buildSoftLockOverlay(borderRadius: 16),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructionCard(int index, Map<String, dynamic> instruction) {
    final isChecked = _checkedInstructions[index] ?? false;
    final stepNumber = instruction['step'] ?? (index + 1);
    final stepText = instruction['text'] ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap:
            _hasFullAccess
                ? () {
                  setState(() {
                    _checkedInstructions[index] = !isChecked;
                  });
                }
                : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isChecked
                    ? AppTheme.cardBackground.withOpacity(0.5)
                    : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isChecked
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryGreen.withOpacity(0.2),
              width: isChecked ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isChecked ? AppTheme.primaryGreen : Colors.transparent,
                  border: Border.all(color: AppTheme.primaryGreen, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child:
                      isChecked
                          ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                          : Text(
                            '$stepNumber',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListenableBuilder(
                  listenable: MeasurementService.instance,
                  builder: (context, _) {
                    final localized = MeasurementService.instance
                        .formatInstructionText('$stepText');
                    return Text(
                      localized,
                      style: TextStyle(
                        fontSize: 16,
                        color: isChecked ? AppTheme.greyText : Colors.white,
                        decoration:
                            isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        height: 1.5,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoftLockOverlay({required double borderRadius}) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2.2, sigmaY: 2.2),
              child: Container(color: Colors.transparent),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBackground.withOpacity(0.12),
                    AppTheme.darkBackground.withOpacity(0.38),
                    AppTheme.darkBackground.withOpacity(0.68),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBackground.withOpacity(0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.45),
                    ),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePendingRecipe() async {
    await PendingRecipeService.instance.save(_recipe);
  }

  Future<void> _handleUnlockFullRecipe() async {
    if (_isUnlocking || _hasFullAccess) return;

    setState(() => _isUnlocking = true);
    try {
      await _savePendingRecipe();
      if (!mounted) return;

      // Always open pricing first. If the user is not signed in, PricingPage
      // prompts for auth after they select a plan, then continues that same
      // Basic / Pro / Premium purchase without asking them to re-select.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PricingPage(returnRecipe: _recipe),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUnlocking = false);
      }
    }
  }

  Widget _buildStickyUnlockBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.darkBackground.withOpacity(0),
            AppTheme.darkBackground.withOpacity(0.92),
            AppTheme.darkBackground,
          ],
          stops: const [0.0, 0.35, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: _buildUnlockCard(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          compact: true,
        ),
      ),
    );
  }

  Widget _buildUnlockCard({
    EdgeInsets padding = const EdgeInsets.fromLTRB(24, 8, 24, 0),
    bool compact = false,
  }) {
    return Padding(
      padding: padding,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(compact ? 18 : 24),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lock_open_rounded,
                    color: AppTheme.primaryGreen,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Unlock Full Recipe',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (!compact) ...[
              const SizedBox(height: 12),
              const Text(
                'Get all ingredients, step-by-step instructions, nutrition facts, and more.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.greyText,
                  height: 1.45,
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Get all ingredients, instructions, nutrition facts, and more.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.greyText,
                  height: 1.35,
                ),
              ),
            ],
            SizedBox(height: compact ? 14 : 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleUnlockFullRecipe,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: AppTheme.darkBackground,
                  padding: EdgeInsets.symmetric(vertical: compact ? 14 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Unlock Full Recipe',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
