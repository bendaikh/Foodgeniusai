import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/web_image.dart';
import '../models/recipe_model.dart';
import '../utils/url_launcher_helper.dart' as url_helper;
import '../services/auth_service.dart';
import '../services/pending_recipe_service.dart';
import '../services/recipe_generation_service.dart';
import '../utils/recipe_navigation.dart';
import 'pricing_page.dart';
import 'user_auth_page.dart';
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

  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.generatedRecipe;

  @override
  void initState() {
    super.initState();
    _checkedIngredients = {
      for (var i = 0; i < widget.recipe.ingredients.length; i++) i: false,
    };
    _checkedInstructions = {
      for (var i = 0; i < widget.recipe.instructions.length; i++) i: false,
    };
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _recipeGenerationService.ensureInMyRecipes(widget.recipe);
      } catch (error, stackTrace) {
        debugPrint('Recipe auto-save failed: $error\n$stackTrace');
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
    disposeVoiceGuide();
    super.dispose();
  }

  bool _isAuthenticated = false;
  bool _hasFullAccess = false;
  bool _isUnlocking = false;

  void _shareOnPinterest(BuildContext context) async {
    try {
      // Check if image URL exists
      if (widget.recipe.imageUrl == null || widget.recipe.imageUrl!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image available to share'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Pinterest share URL format
      final imageUrl = Uri.encodeComponent(widget.recipe.imageUrl!);
      final description = Uri.encodeComponent(
        '${widget.recipe.title} - Delicious recipe created with FoodGeniusAI',
      );

      // Construct Pinterest share URL
      final pinterestUrl =
          'https://www.pinterest.com/pin/create/button/'
          '?url=${Uri.encodeComponent('https://foodgeniusai.com')}'
          '&media=$imageUrl'
          '&description=$description';

      // Use platform-specific URL launcher
      await url_helper.openUrl(pinterestUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Pinterest...'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to Pinterest: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _shareOnFacebook(BuildContext context) async {
    try {
      // Check if image URL exists
      if (widget.recipe.imageUrl == null || widget.recipe.imageUrl!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image available to share'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Facebook share URL format
      final shareUrl = Uri.encodeComponent('https://foodgeniusai.com');
      final quote = Uri.encodeComponent(
        '${widget.recipe.title} - Delicious recipe created with FoodGeniusAI',
      );

      // Construct Facebook share URL
      final facebookUrl =
          'https://www.facebook.com/sharer/sharer.php'
          '?u=$shareUrl'
          '&quote=$quote';

      // Use platform-specific URL launcher
      await url_helper.openUrl(facebookUrl);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening Facebook...'),
            backgroundColor: AppTheme.primaryGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to Facebook: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
              widget.recipe.imageUrl != null &&
                      widget.recipe.imageUrl!.isNotEmpty
                  ? kIsWeb
                      ? WebImage(
                        imageUrl: widget.recipe.imageUrl!,
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
                        widget.recipe.imageUrl!,
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
                  : const Center(
                    child: Icon(
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
              const PremiumAudioButton(size: 40, iconSize: 20),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _shareOnFacebook(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2), // Facebook blue color
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.facebook, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _shareOnPinterest(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE60023), // Pinterest red color
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Pin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
                widget.recipe.title,
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
    final calories = '${widget.recipe.nutrition['calories'] ?? 450}';
    final difficulty =
        widget.recipe.difficulty.isNotEmpty
            ? widget.recipe.difficulty[0].toUpperCase() +
                widget.recipe.difficulty.substring(1)
            : 'Intermediate';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.recipe.description.isNotEmpty) ...[
            Text(
              widget.recipe.description,
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
                '${widget.recipe.prepTime} min',
              ),
              _buildTimeInfo(
                Icons.restaurant,
                'Cook',
                '${widget.recipe.cookTime} min',
              ),
              _buildTimeInfo(
                Icons.calendar_today,
                'Total',
                '${widget.recipe.totalTime} min',
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
    final calories = '${widget.recipe.nutrition['calories'] ?? 450}';

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
                  '${widget.recipe.nutrition['protein'] ?? 40}g',
                  'grams',
                ),
                const SizedBox(width: 12),
                _buildNutritionCard(
                  'Carbs',
                  '${widget.recipe.nutrition['carbs'] ?? 70}g',
                  'grams',
                ),
                const SizedBox(width: 12),
                _buildNutritionCard(
                  'Fats',
                  '${widget.recipe.nutrition['fat'] ?? 25}g',
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
                        '${widget.recipe.nutrition['protein'] ?? 40}g',
                        'grams',
                      ),
                      const SizedBox(width: 12),
                      _buildNutritionCard(
                        'Carbs',
                        '${widget.recipe.nutrition['carbs'] ?? 70}g',
                        'grams',
                      ),
                      const SizedBox(width: 12),
                      _buildNutritionCard(
                        'Fats',
                        '${widget.recipe.nutrition['fat'] ?? 25}g',
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
    final ingredients = widget.recipe.ingredients;
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
    final instructions = widget.recipe.instructions;
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
    await PendingRecipeService.instance.save(widget.recipe);
  }

  Future<void> _handleUnlockFullRecipe() async {
    if (_isUnlocking || _hasFullAccess) return;

    setState(() => _isUnlocking = true);
    try {
      await _savePendingRecipe();
      if (!mounted) return;

      if (_isAuthenticated) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PricingPage(returnRecipe: widget.recipe),
          ),
        );
      } else {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => UserAuthPage(
                  isLogin: false,
                  continueToPricingRecipe: widget.recipe,
                ),
          ),
        );
      }
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
