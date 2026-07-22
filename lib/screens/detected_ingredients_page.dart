import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/ingredient_emoji_resolver.dart';
import '../services/voice_guide_service.dart';
import '../widgets/premium_audio_button.dart';
import '../widgets/voice_guide_route_aware.dart';

class DetectedIngredientsPage extends StatefulWidget {
  final List<String> initialIngredients;

  const DetectedIngredientsPage({super.key, required this.initialIngredients});

  @override
  State<DetectedIngredientsPage> createState() =>
      _DetectedIngredientsPageState();
}

class _DetectedIngredientsPageState extends State<DetectedIngredientsPage>
    with VoiceGuideRouteAware {
  late final List<String> _ingredients;
  final TextEditingController _addController = TextEditingController();

  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.scanIngredients;

  @override
  void initState() {
    super.initState();
    _ingredients = List<String>.from(widget.initialIngredients);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initVoiceGuide();
  }

  @override
  void dispose() {
    disposeVoiceGuide();
    _addController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final value = _addController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _ingredients.add(value);
      _addController.clear();
    });
  }

  Future<void> _editIngredient(int index) async {
    final controller = TextEditingController(text: _ingredients[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit ingredient',
            style: TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Ingredient name'),
            onSubmitted: (value) => Navigator.pop(context, value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _ingredients[index] = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBackground,
        foregroundColor: Colors.white,
        title: const Text('Detected Ingredients'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: PremiumAudioButton(size: 36, iconSize: 18)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review, edit, or remove ingredients before generating recipes.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.greyText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: const InputDecoration(
                            hintText: 'Add missing ingredient',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _addIngredient(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _addIngredient,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _ingredients.isEmpty
                      ? const Center(
                        child: Text(
                          'No ingredients to review yet.',
                          style: TextStyle(color: AppTheme.greyText),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
                        itemCount: _ingredients.length,
                        itemBuilder: (context, index) {
                          final ingredient = _ingredients[index];
                          final emoji = IngredientEmojiResolver.resolve(
                            ingredient,
                          );

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryGreen.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                _IngredientEmojiBadge(emoji: emoji),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    ingredient,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Edit',
                                    onPressed: () => _editIngredient(index),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppTheme.primaryGreen,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Remove',
                                    onPressed: () {
                                      setState(
                                        () => _ingredients.removeAt(index),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, List<String>.from(_ingredients));
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Generate Recipes',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientEmojiBadge extends StatelessWidget {
  final String emoji;

  const _IngredientEmojiBadge({required this.emoji});

  static const double _size = 52;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.18),
        ),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 26, height: 1),
        textAlign: TextAlign.center,
      ),
    );
  }
}
