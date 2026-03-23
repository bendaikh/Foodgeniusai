import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/image_upload_widget.dart';

/// Example: How to use ImageUploadWidget in your recipe form
/// 
/// This is a demo showing the integration.
/// Copy the relevant parts to your actual recipe form page.

class RecipeFormWithImageExample extends StatefulWidget {
  const RecipeFormWithImageExample({super.key});

  @override
  State<RecipeFormWithImageExample> createState() =>
      _RecipeFormWithImageExampleState();
}

class _RecipeFormWithImageExampleState
    extends State<RecipeFormWithImageExample> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _recipeImageUrl;
  
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Get current user ID (replace with your actual auth logic)
    final currentUserId = _authService.currentUser?.uid ?? 'guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Recipe'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipe Image Upload Section
            const Text(
              'RECIPE IMAGE',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            // Image Upload Widget
            ImageUploadWidget(
              userId: currentUserId,
              isRecipeImage: true,
              initialImageUrl: _recipeImageUrl,
              onImageUploaded: (imageUrl) {
                setState(() {
                  _recipeImageUrl = imageUrl;
                });
                print('Recipe image uploaded: $imageUrl');
              },
              height: 250,
              width: double.infinity,
            ),
            
            const SizedBox(height: 32),

            // Recipe Title
            const Text(
              'RECIPE TITLE',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Creamy Italian Pasta',
              ),
            ),

            const SizedBox(height: 24),

            // Recipe Description
            const Text(
              'DESCRIPTION',
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe your recipe...',
              ),
            ),

            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRecipe,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  'Save Recipe',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveRecipe() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe title')),
      );
      return;
    }

    // Here you would save to Firestore with the image URL
    print('Saving recipe:');
    print('Title: ${_titleController.text}');
    print('Description: ${_descriptionController.text}');
    print('Image URL: $_recipeImageUrl');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe saved! (Demo only)')),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
