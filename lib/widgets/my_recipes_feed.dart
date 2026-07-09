import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import '../services/recipe_generation_service.dart';
import '../theme/app_theme.dart';
import '../widgets/web_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../screens/recipe_detail_page.dart';

/// Loads recipes from the server after syncing any pending checkout/signup recipe.
class MyRecipesFeed extends StatefulWidget {
  final String userId;
  final Widget Function(RecipeModel recipe)? recipeCardBuilder;

  const MyRecipesFeed({
    super.key,
    required this.userId,
    this.recipeCardBuilder,
  });

  @override
  State<MyRecipesFeed> createState() => MyRecipesFeedState();
}

class MyRecipesFeedState extends State<MyRecipesFeed> {
  final RecipeGenerationService _recipeGenerationService = RecipeGenerationService();
  Future<List<RecipeModel>>? _recipesFuture;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _recipesFuture = _recipeGenerationService.loadMyRecipes(widget.userId);
    });
    await _recipesFuture;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RecipeModel>>(
      future: _recipesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Could not load recipes: ${snapshot.error}',
                    style: const TextStyle(color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: reload,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final recipes = snapshot.data ?? [];

        if (recipes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: AppTheme.greyText.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Recipes Yet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate a recipe and it will appear here — even if you haven\'t finished payment yet.',
                    style: TextStyle(color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: reload,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              if (widget.recipeCardBuilder != null) {
                return widget.recipeCardBuilder!(recipe);
              }
              return _DefaultRecipeCard(recipe: recipe);
            },
          ),
        );
      },
    );
  }
}

class _DefaultRecipeCard extends StatelessWidget {
  final RecipeModel recipe;

  const _DefaultRecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? kIsWeb
                      ? WebImage(
                          imageUrl: recipe.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          recipe.imageUrl!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                  : Container(
                      width: 100,
                      height: 100,
                      color: AppTheme.primaryGreen.withOpacity(0.15),
                      child: const Icon(Icons.restaurant, color: AppTheme.primaryGreen),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${recipe.prepTime + recipe.cookTime} min • ${recipe.difficulty}',
                      style: const TextStyle(color: AppTheme.greyText, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
