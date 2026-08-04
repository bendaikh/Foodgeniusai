import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_theme.dart';
import 'recipe_detail_page.dart';
import '../models/recipe_model.dart';
import '../widgets/my_recipes_feed.dart';
import '../widgets/premium_audio_button.dart';
import '../widgets/web_image.dart';
import '../services/firestore_service.dart';
import '../services/recipe_deletion_service.dart';
import '../utils/app_message_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCreationsPage extends StatelessWidget {
  final bool embedInShell;
  final double bottomContentInset;

  const MyCreationsPage({
    super.key,
    this.embedInShell = false,
    this.bottomContentInset = 0,
  });

  Future<void> _unsave(BuildContext context, RecipeModel recipe) async {
    final id = recipe.id;
    if (id == null || id.isEmpty) return;
    try {
      await FirestoreService().setRecipeSaved(id, false);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Removed from Saved'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not unsave: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmAndDelete(BuildContext context, RecipeModel recipe) async {
    final confirmed = await AppMessageDialog.confirmDestructive(
      context: context,
      title: 'Delete this recipe?',
      message:
          'This recipe will be permanently removed from your account.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Delete',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await RecipeDeletionService.instance.deleteOwnedRecipe(recipe);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe deleted'),
          backgroundColor: AppTheme.primaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      await AppMessageDialog.showError(
        context: context,
        title: 'Could not delete',
        message: AppMessageDialog.cleanErrorMessage(e),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        bottom: bottomContentInset <= 0,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomContentInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!embedInShell)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const PremiumAudioButton(size: 40, iconSize: 20),
                    ],
                  )
                else
                  const Align(
                    alignment: Alignment.centerRight,
                    child: PremiumAudioButton(size: 40, iconSize: 20),
                  ),
                if (!embedInShell)
                  const SizedBox(height: 20)
                else
                  const SizedBox(height: 12),
                const Text(
                  'Saved',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recipes you bookmarked for later',
                  style: TextStyle(fontSize: 16, color: AppTheme.greyText),
                ),
                const SizedBox(height: 40),
                if (currentUser != null)
                  MyRecipesFeed(
                    userId: currentUser.uid,
                    nestedInScrollView: true,
                    savedOnly: true,
                    emptyTitle: 'No Saved Recipes',
                    emptyMessage:
                        'Tap the bookmark on a recipe to save it here.',
                    recipeCardBuilder:
                        (recipe) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildRecipeCard(context, recipe: recipe),
                        ),
                  )
                else
                  _buildNotLoggedInState(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, {required RecipeModel recipe}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailPage(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Stack(
                children: [
                  recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? kIsWeb
                          ? WebImage(
                            imageUrl: recipe.imageUrl!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                          : Image.network(
                            recipe.imageUrl!,
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 250,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: AppTheme.cardBackground,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage();
                            },
                          )
                      : _buildPlaceholderImage(),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: AppTheme.darkBackground.withValues(alpha: 0.75),
                      shape: const CircleBorder(),
                      child: PopupMenuButton<String>(
                        tooltip: 'Saved options',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        color: AppTheme.cardBackground,
                        onSelected: (value) async {
                          if (value == 'unsave') {
                            await _unsave(context, recipe);
                          } else if (value == 'delete') {
                            await _confirmAndDelete(context, recipe);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'unsave',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bookmark_remove_outlined,
                                  color: AppTheme.primaryGreen,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Unsave',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'READY TO COOK',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppTheme.greyText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${recipe.prepTime + recipe.cookTime} min',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.greyText,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recipe.difficulty,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 250,
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
        child: Icon(Icons.restaurant, size: 80, color: AppTheme.primaryGreen),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
              style: TextStyle(fontSize: 16, color: AppTheme.greyText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Create Recipe'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 24),
            const Text(
              'Error Loading Recipes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              style: const TextStyle(fontSize: 14, color: AppTheme.greyText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedInState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 80, color: AppTheme.primaryGreen),
            SizedBox(height: 24),
            Text(
              'Please Log In',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Log in to view your recipes',
              style: TextStyle(fontSize: 16, color: AppTheme.greyText),
            ),
          ],
        ),
      ),
    );
  }
}
