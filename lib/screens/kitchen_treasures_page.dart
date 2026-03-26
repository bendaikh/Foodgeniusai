import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import '../services/ai_settings_service.dart';
import '../services/openai_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/recipe_model.dart';
import '../widgets/cooking_animation.dart';
import '../widgets/web_image.dart';
import 'recipe_detail_page.dart';

class KitchenTreasuresPage extends StatefulWidget {
  const KitchenTreasuresPage({super.key});

  @override
  State<KitchenTreasuresPage> createState() => _KitchenTreasuresPageState();
}

class _KitchenTreasuresPageState extends State<KitchenTreasuresPage> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  final AISettingsService _settingsService = AISettingsService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  bool _isGenerating = false;
  List<RecipeModel> _generatedRecipes = [];
  bool _showRecipes = false;

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
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

    try {
      final settings = await _settingsService.getSettings();
      
      if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
        throw Exception('OpenAI API key not configured. Please ask admin to configure it in Admin Settings.');
      }

      final openaiService = OpenAIService(settings);
      final user = _authService.currentUser;
      
      if (user == null) {
        throw Exception('Please log in to generate recipes');
      }

      final recipes = await openaiService.generateRecipesFromIngredients(
        ingredients: _ingredients,
        numberOfRecipes: 1,
      );

      // Generate images and save recipes
      List<RecipeModel> recipesWithImages = [];
      for (var recipe in recipes) {
        String? imageUrl;
        try {
          imageUrl = await openaiService.generateRecipeImage(
            recipe.title,
            'Professional food photography, high quality, well-lit, appetizing ${recipe.cuisine} cuisine dish, restaurant presentation, realistic, natural lighting, detailed texture',
            userId: user.uid,
          );
        } catch (e) {
          print('⚠️ Image generation failed: $e');
        }

        final recipeWithUser = RecipeModel(
          id: recipe.id,
          userId: user.uid,
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

        await _firestoreService.createRecipe(recipeWithUser);
        recipesWithImages.add(recipeWithUser);
      }

      if (mounted) {
        Navigator.of(context).pop();
        
        setState(() {
          _generatedRecipes = recipesWithImages;
          _showRecipes = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text('Recipes generated successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1200;
    final isDesktop = screenWidth >= 1200;
    
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
      body: SafeArea(
        child: SingleChildScrollView(
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 24 : 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Kitchen Treasures',
                        style: TextStyle(
                          fontSize: isMobile ? 28 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        'Turn your available ingredients into gourmet masterpieces',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: AppTheme.greyText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isMobile ? 40 : 60),
                if (!_showRecipes) ...[
                  _buildForm(isMobile),
                  const SizedBox(height: 40),
                  if (_ingredients.isNotEmpty) _buildRevealButton(isMobile),
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
                        icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGreen),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Add the ingredients you have on hand.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Salmon, Spinach...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addIngredient,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: 20,
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _ingredients
                  .map((ingredient) => Chip(
                        label: Text(ingredient),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                        onDeleted: () {
                          setState(() {
                            _ingredients.remove(ingredient);
                          });
                        },
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                        side: const BorderSide(
                          color: AppTheme.primaryGreen,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevealButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateRecipes,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
        ),
        child: _isGenerating
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: isMobile ? 18 : 20,
                    width: isMobile ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Finding Recipes...',
                    style: TextStyle(fontSize: isMobile ? 14 : 18),
                  ),
                ],
              )
            : Text(
                'Reveal Recipes',
                style: TextStyle(fontSize: isMobile ? 16 : 18),
              ),
      ),
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
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.greyText,
          ),
        ),
        const SizedBox(height: 32),
        ..._generatedRecipes.map((recipe) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: _buildRecipeCard(context, recipe: recipe, isMobile: isMobile),
          );
        }).toList(),
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
            builder: (context) => RecipeDetailPage(
              recipe: recipe,
              missingIngredients: missingIngredients.isNotEmpty ? missingIngredients : null,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
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
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_circle, color: Colors.amber, size: 12),
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
                          color: AppTheme.primaryGreen.withOpacity(0.1),
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
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
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
                            children: missingIngredients.take(5).map((ingredient) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
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
                                color: Colors.orange.withOpacity(0.7),
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
            AppTheme.primaryGreen.withOpacity(0.3),
            AppTheme.cardBackground,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 80,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  List<String> _getMissingIngredients(RecipeModel recipe) {
    final userIngredientsLower = _ingredients.map((i) => i.toLowerCase()).toList();
    final missing = <String>[];
    
    for (var ingredient in recipe.ingredients) {
      final ingredientName = ingredient['name']?.toString().toLowerCase() ?? '';
      
      bool hasIngredient = userIngredientsLower.any((userIng) {
        return ingredientName.contains(userIng) || userIng.contains(ingredientName);
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
        _ingredientController.clear();
      });
    }
  }
}
