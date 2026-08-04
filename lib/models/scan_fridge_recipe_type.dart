import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Recipe type choices shown after Scan Fridge ingredient review.
enum ScanFridgeRecipeType {
  mainDish,
  salad,
  soup,
  smoothieJuice,
  dessert,
  snack,
  breakfast,
  surpriseMe,
}

extension ScanFridgeRecipeTypeX on ScanFridgeRecipeType {
  String get id {
    switch (this) {
      case ScanFridgeRecipeType.mainDish:
        return 'main_dish';
      case ScanFridgeRecipeType.salad:
        return 'salad';
      case ScanFridgeRecipeType.soup:
        return 'soup';
      case ScanFridgeRecipeType.smoothieJuice:
        return 'smoothie_juice';
      case ScanFridgeRecipeType.dessert:
        return 'dessert';
      case ScanFridgeRecipeType.snack:
        return 'snack';
      case ScanFridgeRecipeType.breakfast:
        return 'breakfast';
      case ScanFridgeRecipeType.surpriseMe:
        return 'surprise_me';
    }
  }

  String get label {
    switch (this) {
      case ScanFridgeRecipeType.mainDish:
        return 'Main Dish';
      case ScanFridgeRecipeType.salad:
        return 'Salad';
      case ScanFridgeRecipeType.soup:
        return 'Soup';
      case ScanFridgeRecipeType.smoothieJuice:
        return 'Smoothie / Juice';
      case ScanFridgeRecipeType.dessert:
        return 'Dessert';
      case ScanFridgeRecipeType.snack:
        return 'Snack';
      case ScanFridgeRecipeType.breakfast:
        return 'Breakfast';
      case ScanFridgeRecipeType.surpriseMe:
        return 'Surprise Me';
    }
  }

  IconData get icon {
    switch (this) {
      case ScanFridgeRecipeType.mainDish:
        return Icons.dinner_dining_rounded;
      case ScanFridgeRecipeType.salad:
        return Icons.eco_rounded;
      case ScanFridgeRecipeType.soup:
        return Icons.soup_kitchen_rounded;
      case ScanFridgeRecipeType.smoothieJuice:
        return Icons.local_cafe_rounded;
      case ScanFridgeRecipeType.dessert:
        return Icons.cake_rounded;
      case ScanFridgeRecipeType.snack:
        return Icons.cookie_rounded;
      case ScanFridgeRecipeType.breakfast:
        return Icons.free_breakfast_rounded;
      case ScanFridgeRecipeType.surpriseMe:
        return Icons.auto_awesome_rounded;
    }
  }

  /// Value written into the AI `mealType` JSON field when not Surprise Me.
  String get mealTypeLabel {
    switch (this) {
      case ScanFridgeRecipeType.mainDish:
        return 'Main Dish';
      case ScanFridgeRecipeType.salad:
        return 'Salad';
      case ScanFridgeRecipeType.soup:
        return 'Soup';
      case ScanFridgeRecipeType.smoothieJuice:
        return 'Smoothie / Juice';
      case ScanFridgeRecipeType.dessert:
        return 'Dessert';
      case ScanFridgeRecipeType.snack:
        return 'Snack';
      case ScanFridgeRecipeType.breakfast:
        return 'Breakfast';
      case ScanFridgeRecipeType.surpriseMe:
        return 'Surprise';
    }
  }

  bool get isSurprise => this == ScanFridgeRecipeType.surpriseMe;

