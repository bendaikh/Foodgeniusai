import 'package:flutter/material.dart';

import '../services/pending_recipe_store.dart';
import '../theme/app_theme.dart';
import 'auth_wrapper.dart';
import 'recipe_detail_page.dart';

class PaymentCancelPage extends StatelessWidget {
  const PaymentCancelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final recipe = PendingRecipeStore.instance.load();

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
                    'No charges were made. You can return to your recipe and try again whenever you are ready.',
                    style: TextStyle(color: AppTheme.greyText),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (recipe != null)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) =>
                                RecipeDetailPage(recipe: recipe),
                          ),
                          (route) => false,
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
