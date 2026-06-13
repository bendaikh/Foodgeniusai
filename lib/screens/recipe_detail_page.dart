import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/web_image.dart';
import '../models/recipe_model.dart';
import '../utils/url_launcher_helper.dart' as url_helper;
import '../services/auth_service.dart';
import '../services/pending_recipe_store.dart';
import 'pricing_page.dart';
import 'user_auth_page.dart';

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

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late Map<int, bool> _checkedIngredients;
  late Map<int, bool> _checkedInstructions;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkedIngredients = {
      for (var i = 0; i < widget.recipe.ingredients.length; i++) i: false
    };
    _checkedInstructions = {
      for (var i = 0; i < widget.recipe.instructions.length; i++) i: false
    };
  }

  bool _isAuthenticated = false;
  bool _hasFullAccess = false;

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
        '${widget.recipe.title} - Delicious recipe created with FoodGeniusAI'
      );
      
      // Construct Pinterest share URL
      final pinterestUrl = 'https://www.pinterest.com/pin/create/button/'
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
        '${widget.recipe.title} - Delicious recipe created with FoodGeniusAI'
      );
      
      // Construct Facebook share URL
      final facebookUrl = 'https://www.facebook.com/sharer/sharer.php'
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
        _hasFullAccess =
            _isAuthenticated && _authService.hasPaidSubscription(profileSnapshot.data);

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _buildNutrition(),
                  if (widget.missingIngredients != null &&
                      widget.missingIngredients!.isNotEmpty)
                    _buildMissingIngredients(),
                  _buildIngredients(),
                  _buildInstructions(),
                  const SizedBox(height: 40),
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
          child: widget.recipe.imageUrl != null && widget.recipe.imageUrl!.isNotEmpty
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
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _shareOnFacebook(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                      Icon(
                        Icons.facebook,
                        color: Colors.white,
                        size: 18,
                      ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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

  Widget _buildNutrition() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description - always visible
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
          // Time info - always visible for everyone
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTimeInfo(Icons.access_time, 'Prep', '${widget.recipe.prepTime} min'),
              _buildTimeInfo(Icons.restaurant, 'Cook', '${widget.recipe.cookTime} min'),
              _buildTimeInfo(Icons.calendar_today, 'Total', '${widget.recipe.totalTime} min'),
            ],
          ),
          const SizedBox(height: 24),
          // Nutrition cards - blurred for guests
          Stack(
            children: [
              Row(
                children: [
                  _buildNutritionCard('Calories', '${widget.recipe.nutrition['calories'] ?? 450}', 'kcal'),
                  const SizedBox(width: 12),
                  _buildNutritionCard('Protein', '${widget.recipe.nutrition['protein'] ?? 40}g', 'grams'),
                  const SizedBox(width: 12),
                  _buildNutritionCard('Carbs', '${widget.recipe.nutrition['carbs'] ?? 70}g', 'grams'),
                  const SizedBox(width: 12),
                  _buildNutritionCard('Fats', '${widget.recipe.nutrition['fat'] ?? 25}g', 'grams'),
                ],
              ),
              if (!_hasFullAccess)
                _buildPaywallOverlay(
                  borderRadius: 16,
                  child: _buildPaywallPrompt('nutrition details', compact: false),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Macro indicators - blurred for guests
          Stack(
            children: [
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
              if (!_hasFullAccess)
                _buildPaywallOverlay(borderRadius: 16),
            ],
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
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyText,
              ),
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.greyText,
          ),
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
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.greyText,
          ),
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
              const Icon(
                Icons.shopping_basket,
                color: Colors.orange,
                size: 24,
              ),
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
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
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
              children: List.generate(
                widget.missingIngredients!.length,
                (index) {
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
                            border: Border.all(
                              color: Colors.orange,
                              width: 2,
                            ),
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
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIngredients() {
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
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: List.generate(
                    widget.recipe.ingredients.length,
                    (index) {
                      final ingredient = widget.recipe.ingredients[index];
                      final isChecked = _checkedIngredients[index] ?? false;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _hasFullAccess ? () {
                                setState(() {
                                  _checkedIngredients[index] = !isChecked;
                                });
                              } : null,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? AppTheme.primaryGreen
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: AppTheme.primaryGreen,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: isChecked
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                '${ingredient['amount']} ${ingredient['unit']} ${ingredient['name']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isChecked
                                      ? AppTheme.greyText
                                      : Colors.white,
                                  decoration: isChecked
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (!_hasFullAccess)
                _buildPaywallOverlay(
                  borderRadius: 16,
                  child: _buildPaywallPrompt('ingredients', compact: true),
                ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
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
          Stack(
            children: [
              Column(
                children: widget.recipe.instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value;
            final isChecked = _checkedInstructions[index] ?? false;
            final stepNumber = instruction['step'] ?? (index + 1);
            final stepText = instruction['text'] ?? '';
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: _hasFullAccess ? () {
                  setState(() {
                    _checkedInstructions[index] = !isChecked;
                  });
                } : null,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isChecked 
                        ? AppTheme.cardBackground.withOpacity(0.5)
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isChecked 
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
                          color: isChecked
                              ? AppTheme.primaryGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: AppTheme.primaryGreen,
                            width: 2,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isChecked
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
                        child: Text(
                          stepText,
                          style: TextStyle(
                            fontSize: 16,
                            color: isChecked
                                ? AppTheme.greyText
                                : Colors.white,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
              ),
              if (!_hasFullAccess)
                _buildPaywallOverlay(
                  borderRadius: 16,
                  minHeight: 280,
                  child: _buildPaywallPrompt('instructions', compact: true),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallOverlay({
    required double borderRadius,
    Widget? child,
    double? minHeight,
  }) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.transparent),
            ),
            Container(
              constraints: minHeight != null
                  ? BoxConstraints(minHeight: minHeight)
                  : null,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.darkBackground.withOpacity(0.25),
                    AppTheme.darkBackground.withOpacity(0.55),
                    AppTheme.darkBackground.withOpacity(0.88),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
              child: child != null
                  ? Center(child: child)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallPrompt(String contentType, {required bool compact}) {
    if (_isAuthenticated) {
      return compact
          ? _buildSubscribePromptCompact(contentType)
          : _buildSubscribePrompt(contentType);
    }
    return compact
        ? _buildLoginPromptCompact(contentType)
        : _buildLoginPrompt(contentType);
  }

  Future<void> _openPricingPage() async {
    await PendingRecipeStore.instance.save(widget.recipe);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PricingPage(returnRecipe: widget.recipe),
      ),
    );
  }

  Widget _buildSubscribePrompt(String contentType) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.workspace_premium,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Subscribe to view $contentType',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _openPricingPage,
              icon: const Icon(Icons.lock_open, size: 18),
              label: const Text(
                'Subscribe to Unlock',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscribePromptCompact(String contentType) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.4),
              ),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppTheme.primaryGreen,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Subscribe to view full recipe',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock $contentType and every premium feature',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.greyText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openPricingPage,
            icon: const Icon(Icons.lock_open, size: 18),
            label: const Text(
              'Subscribe to Unlock',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(String contentType) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              color: AppTheme.primaryGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Sign in to view $contentType',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserAuthPage(isLogin: true),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserAuthPage(isLogin: false),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPromptCompact(String contentType) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.lock_outline,
            color: AppTheme.primaryGreen,
            size: 40,
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to view $contentType',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign in to continue — subscribe to unlock the full recipe',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.greyText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserAuthPage(isLogin: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserAuthPage(isLogin: false),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
