import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/recipe_model.dart';
import '../widgets/web_image.dart';
import 'recipe_detail_page.dart';
import 'recipe_form_page.dart';
import 'landing_page.dart';

class UserAccountPage extends StatefulWidget {
  const UserAccountPage({super.key});

  @override
  State<UserAccountPage> createState() => _UserAccountPageState();
}

class _UserAccountPageState extends State<UserAccountPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  int _selectedTab = 0; // 0 = Profile, 1 = My Recipes

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to view your account'),
        ),
      );
    }

    if (isMobile) {
      // Mobile layout - no sidebar, use bottom navigation or tabs
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            _selectedTab == 0 ? 'Profile' : 'My Recipes',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            PopupMenuButton<int>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) async {
                if (value == -1) {
                  // Create Recipe
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RecipeFormPage()),
                  );
                } else if (value == -2) {
                  // Logout
                  await _authService.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LandingPage()),
                      (route) => false,
                    );
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: -1,
                  child: Row(
                    children: [
                      Icon(Icons.add_circle, color: AppTheme.primaryGreen),
                      SizedBox(width: 12),
                      Text('Create Recipe'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: -2,
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildMainContent(currentUser),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTab,
          onTap: (index) {
            setState(() {
              _selectedTab = index;
            });
          },
          backgroundColor: AppTheme.cardBackground,
          selectedItemColor: AppTheme.primaryGreen,
          unselectedItemColor: AppTheme.greyText,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'My Recipes',
            ),
          ],
        ),
      );
    }

    // Desktop layout - with sidebar
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: AppTheme.cardBackground,
                border: Border(
                  right: BorderSide(
                    color: AppTheme.primaryGreen.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildSidebarHeader(currentUser),
                  const SizedBox(height: 24),
                  _buildMenuItem(0, Icons.person, 'Profile'),
                  _buildMenuItem(1, Icons.restaurant_menu, 'My Recipes'),
                  const Spacer(),
                  _buildMenuItem(-1, Icons.add_circle, 'Create Recipe'),
                  _buildMenuItem(-2, Icons.logout, 'Logout'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: _buildMainContent(currentUser),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(User user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryGreen.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: AppTheme.primaryGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.email?.split('@')[0] ?? 'User',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            user.email ?? '',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index, IconData icon, String title) {
    final isSelected = _selectedTab == index && index >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () async {
          if (index >= 0) {
            setState(() {
              _selectedTab = index;
            });
          } else if (index == -1) {
            // Create Recipe
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RecipeFormPage()),
            );
          } else if (index == -2) {
            // Logout
            await _authService.signOut();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LandingPage()),
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
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent(User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    if (_selectedTab == 0) {
      return _buildProfileTab(user);
    } else {
      return _buildRecipesTab(user, isMobile);
    }
  }

  Widget _buildProfileTab(User user) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    return StreamBuilder<UserModel?>(
      stream: Stream.fromFuture(_firestoreService.getUserById(user.uid)),
      builder: (context, snapshot) {
        final userData = snapshot.data;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Profile',
                style: TextStyle(
                  fontSize: isMobile ? 24 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMobile ? 4 : 8),
              Text(
                'Manage your account settings',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: AppTheme.greyText,
                ),
              ),
              SizedBox(height: isMobile ? 24 : 40),
              _buildProfileCard(user, userData, isMobile),
              SizedBox(height: isMobile ? 16 : 24),
              _buildStatsCard(user, isMobile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(User user, UserModel? userData, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: isMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: isMobile ? 16 : 24),
          _buildInfoRow('Email', user.email ?? 'N/A', isMobile),
          Divider(color: AppTheme.greyText, height: isMobile ? 24 : 32),
          _buildInfoRow('Name', userData?.name ?? 'N/A', isMobile),
          Divider(color: AppTheme.greyText, height: isMobile ? 24 : 32),
          _buildInfoRow('Subscription', userData?.subscriptionTier ?? 'free', isMobile),
          Divider(color: AppTheme.greyText, height: isMobile ? 24 : 32),
          _buildInfoRow('Member Since', 
            userData?.createdAt != null 
              ? '${userData!.createdAt!.day}/${userData.createdAt!.month}/${userData.createdAt!.year}'
              : 'N/A',
            isMobile
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isMobile) {
    if (isMobile) {
      // Stack label and value vertically on mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.greyText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    
    // Side-by-side layout on desktop
    return Row(
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.greyText,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(User user, bool isMobile) {
    return StreamBuilder<List<RecipeModel>>(
      stream: _firestoreService.getRecipesByUser(user.uid),
      builder: (context, snapshot) {
        final recipes = snapshot.data ?? [];

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
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
              Text(
                'Your Stats',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 24),
              if (isMobile)
                // Stack stats vertically on mobile
                Column(
                  children: [
                    _buildStatItem(
                      'Total Recipes',
                      recipes.length.toString(),
                      Icons.restaurant_menu,
                      isMobile,
                    ),
                    const SizedBox(height: 12),
                    _buildStatItem(
                      'This Month',
                      recipes.where((r) {
                        final now = DateTime.now();
                        return r.createdAt?.month == now.month &&
                               r.createdAt?.year == now.year;
                      }).length.toString(),
                      Icons.calendar_today,
                      isMobile,
                    ),
                  ],
                )
              else
                // Side-by-side on desktop
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Total Recipes',
                        recipes.length.toString(),
                        Icons.restaurant_menu,
                        isMobile,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatItem(
                        'This Month',
                        recipes.where((r) {
                          final now = DateTime.now();
                          return r.createdAt?.month == now.month &&
                                 r.createdAt?.year == now.year;
                        }).length.toString(),
                        Icons.calendar_today,
                        isMobile,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryGreen, size: isMobile ? 28 : 32),
          SizedBox(width: isMobile ? 12 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
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

  Widget _buildRecipesTab(User user, bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            // Stack header elements vertically on mobile
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Recipes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your AI-crafted masterpieces',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyText,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecipeFormPage()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Recipe'),
                  ),
                ),
              ],
            )
          else
            // Side-by-side on desktop
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'My Recipes',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your AI-crafted masterpieces',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.greyText,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RecipeFormPage()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Recipe'),
                ),
              ],
            ),
          SizedBox(height: isMobile ? 24 : 32),
          StreamBuilder<List<RecipeModel>>(
            stream: _firestoreService.getRecipesByUser(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final recipes = snapshot.data ?? [];

              if (recipes.isEmpty) {
                return _buildEmptyState();
              }

              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth < 600 ? 1 : (screenWidth < 900 ? 2 : 3);
              
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: screenWidth < 600 ? 16 : 24,
                  mainAxisSpacing: screenWidth < 600 ? 16 : 24,
                  childAspectRatio: 0.75,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  return _buildRecipeCard(recipes[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(
              recipe: recipe,
            ),
          ),
        );
      },
      child: Container(
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
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                  ? kIsWeb
                      ? WebImage(
                          imageUrl: recipe.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(150);
                          },
                        )
                      : Image.network(
                          recipe.imageUrl!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 150,
                              color: AppTheme.cardBackground,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(150);
                          },
                        )
                  : _buildPlaceholderImage(150),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.greyText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.totalTime} min',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recipe.difficulty,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        recipe.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.greyText,
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    const Divider(
                      color: AppTheme.greyText,
                      height: 20,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          size: 14,
                          color: AppTheme.primaryGreen.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.ingredients.length} ingredients',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyText,
                          ),
                        ),
                        if (recipe.cuisine != null && recipe.cuisine!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.public,
                            size: 14,
                            color: AppTheme.primaryGreen.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              recipe.cuisine!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.greyText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
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

  Widget _buildPlaceholderImage(double height) {
    return Container(
      height: height,
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
          size: 60,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: AppTheme.greyText.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Recipes Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Start creating your culinary masterpieces!',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipeFormPage()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Recipe'),
            ),
          ],
        ),
      ),
    );
  }
}
