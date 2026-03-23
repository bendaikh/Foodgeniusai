import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'my_creations_page.dart';

class KitchenTreasuresPage extends StatefulWidget {
  const KitchenTreasuresPage({super.key});

  @override
  State<KitchenTreasuresPage> createState() => _KitchenTreasuresPageState();
}

class _KitchenTreasuresPageState extends State<KitchenTreasuresPage> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'Kitchen Treasures',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                _buildForm(),
                const SizedBox(height: 40),
                if (_ingredients.isNotEmpty) _buildRevealButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Add the ingredients you have on hand.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Salmon, Spinach...',
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _addIngredient,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 20,
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          if (_ingredients.isNotEmpty) ...[
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _ingredients
                  .map((ingredient) => Chip(
                        label: Text(ingredient),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white,
                        ),
                        onDeleted: () {
                          setState(() {
                            _ingredients.remove(ingredient);
                          });
                        },
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
                        labelStyle: const TextStyle(color: Colors.white),
                        side: const BorderSide(
                          color: AppTheme.primaryGreen,
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevealButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MyCreationsPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: const Text(
          'Reveal Recipes',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  void _addIngredient() {
    if (_ingredientController.text.trim().isNotEmpty) {
      setState(() {
        _ingredients.add(_ingredientController.text.trim());
        _ingredientController.clear();
      });
    }
  }
}
