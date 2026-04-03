import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'admin_users_page.dart';
import 'admin_api_settings_page.dart';
import 'admin_payments_page.dart';
import 'admin_recipes_page.dart';
import 'admin_analytics_page.dart';
import 'admin_settings_page.dart';
import 'admin_seo_settings_page.dart';
import 'database_seeder_page.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/recipe_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardHomePage(),
    const AdminUsersPage(),
    const AdminRecipesPage(),
    const AdminPaymentsPage(),
    const AdminApiSettingsPage(),
    const AdminAnalyticsPage(),
    const AdminSeoSettingsPage(),
    const AdminSettingsPage(),
    const DatabaseSeederPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 280,
      color: AppTheme.cardBackground,
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(0, Icons.dashboard, 'Dashboard'),
                _buildMenuItem(1, Icons.people, 'Users'),
                _buildMenuItem(2, Icons.restaurant_menu, 'Recipes'),
                _buildMenuItem(3, Icons.payment, 'Payments'),
                _buildMenuItem(4, Icons.api, 'API Settings'),
                _buildMenuItem(5, Icons.analytics, 'Analytics'),
                _buildMenuItem(6, Icons.search, 'SEO Settings'),
                const Divider(color: AppTheme.greyText, height: 32),
                _buildMenuItem(8, Icons.cloud_upload, 'Database Seeder'),
                _buildMenuItem(7, Icons.settings, 'Settings'),
                _buildMenuItem(-2, Icons.logout, 'Logout'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: AppTheme.primaryGreen,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FoodGeniusAI',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index && index >= 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () async {
          if (index >= 0) {
            setState(() {
              _selectedIndex = index;
            });
          } else if (index == -2) {
            // Logout
            final authService = AuthService();
            await authService.signOut();
            if (mounted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/landing',
                (route) => false,
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.greyText,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? AppTheme.primaryGreen : Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({super.key});

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
                    _buildStats(users, recipes),
                    const SizedBox(height: 32),
                    _buildCharts(users),
                    const SizedBox(height: 32),
                    _buildRecentActivity(users, recipes),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back! Here\'s what\'s happening today.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(List<UserModel> users, List<RecipeModel> recipes) {
    final totalUsers = users.length;
    final activeSubscriptions =
        users.where((u) => u.subscriptionStatus == 'active').length;
    final totalRecipes = recipes.length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Users',
            totalUsers.toString(),
            'All registered users',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Active Subscriptions',
            activeSubscriptions.toString(),
            'Active subscribers',
            Icons.star,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Recipes Generated',
            totalRecipes.toString(),
            'Total recipes created',
            Icons.restaurant_menu,
            AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Revenue (MRR)',
            '\$0',
            'Monthly recurring revenue',
            Icons.attach_money,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String change,
    IconData icon,
    Color color,
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyText,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
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
            change,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts(List<UserModel> users) {
    final freeTier = users.where((u) => u.subscriptionTier == 'free').length;
    final proTier = users.where((u) => u.subscriptionTier == 'pro').length;
    final eliteTier = users.where((u) => u.subscriptionTier == 'elite').length;

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
                  'Revenue Overview',
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
                          Icons.show_chart,
                          size: 48,
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Revenue Chart - Coming Soon',
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
                  'Subscription Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                _buildSubscriptionItem('Free', freeTier, Colors.grey),
                const SizedBox(height: 12),
                _buildSubscriptionItem('Gourmet Pro', proTier, Colors.blue),
                const SizedBox(height: 12),
                _buildSubscriptionItem('Michelin Elite', eliteTier, Colors.amber),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionItem(String plan, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            plan,
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(List<UserModel> users, List<RecipeModel> recipes) {
    final recentUsers = users
        .where((u) => u.createdAt != null)
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final recentRecipes = recipes
        .where((r) => r.createdAt != null)
        .toList()
      ..sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    final activities = <Widget>[];

    if (recentUsers.isNotEmpty) {
      final user = recentUsers.first;
      final timeAgo = _getTimeAgo(user.createdAt!);
      activities.add(_buildActivityItem(
        'New user registered',
        user.email,
        timeAgo,
        Icons.person_add,
      ));
    }

    if (recentRecipes.isNotEmpty) {
      final recipe = recentRecipes.first;
      final timeAgo = _getTimeAgo(recipe.createdAt!);
      activities.add(_buildActivityItem(
        'Recipe generated',
        recipe.title,
        timeAgo,
        Icons.restaurant_menu,
      ));
    }

    if (activities.isEmpty) {
      activities.add(_buildActivityItem(
        'No recent activity',
        'Activity will appear here as users interact with the app',
        'N/A',
        Icons.info_outline,
      ));
    }

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
            'Recent Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...activities,
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildActivityItem(
    String title,
    String subtitle,
    String time,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }
}