  /// Strict instructions injected into the generation prompt.
  String get promptConstraint {
    switch (this) {
      case ScanFridgeRecipeType.mainDish:
        return '''
REQUIRED RECIPE TYPE: Main Dish (strict / mandatory).
- Return ONLY a complete main meal / entrée suitable as the centerpiece of a meal.
- Do NOT return a drink, smoothie, juice, salad-only plate, soup-only bowl, dessert, snack, or side dish.
- The dish must be a full savory meal built around the provided ingredients.''';
      case ScanFridgeRecipeType.salad:
        return '''
REQUIRED RECIPE TYPE: Salad (strict / mandatory).
- Return ONLY a salad recipe (composed greens, chopped salad, grain salad, or similar).
- Do NOT return soup, juice, smoothie, dessert, snack, breakfast pastry, drink, or a hot main entrée.
- Dressing and toppings are fine; the dish must clearly be a salad.''';
      case ScanFridgeRecipeType.soup:
        return '''
REQUIRED RECIPE TYPE: Soup (strict / mandatory).
- Return ONLY a soup, broth, stew-style soup, or chowder.
- Do NOT return salad, juice, smoothie, dessert, snack, drink, or a dry plated main dish.
- The result must be a ladleable liquid-based dish.''';
      case ScanFridgeRecipeType.smoothieJuice:
        return '''
REQUIRED RECIPE TYPE: Smoothie / Juice (strict / mandatory).
- Return ONLY a drinkable smoothie, juice, or blended beverage recipe.
- Do NOT return solid food, a plated meal, salad, soup, dessert plate, snack plate, or cooked main dish.
- Include blending/juicing steps and serving as a drink.''';
      case ScanFridgeRecipeType.dessert:
        return '''
REQUIRED RECIPE TYPE: Dessert (strict / mandatory).
- Return ONLY a sweet dessert (cake, pudding, fruit dessert, cookies, ice cream style, etc.).
- Do NOT return a savory main dish, salad, soup, juice, smoothie, drink, or snack unless it is clearly a sweet dessert.''';
      case ScanFridgeRecipeType.snack:
        return '''
REQUIRED RECIPE TYPE: Snack (strict / mandatory).
- Return ONLY a light snack or small bite (not a full meal).
- Do NOT return a full main dish, multi-course meal, soup entrée, large salad meal, dessert cake, or a smoothie/juice drink.
- Keep it quick and snack-sized.''';
      case ScanFridgeRecipeType.breakfast:
        return '''
REQUIRED RECIPE TYPE: Breakfast (strict / mandatory).
- Return ONLY a breakfast-appropriate recipe (eggs, oatmeal, pancakes, breakfast bowl, toast dish, etc.).
- Do NOT return dinner-style main courses, dessert cakes, dinner soups, drinks, or dinner salads unless they are clearly breakfast versions.''';
      case ScanFridgeRecipeType.surpriseMe:
        return '''
RECIPE TYPE: Surprise Me.
- You may choose any suitable recipe type that best fits the ingredients
  (main dish, salad, soup, smoothie/juice, dessert, snack, or breakfast).
- Pick the most appetizing and practical option for the ingredients provided.
- Set mealType in the JSON to the type you chose.''';
    }
  }

  static ScanFridgeRecipeType? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final type in ScanFridgeRecipeType.values) {
      if (type.id == id || type.label == id || type.mealTypeLabel == id) {
        return type;
      }
    }
    return null;
  }
}

/// Optional cuisine preference for Scan Fridge generation.
enum ScanFridgeCuisine {
  any,
  italian,
  mexican,
  asian,
  american,
  mediterranean,
  french,
  indian,
  moroccan,
}

extension ScanFridgeCuisineX on ScanFridgeCuisine {
  String get id {
    switch (this) {
      case ScanFridgeCuisine.any:
        return 'any_cuisine';
      case ScanFridgeCuisine.italian:
        return 'italian';
      case ScanFridgeCuisine.mexican:
        return 'mexican';
      case ScanFridgeCuisine.asian:
        return 'asian';
      case ScanFridgeCuisine.american:
        return 'american';
      case ScanFridgeCuisine.mediterranean:
        return 'mediterranean';
      case ScanFridgeCuisine.french:
        return 'french';
      case ScanFridgeCuisine.indian:
        return 'indian';
      case ScanFridgeCuisine.moroccan:
        return 'moroccan';
    }
  }

  String get label {
    switch (this) {
      case ScanFridgeCuisine.any:
        return 'Any Cuisine';
      case ScanFridgeCuisine.italian:
        return 'Italian';
      case ScanFridgeCuisine.mexican:
        return 'Mexican';
      case ScanFridgeCuisine.asian:
        return 'Asian';
      case ScanFridgeCuisine.american:
        return 'American';
      case ScanFridgeCuisine.mediterranean:
        return 'Mediterranean';
      case ScanFridgeCuisine.french:
        return 'French';
      case ScanFridgeCuisine.indian:
        return 'Indian';
      case ScanFridgeCuisine.moroccan:
        return 'Moroccan';
    }
  }

  IconData get icon {
    switch (this) {
      case ScanFridgeCuisine.any:
        return Icons.public_rounded;
      case ScanFridgeCuisine.italian:
        return Icons.local_pizza_rounded;
      case ScanFridgeCuisine.mexican:
        return Icons.lunch_dining_rounded;
      case ScanFridgeCuisine.asian:
        return Icons.ramen_dining_rounded;
      case ScanFridgeCuisine.american:
        return Icons.outdoor_grill_rounded;
      case ScanFridgeCuisine.mediterranean:
        return Icons.spa_rounded;
      case ScanFridgeCuisine.french:
        return Icons.bakery_dining_rounded;
      case ScanFridgeCuisine.indian:
        return Icons.rice_bowl_rounded;
      case ScanFridgeCuisine.moroccan:
        return Icons.restaurant_rounded;
    }
  }

