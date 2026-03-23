import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/recipe_model.dart';

class AdminAnalyticsPage extends StatelessWidget {
  const AdminAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: FirestoreService().getAllUsers(),
      builder: (context, userSnapshot) {
        return StreamBuilder<List<RecipeModel>>(
          stream: FirestoreService().getAllRecipes(),
          builder: (context, recipeSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting ||
                recipeSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (userSnapshot.hasError || recipeSnapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${userSnapshot.error ?? recipeSnapshot.error}'),
                  ],
                ),
              );
            }

            final users = userSnapshot.data ?? [];
            final recipes = recipeSnapshot.data ?? [];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildMetricsRow(users, recipes),
                    const SizedBox(height: 24),
                    _buildChartsRow(recipes),
                    const SizedBox(height: 24),
                    _buildPopularRecipes(recipes),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics & Reports',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Track performance and user behavior',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_today, size: 16),
              label: const Text('Last 30 Days'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Export Report'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsRow(List<UserModel> users, List<RecipeModel> recipes) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final newUsers = users.where((u) {
      return u.createdAt != null && u.createdAt!.isAfter(thirtyDaysAgo);
    }).length;

    final activeUsers = users.where((u) => u.subscriptionStatus == 'active').length;
    final totalUsers = users.length;
    final engagementRate = totalUsers > 0 
        ? ((activeUsers / totalUsers) * 100).toStringAsFixed(1)
        : '0.0';

    final paidUsers = users.where((u) => u.subscriptionTier != 'free').length;
    final conversionRate = totalUsers > 0
        ? ((paidUsers / totalUsers) * 100).toStringAsFixed(1)
        : '0.0';

    final avgRecipesPerUser = users.isEmpty
        ? 0
        : users.map((u) => u.totalRecipesGenerated).reduce((a, b) => a + b) ~/
            users.length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'User Growth',
            '+$newUsers',
            'New users this month',
            Icons.trending_up,
            Colors.green,
            'Last 30 days',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Engagement Rate',
            '$engagementRate%',
            'Active users',
            Icons.people,
            Colors.blue,
            '$activeUsers active',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Conversion Rate',
            '$conversionRate%',
            'Free to paid conversion',
            Icons.monetization_on,
            Colors.amber,
            '$paidUsers paid',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            'Avg. Recipes',
            avgRecipesPerUser.toString(),
            'Per user',
            Icons.restaurant_menu,
            AppTheme.primaryGreen,
            'Total: ${recipes.length}',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    String change,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsRow(List<RecipeModel> recipes) {
    final cuisineCounts = <String, int>{};
    for (var recipe in recipes) {
      cuisineCounts[recipe.cuisine] = (cuisineCounts[recipe.cuisine] ?? 0) + 1;
    }

    final topCuisines = cuisineCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalRecipes = recipes.length;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'User Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.darkBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Activity Chart - Coming Soon',
                          style: TextStyle(color: AppTheme.greyText),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(24),
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
                const Text(
                  'Top Cuisines',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                if (topCuisines.isEmpty)
                  const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: AppTheme.greyText),
                    ),
                  )
                else
                  ...topCuisines.take(5).map((entry) {
                    final percentage = totalRecipes > 0
                        ? entry.value / totalRecipes
                        : 0.0;
                    final color = _getCuisineColor(topCuisines.indexOf(entry));
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildCuisineItem(
                        entry.key,
                        entry.value,
                        percentage,
                        color,
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getCuisineColor(int index) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }

  Widget _buildCuisineItem(String name, int count, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                color: AppTheme.greyText,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularRecipes(List<RecipeModel> recipes) {
    final sortedRecipes = recipes
        .where((r) => r.createdAt != null)
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final topRecipes = sortedRecipes.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Most Recent Recipes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          if (topRecipes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 64,
                      color: AppTheme.greyText,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No recipes yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...topRecipes.asMap().entries.map((entry) {
              final recipe = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${entry.key + 1}',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        recipe.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepTime + recipe.cookTime}m',
                          style: const TextStyle(
                            color: AppTheme.greyText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        recipe.cuisine,
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
