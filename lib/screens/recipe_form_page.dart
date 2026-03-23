import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_settings_service.dart';
import '../services/openai_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/recipe_model.dart';
import '../widgets/cooking_animation.dart';
import 'my_creations_page.dart';

class RecipeFormPage extends StatefulWidget {
  const RecipeFormPage({super.key});

  @override
  State<RecipeFormPage> createState() => _RecipeFormPageState();
}

class _RecipeFormPageState extends State<RecipeFormPage> {
  final AISettingsService _settingsService = AISettingsService();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  
  final TextEditingController _cravingController = TextEditingController();
  final TextEditingController _servingsController =
      TextEditingController(text: '2');
  String? _selectedMealType;
  String? _selectedDietary;
  String? _selectedPortion;
  
  bool _isGenerating = false;

  @override
  void dispose() {
    _cravingController.dispose();
    _servingsController.dispose();
    super.dispose();
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

    setState(() {
      _isGenerating = true;
    });

    // Show cooking animation dialog
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

    try {
      // Load AI settings
      final settings = await _settingsService.getSettings();
      
      if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
        throw Exception('OpenAI API key not configured. Please ask admin to configure it in Admin Settings.');
      }

      // Create OpenAI service
      final openaiService = OpenAIService(settings);

      // Generate recipe
      final recipe = await openaiService.generateRecipe(
        craving: _cravingController.text.trim(),
        mealType: _selectedMealType,
        dietary: _selectedDietary,
        servings: int.tryParse(_servingsController.text) ?? 2,
        portionSize: _selectedPortion,
      );

      // Get current user first (before image generation)
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Please log in to save recipes');
      }

      // Generate realistic food image
      String? imageUrl;
      try {
        imageUrl = await openaiService.generateRecipeImage(
          recipe.title,
          'Professional food photography, high quality, well-lit, appetizing ${recipe.cuisine} cuisine dish, restaurant presentation, realistic, natural lighting, detailed texture',
          userId: user.uid, // Pass user ID to save image permanently
        );
        print('✅ Image generated: $imageUrl');
      } catch (e) {
        print('⚠️ Image generation failed: $e');
        // Continue without image if it fails
      }

      // Update recipe with user ID, image, and calculate totalTime
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
        imageUrl: imageUrl, // Add the generated image
        createdAt: recipe.createdAt,
      );

      // Save to Firestore
      await _firestoreService.createRecipe(recipeWithUser);

      if (mounted) {
        // Close the cooking animation dialog
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    imageUrl != null 
                      ? 'Recipe and image generated successfully!' 
                      : 'Recipe generated! (Image generation skipped)',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to My Creations
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyCreationsPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close the cooking animation dialog
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
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
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
                        'Create a recipe you\'ll love',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 8 : 12),
                      Text(
                        'Tell us what you feel like cooking today',
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
                _buildForm(),
                const SizedBox(height: 40),
                _buildCreateButton(),
                const SizedBox(height: 24),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
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
          const Text(
            'WHAT ARE YOU CRAVING?',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cravingController,
            decoration: const InputDecoration(
              hintText: 'e.g. Creamy Italian Pasta...',
            ),
          ),
          SizedBox(height: isMobile ? 24 : 32),
          if (isMobile)
            // Stack fields vertically on mobile
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMealTypeField(),
                const SizedBox(height: 24),
                _buildDietaryField(),
                const SizedBox(height: 24),
                _buildServingsField(),
                const SizedBox(height: 24),
                _buildPortionField(),
              ],
            )
          else
            // Side-by-side layout on desktop
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildMealTypeField()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildDietaryField()),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: _buildServingsField()),
                    const SizedBox(width: 24),
                    Expanded(child: _buildPortionField()),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMealTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEAL TYPE',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedMealType,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Choose Meal Type...',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          dropdownColor: AppTheme.cardBackground,
          items: [
            'Breakfast',
            'Lunch',
            'Dinner',
            'Snack',
            'Dessert'
          ]
              .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(
                      type,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
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
        const Text(
          'DIETARY',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedDietary,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Choose Dietary...',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          dropdownColor: AppTheme.cardBackground,
          items: [
            'None',
            'Vegetarian',
            'Vegan',
            'Gluten-Free',
            'Keto',
            'Paleo'
          ]
              .map((dietary) => DropdownMenuItem(
                    value: dietary,
                    child: Text(
                      dietary,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
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

  Widget _buildServingsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SERVINGS',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _servingsController,
          decoration: const InputDecoration(
            hintText: '2',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPortionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PORTION QUANTITY',
          style: TextStyle(
            color: AppTheme.primaryGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedPortion,
          isExpanded: true,
          decoration: const InputDecoration(
            hintText: 'Choose Portion...',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          dropdownColor: AppTheme.cardBackground,
          items: [
            'Small',
            'Medium',
            'Large',
            'Extra Large'
          ]
              .map((portion) => DropdownMenuItem(
                    value: portion,
                    child: Text(
                      portion,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
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

  Widget _buildCreateButton() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isGenerating ? null : _generateRecipe,
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
                    'Generating Your Recipe...',
                    style: TextStyle(fontSize: isMobile ? 14 : 18),
                  ),
                ],
              )
            : Text(
                'Create My Recipe',
                style: TextStyle(fontSize: isMobile ? 16 : 18),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Text(
            'Takes ~20 seconds • No card required',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyText,
            ),
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 32,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: AppTheme.primaryGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Healthy meal ideas',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: AppTheme.primaryGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Easy step-by-step instructions',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, color: AppTheme.primaryGreen, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Save your favorite recipes',
                    style: TextStyle(fontSize: 12, color: AppTheme.greyText),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Loved by home cooks • 4.8/5',
                style: TextStyle(fontSize: 14, color: AppTheme.greyText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
