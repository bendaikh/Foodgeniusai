import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/scan_fridge_recipe_type.dart';
import '../theme/app_theme.dart';
import '../utils/ingredient_emoji_resolver.dart';
import '../services/voice_guide_service.dart';
import '../widgets/premium_audio_button.dart';
import '../widgets/voice_guide_route_aware.dart';

class DetectedIngredientsPage extends StatefulWidget {
  final List<String> initialIngredients;

  /// Optional restore values when returning from paywall / retry.
  final ScanFridgeRecipeType? initialRecipeType;
  final ScanFridgeCuisine initialCuisine;
  final ScanFridgeCookingTime initialCookingTime;
  final ScanFridgeDifficulty initialDifficulty;
  final String? initialDietary;

  const DetectedIngredientsPage({
    super.key,
    required this.initialIngredients,
    this.initialRecipeType,
    this.initialCuisine = ScanFridgeCuisine.any,
    this.initialCookingTime = ScanFridgeCookingTime.any,
    this.initialDifficulty = ScanFridgeDifficulty.any,
    this.initialDietary,
  });

  @override
  State<DetectedIngredientsPage> createState() =>
      _DetectedIngredientsPageState();
}

class _DetectedIngredientsPageState extends State<DetectedIngredientsPage>
    with VoiceGuideRouteAware {
  late final List<String> _originalDetected;
  late final List<String> _ingredients;
  final TextEditingController _addController = TextEditingController();

  ScanFridgeRecipeType? _selectedRecipeType;
  ScanFridgeCuisine _selectedCuisine = ScanFridgeCuisine.any;
  ScanFridgeCookingTime _selectedCookingTime = ScanFridgeCookingTime.any;
  ScanFridgeDifficulty _selectedDifficulty = ScanFridgeDifficulty.any;
  String? _selectedDietary;
  bool _isSubmitting = false;

  static const _dietaryOptions = <String>[
    'None',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Keto',
    'Paleo',
  ];

  @override
  VoiceGuideScreen get voiceGuideScreen => VoiceGuideScreen.scanIngredients;

  @override
  void initState() {
    super.initState();
    _originalDetected = List<String>.from(widget.initialIngredients);
    _ingredients = List<String>.from(widget.initialIngredients);
    _selectedRecipeType = widget.initialRecipeType;
    _selectedCuisine = widget.initialCuisine;
    _selectedCookingTime = widget.initialCookingTime;
    _selectedDifficulty = widget.initialDifficulty;
    _selectedDietary = widget.initialDietary;
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

  bool get _canGenerate =>
      !_isSubmitting &&
      _ingredients.isNotEmpty &&
      _selectedRecipeType != null;

  void _onGenerate() {
    final type = _selectedRecipeType;
    if (!_canGenerate || type == null) {
      if (kDebugMode) {
        debugPrint(
          '[ScanFridge] Generate blocked — recipeType null or empty ingredients',
        );
      }
      return;
    }

    // Guard against invalid / unexpected enum states.
    final cuisine = ScanFridgeCuisine.values.contains(_selectedCuisine)
        ? _selectedCuisine
        : ScanFridgeCuisine.any;
    final cookingTime =
        ScanFridgeCookingTime.values.contains(_selectedCookingTime)
            ? _selectedCookingTime
            : ScanFridgeCookingTime.any;
    final difficulty = ScanFridgeDifficulty.values.contains(_selectedDifficulty)
        ? _selectedDifficulty
        : ScanFridgeDifficulty.any;

    setState(() => _isSubmitting = true);
    debugLogScanFridgePreferences('Generate tapped', {
      'recipeType': type.id,
      'cuisine': cuisine.id,
      'cookingTime': cookingTime.id,
      'difficulty': difficulty.id,
      'dietary': _selectedDietary ?? 'None',
    });

    Navigator.pop(
      context,
      DetectedIngredientsResult(
        ingredients: List<String>.from(_ingredients),
        originalDetectedIngredients: List<String>.from(_originalDetected),
        recipeType: type,
        cuisine: cuisine,
        cookingTime: cookingTime,
        difficulty: difficulty,
        dietary: _selectedDietary,
      ),
    );
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.greyText,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 720 ? 4 : 2;

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text(
              'Review ingredients, then customize your recipe preferences.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.greyText,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 14),
            if (_ingredients.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No ingredients to review yet.',
                    style: TextStyle(color: AppTheme.greyText),
                  ),
                ),
              )
            else
              ...List.generate(_ingredients.length, (index) {
                final ingredient = _ingredients[index];
                final emoji = IngredientEmojiResolver.resolve(ingredient);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IngredientRow(
                    emoji: emoji,
                    ingredient: ingredient,
                    onEdit: () => _editIngredient(index),
                    onRemove: () {
                      setState(() => _ingredients.removeAt(index));
                    },
                  ),
                );
              }),
            const SizedBox(height: 10),
            _sectionTitle(
              'What would you like to make?',
              subtitle:
                  'Required. Generate stays locked until you choose one type.',
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ScanFridgeRecipeType.values.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: crossAxisCount >= 4 ? 1.4 : 1.5,
              ),
              itemBuilder: (context, index) {
                final type = ScanFridgeRecipeType.values[index];
                final selected = _selectedRecipeType == type;
                return _PreferenceCard(
                  icon: type.icon,
                  label: type.label,
                  selected: selected,
                  onTap: () {
                    setState(() => _selectedRecipeType = type);
                    if (kDebugMode) {
                      debugPrint(
                        '[ScanFridge] recipe type selected: ${type.id}',
                      );
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              'Choose a cuisine',
              subtitle: 'Optional. Defaults to Any Cuisine.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ScanFridgeCuisine.values.map((cuisine) {
                return _PreferenceChip(
                  icon: cuisine.icon,
                  label: cuisine.label,
                  selected: _selectedCuisine == cuisine,
                  onTap: () {
                    setState(() => _selectedCuisine = cuisine);
                    if (kDebugMode) {
                      debugPrint(
                        '[ScanFridge] cuisine selected: ${cuisine.id}',
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              'How much time do you have?',
              subtitle: 'Optional. Defaults to Any Time.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ScanFridgeCookingTime.values.map((time) {
                return _PreferenceChip(
                  icon: time.icon,
                  label: time.label,
                  selected: _selectedCookingTime == time,
                  onTap: () {
                    setState(() => _selectedCookingTime = time);
                    if (kDebugMode) {
                      debugPrint(
                        '[ScanFridge] cooking time selected: ${time.id}',
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              'Choose difficulty',
              subtitle: 'Optional. Defaults to Any Level.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ScanFridgeDifficulty.values.map((level) {
                return _PreferenceChip(
                  icon: level.icon,
                  label: level.label,
                  selected: _selectedDifficulty == level,
                  onTap: () {
                    setState(() => _selectedDifficulty = level);
                    if (kDebugMode) {
                      debugPrint(
                        '[ScanFridge] difficulty selected: ${level.id}',
                      );
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            _sectionTitle(
              'Dietary preferences',
              subtitle: 'Optional.',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _dietaryOptions.map((option) {
                final selected = _selectedDietary == option ||
                    (_selectedDietary == null && option == 'None');
                return ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _selectedDietary = option == 'None' ? null : option;
                    });
                    if (kDebugMode) {
                      debugPrint(
                        '[ScanFridge] dietary selected: '
                        '${option == 'None' ? 'None' : option}',
                      );
                    }
                  },
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.28),
                  backgroundColor: AppTheme.cardBackground,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.greyText,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                  side: BorderSide(
                    color: selected
                        ? AppTheme.primaryGreen
                        : AppTheme.primaryGreen.withValues(alpha: 0.22),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
            const SizedBox(height: 88),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_canGenerate && !_isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _ingredients.isEmpty
                        ? 'Add at least one ingredient to continue.'
                        : 'Select a recipe type to unlock Generate Recipe.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.greyText,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canGenerate ? _onGenerate : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor:
                        AppTheme.primaryGreen.withValues(alpha: 0.25),
                    disabledForegroundColor: Colors.white38,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppTheme.darkBackground,
                          ),
                        )
                      : const Text(
                          'Generate Recipe',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryGreen.withValues(alpha: 0.16)
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryGreen
                  : AppTheme.primaryGreen.withValues(alpha: 0.18),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? AppTheme.primaryGreen : Colors.white70,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.primaryGreen.withValues(alpha: 0.22)
                : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryGreen
                  : AppTheme.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? AppTheme.primaryGreen : Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final String emoji;
  final String ingredient;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _IngredientRow({
    required this.emoji,
    required this.ingredient,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
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
              onPressed: onEdit,
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
              onPressed: onRemove,
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
