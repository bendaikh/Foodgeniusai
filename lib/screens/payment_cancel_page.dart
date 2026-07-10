import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import '../services/pending_recipe_service.dart';
import '../services/recipe_generation_service.dart';
import '../theme/app_theme.dart';
import '../utils/recipe_navigation.dart';
import 'auth_wrapper.dart';

class PaymentCancelPage extends StatefulWidget {
  const PaymentCancelPage({super.key});

  @override
  State<PaymentCancelPage> createState() => _PaymentCancelPageState();
}

class _PaymentCancelPageState extends State<PaymentCancelPage> {
  final RecipeGenerationService _recipeGenerationService = RecipeGenerationService();
  RecipeModel? _recipe;
  bool _isLoading = true;

  bool get _isMobileCallback {
    if (!kIsWeb) return false;
    return Uri.base.queryParameters['source'] == 'mobile';
  }

  @override
  void initState() {
    super.initState();
    _restoreRecipe();
  }

  Future<void> _restoreRecipe() async {
    final saved = await _recipeGenerationService.syncPendingToMyRecipes();
    final local = saved ?? PendingRecipeService.instance.loadLocal();
    if (!mounted) return;
    setState(() {
      _recipe = local;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final recipe = _recipe;

    if (_isMobileCallback) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A1628),
                Color(0xFF0F2A3D),
                Color(0xFF0A1628),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 36,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payment_outlined,
                          color: AppTheme.greyText,
                          size: 56,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Payment Cancelled',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No charges were made. Close this page and return to the GourmetAI app to choose a plan when you\'re ready.',
                          style: TextStyle(
                            color: AppTheme.greyText,
                            fontSize: 15,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.payment_outlined,
                    color: AppTheme.greyText,
                    size: 56,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Payment cancelled',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No charges were made. Your recipe is saved in My Recipes. Subscribe to unlock the full content.',
                    style: TextStyle(color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (recipe != null)
                    ElevatedButton(
                      onPressed: () {
                        RecipeNavigation.openRecipeDetailFromCheckout(
                          context,
                          recipe,
                        );
                      },
                      child: const Text('Back to my recipe'),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const AuthWrapper(),
                          ),
                          (route) => false,
                        );
                      },
                      child: const Text('Back to home'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
