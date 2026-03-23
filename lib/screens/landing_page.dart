import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'pricing_page.dart';
import 'user_auth_page.dart';
import 'recipe_form_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  void _handleStartCreating(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;
    
    if (user != null) {
      // User is logged in, go directly to recipe form
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RecipeFormPage()),
      );
    } else {
      // User not logged in, go to auth page
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
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
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
    
    if (isMobile) {
      // Mobile header - simplified
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'GourmetAI',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                  IconButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin');
                    },
                    icon: const Icon(Icons.admin_panel_settings, color: AppTheme.greyText, size: 20),
                    tooltip: 'Admin',
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }
    
    // Desktop header - full version
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'GourmetAI',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () {},
              child: const Text(
                'Home',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Collection',
                style: TextStyle(color: AppTheme.greyText),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.wb_sunny_outlined, color: Colors.amber),
            ),
            const SizedBox(width: 8),
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
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
              icon: const Icon(Icons.admin_panel_settings,
                  color: AppTheme.greyText),
              tooltip: 'Admin Panel',
            ),
          ],
        ),
      ],
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
      'Choose your path and let GourmetAI guide you to\nprofessional perfection.',
      style: TextStyle(
        fontSize: isMobile ? 14 : 16,
        color: AppTheme.greyText,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildOptions(BuildContext context, bool isMobile) {
    if (isMobile) {
      // Stack cards vertically on mobile
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
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            context,
            icon: Icons.kitchen,
            title: 'Kitchen Treasures',
            description:
                'Turn your available ingredients into gourmet masterpieces.',
            buttonText: 'Find Magic',
            onPressed: () => _handleStartCreating(context),
            isMobile: true,
          ),
        ],
      );
    }
    
    // Side by side on desktop
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
            onPressed: () => _handleStartCreating(context),
            isMobile: false,
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
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: isMobile ? 48 : 64,
            color: AppTheme.primaryGreen,
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
          ElevatedButton(
            onPressed: onPressed,
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    if (isMobile) {
      // Stack footer items vertically on mobile
      return Column(
        children: [
          _buildFooterItem('TRENDING: TRUFFLE INFUSION'),
          const SizedBox(height: 16),
          _buildFooterItem('ANALYTICS: 98% TASTE MATCH'),
          const SizedBox(height: 16),
          _buildFooterItem('CHEF INSIGHTS: SEARING MASTERY'),
        ],
      );
    }
    
    // Horizontal layout for desktop
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFooterItem('TRENDING: TRUFFLE INFUSION'),
        const SizedBox(width: 32),
        _buildFooterItem('ANALYTICS: 98% TASTE MATCH'),
        const SizedBox(width: 32),
        _buildFooterItem('CHEF INSIGHTS: SEARING MASTERY'),
      ],
    );
  }

  Widget _buildFooterItem(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.greyText,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}
