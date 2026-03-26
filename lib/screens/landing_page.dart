import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'pricing_page.dart';
import 'user_auth_page.dart';
import 'recipe_form_page.dart';
import 'user_account_page.dart';
import 'kitchen_treasures_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isHoveringRecipe = false;
  bool _isHoveringKitchen = false;

  void _handleStartCreating(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecipeFormPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserAuthPage()),
      );
    }
  }

  void _handleKitchenTreasures(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KitchenTreasuresPage()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserAuthPage()),
      );
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
              children: [
                _buildHeader(context),
                SizedBox(height: isMobile ? 40 : 60),
                _buildTitle(isMobile),
                SizedBox(height: isMobile ? 12 : 16),
                _buildSubtitle(isMobile),
                SizedBox(height: isMobile ? 40 : 60),
                _buildOptions(context, isMobile),
                SizedBox(height: isMobile ? 40 : 60),
                _buildFooter(isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (isMobile) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
        Text(
          'FoodGeniusAI',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (user != null)
                    _buildUserMenu(context, user, isMobile)
                  else ...[
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const UserAuthPage()),
                        );
                      },
                      icon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen, size: 20),
                      tooltip: 'Login',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'FoodGeniusAI',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          children: [
            const TextButton(
              onPressed: null,
              child: Text(
                'Home',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            const IconButton(
              onPressed: null,
              icon: Icon(Icons.wb_sunny_outlined, color: Colors.amber),
            ),
            const SizedBox(width: 8),
            if (user != null)
              _buildUserMenu(context, user, isMobile)
            else ...[
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UserAuthPage()),
                  );
                },
                icon: const Icon(Icons.person_outline, color: AppTheme.primaryGreen),
                tooltip: 'Login as User',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildUserMenu(BuildContext context, User user, bool isMobile) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        String displayName = 'User';
        
        if (snapshot.hasData && snapshot.data != null) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          displayName = data?['name'] ?? user.email?.split('@')[0] ?? 'User';
        } else {
          displayName = user.email?.split('@')[0] ?? 'User';
        }
        
        return PopupMenuButton<String>(
          offset: const Offset(0, 50),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: isMobile ? 4 : 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  color: AppTheme.primaryGreen,
                  size: isMobile ? 16 : 20,
                ),
                SizedBox(width: isMobile ? 4 : 8),
                Text(
                  displayName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: isMobile ? 4 : 8),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.primaryGreen,
                  size: isMobile ? 16 : 20,
                ),
              ],
            ),
          ),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, color: AppTheme.primaryGreen, size: 18),
                  SizedBox(width: 12),
                  Text('My Profile'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 18),
                  SizedBox(width: 12),
                  Text('Logout'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'profile') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserAccountPage()),
              );
            } else if (value == 'logout') {
              await AuthService().signOut();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out successfully'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Widget _buildTitle(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'AI-POWERED EXCELLENCE',
            style: TextStyle(
              color: AppTheme.primaryGreen,
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(height: isMobile ? 16 : 24),
        Text(
          'Elevate Your',
          style: TextStyle(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          'Culinary Vision',
          style: TextStyle(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubtitle(bool isMobile) {
    return Text(
      'Choose your path and let FoodGeniusAI guide you to\nprofessional perfection.',
      style: TextStyle(
        fontSize: isMobile ? 14 : 16,
        color: AppTheme.greyText,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOptions(BuildContext context, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildOptionCard(
            context,
            icon: Icons.restaurant_menu,
            title: 'Generate Recipe',
            description:
                'AI-crafted recipes based on your specific cravings and dietary needs.',
            buttonText: 'Start Creating',
            onPressed: () => _handleStartCreating(context),
            isMobile: true,
            isHovering: _isHoveringRecipe,
            onHoverChange: (hovering) => setState(() => _isHoveringRecipe = hovering),
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            context,
            icon: Icons.kitchen,
            title: 'Kitchen Treasures',
            description:
                'Turn your available ingredients into gourmet masterpieces.',
            buttonText: 'Find Magic',
            onPressed: () => _handleKitchenTreasures(context),
            isMobile: true,
            isHovering: _isHoveringKitchen,
            onHoverChange: (hovering) => setState(() => _isHoveringKitchen = hovering),
          ),
        ],
      );
    }
    
    return Row(
      children: [
        Expanded(
          child: _buildOptionCard(
            context,
            icon: Icons.restaurant_menu,
            title: 'Generate Recipe',
            description:
                'AI-crafted recipes based on your specific cravings and dietary needs.',
            buttonText: 'Start Creating',
            onPressed: () => _handleStartCreating(context),
            isMobile: false,
            isHovering: _isHoveringRecipe,
            onHoverChange: (hovering) => setState(() => _isHoveringRecipe = hovering),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildOptionCard(
            context,
            icon: Icons.kitchen,
            title: 'Kitchen Treasures',
            description:
                'Turn your available ingredients into gourmet masterpieces.',
            buttonText: 'Find Magic',
            onPressed: () => _handleKitchenTreasures(context),
            isMobile: false,
            isHovering: _isHoveringKitchen,
            onHoverChange: (hovering) => setState(() => _isHoveringKitchen = hovering),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
    required bool isMobile,
    required bool isHovering,
    required ValueChanged<bool> onHoverChange,
  }) {
    // Determine if this is the recipe or kitchen card
    bool isRecipeCard = title == 'Generate Recipe';
    
    return MouseRegion(
      onEnter: (_) => onHoverChange(true),
      onExit: (_) => onHoverChange(false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        transform: Matrix4.translationValues(0, isHovering ? -8 : 0, 0),
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isHovering
                ? AppTheme.primaryGreen.withOpacity(0.6)
                : AppTheme.primaryGreen.withOpacity(0.2),
            width: isHovering ? 2 : 1,
          ),
          boxShadow: isHovering
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedScale(
              scale: isHovering ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _buildAnimatedIcon(icon, isMobile, isRecipeCard),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 12 : 16),
            Text(
              description,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: AppTheme.greyText,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            AnimatedScale(
              scale: isHovering ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, bool isMobile, bool isRecipeCard) {
    return Icon(
      icon,
      size: isMobile ? 48 : 64,
      color: AppTheme.primaryGreen,
    );
  }

  Widget _buildFooter(bool isMobile) {
    if (isMobile) {
      return const Column(
        children: [
          _FooterItem(text: 'TRENDING: TRUFFLE INFUSION'),
          SizedBox(height: 16),
          _FooterItem(text: 'ANALYTICS: 98% TASTE MATCH'),
          SizedBox(height: 16),
          _FooterItem(text: 'CHEF INSIGHTS: SEARING MASTERY'),
        ],
      );
    }
    
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterItem(text: 'TRENDING: TRUFFLE INFUSION'),
        SizedBox(width: 32),
        _FooterItem(text: 'ANALYTICS: 98% TASTE MATCH'),
        SizedBox(width: 32),
        _FooterItem(text: 'CHEF INSIGHTS: SEARING MASTERY'),
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  final String text;
  
  const _FooterItem({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _GreenDot(),
        const SizedBox(width: 8),
        _FooterText(text: text),
      ],
    );
  }
}

class _GreenDot extends StatelessWidget {
  const _GreenDot();
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: AppTheme.primaryGreen,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  final String text;
  
  const _FooterText({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        color: AppTheme.greyText,
        letterSpacing: 1.0,
      ),
    );
  }
}
