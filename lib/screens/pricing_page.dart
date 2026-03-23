import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'recipe_form_page.dart';
import 'kitchen_treasures_page.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: 60),
                _buildTitle(),
                const SizedBox(height: 60),
                _buildPricingCards(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          'Select Your Culinary Experience',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        Text(
          'Choose a plan to start your journey into elite AI cooking.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.greyText,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPricingCards(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildPricingCard(
            context,
            icon: '🌱',
            title: 'Free Tier',
            price: '\$0',
            period: '/ year',
            features: [
              'Basic Recipes',
              'Standard Quality Images',
              'Limited History',
            ],
            buttonText: 'Choose Free',
            isPopular: false,
            onPressed: () {
              _showFeatureSelection(context);
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildPricingCard(
            context,
            icon: '💎',
            title: 'Gourmet Pro',
            price: '\$12',
            period: '/ month',
            features: [
              'Ultra-Realistic Images',
              'Advanced AI Recipes',
              'Unlimited Portfolio',
            ],
            buttonText: 'Get Pro',
            isPopular: true,
            onPressed: () {
              _showFeatureSelection(context);
            },
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildPricingCard(
            context,
            icon: '👑',
            title: 'Michelin Elite',
            price: '\$29',
            period: '/ month',
            features: [
              'Michelin Star Precision',
              '8K Hyper-Realistic Images',
              'Priority Generation',
            ],
            buttonText: 'Go Elite',
            isPopular: false,
            onPressed: () {
              _showFeatureSelection(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String price,
    required String period,
    required List<String> features,
    required String buttonText,
    required bool isPopular,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPopular
              ? AppTheme.primaryGreen
              : AppTheme.primaryGreen.withOpacity(0.2),
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
              ),
              child: const Center(
                child: Text(
                  'POPULAR',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        period,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                ...features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            feature,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPopular
                          ? AppTheme.primaryGreen
                          : Colors.transparent,
                      foregroundColor:
                          isPopular ? AppTheme.darkBackground : Colors.white,
                      side: isPopular
                          ? null
                          : const BorderSide(
                              color: AppTheme.primaryGreen,
                            ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFeatureSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to do?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RecipeFormPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Generate Recipe'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const KitchenTreasuresPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                side: const BorderSide(color: AppTheme.primaryGreen),
              ),
              child: const Text('Kitchen Treasures'),
            ),
          ],
        ),
      ),
    );
  }
}