  bool get isAny => this == ScanFridgeCuisine.any;

  String get promptConstraint {
    if (isAny) {
      return '''
CUISINE: Any Cuisine.
- Choose the cuisine that best fits the available ingredients.
- Do not force a cuisine that requires many missing essential ingredients.''';
    }
    return '''
CUISINE: $label (must respect unless ingredients make it impossible).
- Style the recipe after $label cuisine (seasonings, techniques, presentation).
- Prioritize the user's available ingredients over perfect authenticity.
- Do NOT invent many unavailable essential ingredients just to match $label.
- Common pantry staples (salt, pepper, oil, basic spices) are acceptable.
- If a critical specialty ingredient is missing, list it clearly in missingIngredients
  instead of silently substituting the cuisine.''';
  }

  static ScanFridgeCuisine fromId(String? id) {
    if (id == null || id.isEmpty) return ScanFridgeCuisine.any;
    for (final value in ScanFridgeCuisine.values) {
      if (value.id == id || value.label == id) return value;
    }
    return ScanFridgeCuisine.any;
  }
}

/// Optional cooking-time preference for Scan Fridge generation.
enum ScanFridgeCookingTime {
  any,
  under15,
  from15to30,
  from30to60,
}

extension ScanFridgeCookingTimeX on ScanFridgeCookingTime {
  String get id {
    switch (this) {
      case ScanFridgeCookingTime.any:
        return 'any_time';
      case ScanFridgeCookingTime.under15:
        return 'under_15';
      case ScanFridgeCookingTime.from15to30:
        return '15_30';
      case ScanFridgeCookingTime.from30to60:
        return '30_60';
    }
  }

  String get label {
    switch (this) {
      case ScanFridgeCookingTime.any:
        return 'Any Time';
      case ScanFridgeCookingTime.under15:
        return 'Under 15 min';
      case ScanFridgeCookingTime.from15to30:
        return '15–30 min';
      case ScanFridgeCookingTime.from30to60:
        return '30–60 min';
    }
  }

  IconData get icon {
    switch (this) {
      case ScanFridgeCookingTime.any:
        return Icons.schedule_rounded;
      case ScanFridgeCookingTime.under15:
        return Icons.bolt_rounded;
      case ScanFridgeCookingTime.from15to30:
        return Icons.timer_rounded;
      case ScanFridgeCookingTime.from30to60:
        return Icons.hourglass_bottom_rounded;
    }
  }

  bool get isAny => this == ScanFridgeCookingTime.any;

  String get promptConstraint {
    switch (this) {
      case ScanFridgeCookingTime.any:
        return '''
COOKING TIME: Any Time.
- Choose a realistic prepTime + cookTime that suits the dish and ingredients.''';
      case ScanFridgeCookingTime.under15:
        return '''
COOKING TIME: Under 15 minutes (strict).
- prepTime + cookTime MUST be 15 minutes or less.
- Do NOT require long baking, marinating, resting, slow cooking, or overnight steps.
- Prefer quick stovetop, blender, no-cook, or microwave-friendly methods.''';
      case ScanFridgeCookingTime.from15to30:
        return '''
COOKING TIME: 15–30 minutes (strict).
- prepTime + cookTime MUST be between 15 and 30 minutes inclusive.
- Avoid multi-hour roasting, overnight marinating, or slow-cooker methods.''';
      case ScanFridgeCookingTime.from30to60:
        return '''
COOKING TIME: 30–60 minutes (strict).
- prepTime + cookTime MUST be between 30 and 60 minutes inclusive.
- Do not exceed 60 minutes total.''';
    }
  }

  static ScanFridgeCookingTime fromId(String? id) {
    if (id == null || id.isEmpty) return ScanFridgeCookingTime.any;
    for (final value in ScanFridgeCookingTime.values) {
      if (value.id == id || value.label == id) return value;
    }
    return ScanFridgeCookingTime.any;
  }
}

/// Optional difficulty preference for Scan Fridge generation.
enum ScanFridgeDifficulty {
  any,
  beginner,
  intermediate,
  advanced,
}

