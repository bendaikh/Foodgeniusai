import 'package:flutter/material.dart';

import '../models/recipe_model.dart';
import '../screens/recipe_detail_page.dart';
import '../screens/user_account_page.dart';

class RecipeNavigation {
  static const int myRecipesTab = 1;

  static void openRecipeDetail(BuildContext context, RecipeModel recipe) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailPage(recipe: recipe),
      ),
    );
  }

  /// Opens recipe detail with My Recipes as the route below it.
  static void openRecipeDetailFromCheckout(
    BuildContext context,
    RecipeModel recipe,
  ) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const UserAccountPage(initialTab: myRecipesTab),
      ),
      (route) => false,
    );
    openRecipeDetail(context, recipe);
  }

  static void goBackFromRecipeDetail(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const UserAccountPage(initialTab: myRecipesTab),
        ),
        (route) => false,
      );
    }
  }
}
