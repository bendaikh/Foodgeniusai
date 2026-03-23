import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/recipe_model.dart';

class AdminRecipesPage extends StatelessWidget {
  const AdminRecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecipeModel>>(
      stream: FirestoreService().getAllRecipes(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final recipes = snapshot.data ?? [];

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                _buildStatsRow(recipes),
                const SizedBox(height: 24),
                recipes.isEmpty
                    ? _buildEmptyState()
                    : _buildRecipesGrid(recipes),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipe Management',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'View and manage AI-generated recipes',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(List<RecipeModel> recipes) {
    final totalRecipes = recipes.length;
    final todayRecipes = recipes.where((r) {
      final now = DateTime.now();
      return r.createdAt?.year == now.year &&
          r.createdAt?.month == now.month &&
          r.createdAt?.day == now.day;
    }).length;

    final avgPrepTime = recipes.isEmpty
        ? 0
        : recipes.map((r) => r.prepTime + r.cookTime).reduce((a, b) => a + b) ~/
            recipes.length;

    final cuisineCounts = <String, int>{};
    for (var recipe in recipes) {
      cuisineCounts[recipe.cuisine] = (cuisineCounts[recipe.cuisine] ?? 0) + 1;
    }
    final popularCuisine = cuisineCounts.isEmpty
        ? 'N/A'
        : cuisineCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Recipes',
            totalRecipes.toString(),
            Icons.restaurant_menu,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Today',
            todayRecipes.toString(),
            Icons.today,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Avg. Cook Time',
            '${avgPrepTime}m',
            Icons.timer,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Popular Cuisine',
            popularCuisine,
            Icons.favorite,
            Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesGrid(List<RecipeModel> recipes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return _buildRecipeCard(recipes[index]);
      },
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe) {
    final formattedDate = recipe.createdAt != null
        ? '${recipe.createdAt!.day}/${recipe.createdAt!.month}/${recipe.createdAt!.year}'
        : 'N/A';
    final totalTime = recipe.prepTime + recipe.cookTime;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.3),
                  AppTheme.darkBackground,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      recipe.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 48,
                            color: AppTheme.primaryGreen,
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 48,
                      color: AppTheme.primaryGreen,
                    ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    recipe.userId,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.greyText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppTheme.greyText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalTime min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.greyText,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty)
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getDifficultyColor(recipe.difficulty),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.visibility, size: 18),
                  color: AppTheme.greyText,
                  tooltip: 'View',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.edit, size: 18),
                  color: AppTheme.primaryGreen,
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.delete, size: 18),
                  color: Colors.red,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppTheme.greyText,
            ),
            SizedBox(height: 24),
            Text(
              'No Recipes Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Recipes will appear here once users start creating them',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Intermediate':
        return Colors.amber;
      case 'Advanced':
        return Colors.red;
      default:
        return AppTheme.greyText;
    }
  }
}