extension ScanFridgeDifficultyX on ScanFridgeDifficulty {
  String get id {
    switch (this) {
      case ScanFridgeDifficulty.any:
        return 'any_level';
      case ScanFridgeDifficulty.beginner:
        return 'beginner';
      case ScanFridgeDifficulty.intermediate:
        return 'intermediate';
      case ScanFridgeDifficulty.advanced:
        return 'advanced';
    }
  }

  String get label {
    switch (this) {
      case ScanFridgeDifficulty.any:
        return 'Any Level';
      case ScanFridgeDifficulty.beginner:
        return 'Beginner';
      case ScanFridgeDifficulty.intermediate:
        return 'Intermediate';
      case ScanFridgeDifficulty.advanced:
        return 'Advanced';
    }
  }

  /// Value for the recipe JSON `difficulty` field when not "Any".
  String get jsonDifficulty {
    switch (this) {
      case ScanFridgeDifficulty.any:
        return 'easy';
      case ScanFridgeDifficulty.beginner:
        return 'easy';
      case ScanFridgeDifficulty.intermediate:
        return 'medium';
      case ScanFridgeDifficulty.advanced:
        return 'hard';
    }
  }

  IconData get icon {
    switch (this) {
      case ScanFridgeDifficulty.any:
        return Icons.tune_rounded;
      case ScanFridgeDifficulty.beginner:
        return Icons.emoji_emotions_rounded;
      case ScanFridgeDifficulty.intermediate:
        return Icons.restaurant_menu_rounded;
      case ScanFridgeDifficulty.advanced:
        return Icons.workspace_premium_rounded;
    }
  }

  bool get isAny => this == ScanFridgeDifficulty.any;

  String get promptConstraint {
    switch (this) {
      case ScanFridgeDifficulty.any:
        return '''
DIFFICULTY: Any Level.
- Choose a difficulty that fits the ingredients and selected recipe type.
- Set difficulty in JSON to easy, medium, or hard.''';
      case ScanFridgeDifficulty.beginner:
        return '''
DIFFICULTY: Beginner (strict).
- Use simple steps, common equipment, and basic techniques only.
- Avoid advanced knife work, tempering, sous-vide, complex dough, or multi-stage sauces.
- Set difficulty in JSON to "easy".''';
      case ScanFridgeDifficulty.intermediate:
        return '''
DIFFICULTY: Intermediate (strict).
- May include more prep and moderate techniques (sauté, roast, simmer, basic baking).
- Avoid expert-only methods.
- Set difficulty in JSON to "medium".''';
      case ScanFridgeDifficulty.advanced:
        return '''
DIFFICULTY: Advanced (allowed).
- Complex techniques and longer, more precise instructions are acceptable.
- Still prioritize the user's available ingredients.
- Set difficulty in JSON to "hard".''';
    }
  }

  static ScanFridgeDifficulty fromId(String? id) {
    if (id == null || id.isEmpty) return ScanFridgeDifficulty.any;
    for (final value in ScanFridgeDifficulty.values) {
      if (value.id == id ||
          value.label == id ||
          value.jsonDifficulty == id) {
        return value;
      }
    }
    return ScanFridgeDifficulty.any;
  }
}

/// Result returned from the Scan Fridge ingredient review screen.
class DetectedIngredientsResult {
  final List<String> ingredients;
  final List<String> originalDetectedIngredients;
  final ScanFridgeRecipeType recipeType;
  final ScanFridgeCuisine cuisine;
  final ScanFridgeCookingTime cookingTime;
  final ScanFridgeDifficulty difficulty;
  final String? dietary;

  const DetectedIngredientsResult({
    required this.ingredients,
    required this.originalDetectedIngredients,
    required this.recipeType,
    this.cuisine = ScanFridgeCuisine.any,
    this.cookingTime = ScanFridgeCookingTime.any,
    this.difficulty = ScanFridgeDifficulty.any,
    this.dietary,
  });

  Map<String, String> get debugMap => {
        'recipeType': recipeType.id,
        'cuisine': cuisine.id,
        'cookingTime': cookingTime.id,
        'difficulty': difficulty.id,
        'dietary': dietary ?? 'None',
      };
}

void debugLogScanFridgePreferences(String stage, Map<String, String> prefs) {
  if (!kDebugMode) return;
  debugPrint(
    '[ScanFridge] $stage — '
    'recipeType=${prefs['recipeType']} '
    'cuisine=${prefs['cuisine']} '
    'cookingTime=${prefs['cookingTime']} '
    'difficulty=${prefs['difficulty']} '
    'dietary=${prefs['dietary']}',
  );
}
