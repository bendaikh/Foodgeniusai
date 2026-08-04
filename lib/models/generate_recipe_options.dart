/// Centralized Standard Generate Recipe option lists and validation.
class GenerateRecipeOptions {
  GenerateRecipeOptions._();

  static const mealTypes = <String>[
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Drink',
    'Surprise Me',
  ];

  /// Concrete meal types the AI may return (excludes Surprise Me).
  static const concreteMealTypes = <String>[
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Dessert',
    'Drink',
  ];

  static const mainGoals = <String>[
    'Lose Weight',
    'Maintain Weight',
    'Gain Weight',
    'Build Muscle',
    'High Protein',
    'Low Carb',
    'Balanced',
    'Just Enjoy',
  ];

  static const dietaryPreferences = <String>[
    'None',
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Keto',
    'Paleo',
    'Dairy-Free',
    'Halal',
  ];

  static const allergies = <String>[
    'No Allergies',
    'Nuts',
    'Peanuts',
    'Dairy',
    'Eggs',
    'Gluten',
    'Shellfish',
    'Soy',
    'Sesame',
  ];

  static const surpriseMe = 'Surprise Me';
  static const dietaryNone = 'None';
  static const noAllergies = 'No Allergies';
  static const notSpecified = 'Not specified';

  static bool isValidMealType(String? value) =>
      value != null && mealTypes.contains(value.trim());

  static bool isValidConcreteMealType(String? value) =>
      value != null && concreteMealTypes.contains(value.trim());

  static bool isValidMainGoal(String? value) =>
      value != null && mainGoals.contains(value.trim());

  static bool isValidDietaryList(List<String> values) {
    if (values.isEmpty) return false;
    if (values.contains(dietaryNone) && values.length > 1) return false;
    return values.every(dietaryPreferences.contains);
  }

  static bool isValidAllergyList(List<String> values) {
    if (values.isEmpty) return false;
    if (values.contains(noAllergies) && values.length > 1) return false;
    return values.every(allergies.contains);
  }
}

/// Validated Standard Generate Recipe request used by form, pending store, and AI.
class GenerateRecipeRequest {
  final String craving;
  final String mealType;
  final String mainGoal;
  final int servings;
  final List<String> dietaryPreferences;
  final List<String> allergies;

  const GenerateRecipeRequest({
    required this.craving,
    required this.mealType,
    required this.mainGoal,
    required this.servings,
    required this.dietaryPreferences,
    required this.allergies,
  });

  bool get isSurpriseMealType =>
      mealType == GenerateRecipeOptions.surpriseMe;

  /// Throws [ArgumentError] when any required field is invalid.
  void validate() {
    final trimmed = craving.trim();
    if (trimmed.length < 2) {
      throw ArgumentError('Please enter a recipe idea.');
    }
    if (servings < 1) {
      throw ArgumentError('Please select the number of servings.');
    }
    if (!GenerateRecipeOptions.isValidMealType(mealType)) {
      throw ArgumentError('Please choose a meal type.');
    }
    if (!GenerateRecipeOptions.isValidMainGoal(mainGoal)) {
      throw ArgumentError('Please select your main goal.');
    }
    if (!GenerateRecipeOptions.isValidDietaryList(dietaryPreferences)) {
      throw ArgumentError('Please select a dietary preference.');
    }
    if (!GenerateRecipeOptions.isValidAllergyList(allergies)) {
      throw ArgumentError('Please select an allergy preference.');
    }
  }

  /// Creates a validated request or throws [ArgumentError].
  factory GenerateRecipeRequest.validated({
    required String craving,
    required String? mealType,
    required String? mainGoal,
    required int? servings,
    required List<String> dietaryPreferences,
    required List<String> allergies,
  }) {
    final request = GenerateRecipeRequest(
      craving: craving.trim(),
      mealType: (mealType ?? '').trim(),
      mainGoal: (mainGoal ?? '').trim(),
      servings: servings ?? 0,
      dietaryPreferences: List<String>.from(dietaryPreferences),
      allergies: List<String>.from(allergies),
    );
    request.validate();
    return request;
  }

  /// First missing-field hint for the Generate button area.
  static String? firstMissingHint({
    required String craving,
    required int? servings,
    required String? mealType,
    required String? mainGoal,
  }) {
    if (craving.trim().length < 2) return 'Enter a recipe idea.';
    if (servings == null || servings < 1) return 'Select servings.';
    if (!GenerateRecipeOptions.isValidMealType(mealType)) {
      return 'Choose a meal type.';
    }
    if (!GenerateRecipeOptions.isValidMainGoal(mainGoal)) {
      return 'Select your main goal.';
    }
    return null;
  }
}

/// Prevents overlapping pending-resume / paywall-resume generation starts.
class GenerationResumeGuard {
  bool _inFlight = false;

  bool get isInFlight => _inFlight;

  bool tryAcquire() {
    if (_inFlight) return false;
    _inFlight = true;
    return true;
  }

  void release() {
    _inFlight = false;
  }
}

/// Parse/validation failures must never consume recipe quota.
bool shouldConsumeQuotaOnGenerationFailure(Object error) =>
    error is! RecipeAiResponseException;

/// Thrown when the AI response is missing/invalid required fields.
class RecipeAiResponseException implements Exception {
  final String message;
  const RecipeAiResponseException(this.message);

  @override
  String toString() => message;
}

/// Builds the Standard Generate Recipe prompt (testable, no network).
class GenerateRecipePromptBuilder {
  GenerateRecipePromptBuilder._();

  static String build(GenerateRecipeRequest request) {
    request.validate();

    final dietaryLabel = request.dietaryPreferences.join(', ');
    final allergiesLabel = request.allergies.join(', ');
    final mealTypeExample = request.isSurpriseMealType
        ? 'Breakfast'
        : request.mealType;

    return '''
You are a professional chef. Create a recipe for: ${request.craving}

USER-SELECTED VALUES (mandatory — come only from validated form selections):
- Recipe idea: ${request.craving}
- Servings: ${request.servings}
- Meal type: ${request.mealType}
- Main goal: ${request.mainGoal}
- Dietary preferences: $dietaryLabel
- Allergies: $allergiesLabel

Hard rules:
1. Never invent missing user preferences.
2. Required values come only from the validated selections above.
3. Do not invent servings, meal type, main goal, dietary preferences, or allergies.
4. Servings in JSON must be exactly ${request.servings}.
5. Meal type must follow the selected type unless "Surprise Me" is selected.
6. If meal type is "Surprise Me", choose exactly one concrete type from: ${GenerateRecipeOptions.concreteMealTypes.join(', ')}.
7. Otherwise mealType in JSON must be exactly "${request.mealType}".
8. Goal, dietary restrictions, and allergies are hard constraints.
9. Nutrition values are estimates only.
10. Do not assume any cuisine or difficulty preference. Set cuisine and difficulty to "${GenerateRecipeOptions.notSpecified}" unless the recipe idea itself clearly implies them.
11. Return structured JSON compatible with the schema below.

IMPORTANT: Return ONLY valid JSON, no other text. Use this exact structure:

{
  "title": "Recipe Name Here",
  "description": "Brief appetizing description",
  "cuisine": "${GenerateRecipeOptions.notSpecified}",
  "mealType": "$mealTypeExample",
  "difficulty": "${GenerateRecipeOptions.notSpecified}",
  "prepTime": 15,
  "cookTime": 30,
  "servings": ${request.servings},
  "ingredients": [
    {"name": "ingredient", "amount": "1", "unit": "piece"}
  ],
  "instructions": [
    {"step": 1, "text": "First step"},
    {"step": 2, "text": "Second step"}
  ],
  "dietary": ${_jsonStringList(request.dietaryPreferences)},
  "nutrition": {
    "calories": "350",
    "protein": "25g",
    "carbs": "40g",
    "fat": "10g"
  }
}

Return ONLY the JSON object, nothing else.
''';
  }

  static String _jsonStringList(List<String> values) {
    final escaped = values.map((v) => '"${v.replaceAll('"', '\\"')}"').join(', ');
    return '[$escaped]';
  }
}

/// Parses and validates a Standard Generate Recipe AI JSON payload.
class GenerateRecipeResponseParser {
  GenerateRecipeResponseParser._();

  /// Parses an already-decoded JSON map with the validated user request.
  static ParsedGenerateRecipe parseDecoded({
    required Map<String, dynamic> recipeData,
    required GenerateRecipeRequest request,
  }) {
    request.validate();

    final title = recipeData['title']?.toString().trim() ?? '';
    if (title.isEmpty) {
      throw const RecipeAiResponseException(
        'The AI response was missing a recipe title. Please try again.',
      );
    }

    final rawServings = recipeData['servings'];
    final parsedServings = rawServings is int
        ? rawServings
        : int.tryParse(rawServings?.toString() ?? '');
    if (parsedServings == null) {
      throw const RecipeAiResponseException(
        'The AI response was missing servings. Please try again.',
      );
    }
    if (parsedServings != request.servings) {
      throw RecipeAiResponseException(
        'The AI returned $parsedServings servings instead of ${request.servings}. Please try again.',
      );
    }

    final rawMealType = recipeData['mealType']?.toString().trim() ?? '';
    if (rawMealType.isEmpty) {
      throw const RecipeAiResponseException(
        'The AI response was missing a meal type. Please try again.',
      );
    }

    late final String resolvedMealType;
    if (request.isSurpriseMealType) {
      if (!GenerateRecipeOptions.isValidConcreteMealType(rawMealType)) {
        throw RecipeAiResponseException(
          'The AI returned an invalid meal type "$rawMealType". Please try again.',
        );
      }
      resolvedMealType = rawMealType;
    } else {
      if (rawMealType != request.mealType) {
        throw RecipeAiResponseException(
          'The AI changed the meal type to "$rawMealType". Please try again.',
        );
      }
      resolvedMealType = request.mealType;
    }

    final ingredients = <Map<String, dynamic>>[];
    final rawIngredients = recipeData['ingredients'];
    if (rawIngredients is List) {
      for (final ing in rawIngredients) {
        if (ing is Map) {
          final name = ing['name']?.toString() ?? '';
          if (name.trim().isEmpty) continue;
          ingredients.add({
            'name': name,
            'amount': ing['amount']?.toString() ?? '',
            'unit': ing['unit']?.toString() ?? '',
          });
        } else if (ing is String && ing.trim().isNotEmpty) {
          ingredients.add({'name': ing, 'amount': '', 'unit': ''});
        }
      }
    }
    if (ingredients.isEmpty) {
      throw const RecipeAiResponseException(
        'The AI response was missing ingredients. Please try again.',
      );
    }

    final instructions = <Map<String, dynamic>>[];
    final rawInstructions = recipeData['instructions'];
    if (rawInstructions is List) {
      var step = 1;
      for (final inst in rawInstructions) {
        if (inst is Map) {
          final text = inst['text']?.toString() ?? '';
          if (text.trim().isEmpty) continue;
          instructions.add({
            'step': inst['step'] ?? step,
            'text': text,
          });
        } else if (inst is String && inst.trim().isNotEmpty) {
          instructions.add({'step': step, 'text': inst});
        }
        step++;
      }
    }
    if (instructions.isEmpty) {
      throw const RecipeAiResponseException(
        'The AI response was missing instructions. Please try again.',
      );
    }

    final prepTime = int.tryParse(recipeData['prepTime']?.toString() ?? '');
    final cookTime = int.tryParse(recipeData['cookTime']?.toString() ?? '');
    if (prepTime == null || cookTime == null || prepTime < 0 || cookTime < 0) {
      throw const RecipeAiResponseException(
        'The AI response had invalid prep/cook times. Please try again.',
      );
    }

    final cuisineRaw = recipeData['cuisine']?.toString().trim() ?? '';
    final difficultyRaw = recipeData['difficulty']?.toString().trim() ?? '';
    final cuisine = cuisineRaw.isEmpty
        ? GenerateRecipeOptions.notSpecified
        : cuisineRaw;
    final difficulty = difficultyRaw.isEmpty
        ? GenerateRecipeOptions.notSpecified
        : difficultyRaw;

    // Always trust validated user dietary preferences.
    final dietary = List<String>.from(request.dietaryPreferences);

    return ParsedGenerateRecipe(
      title: title,
      description: recipeData['description']?.toString().trim().isNotEmpty == true
          ? recipeData['description'].toString().trim()
          : 'A delicious recipe',
      cuisine: cuisine,
      mealType: resolvedMealType,
      difficulty: difficulty,
      prepTime: prepTime,
      cookTime: cookTime,
      servings: request.servings,
      ingredients: ingredients,
      instructions: instructions,
      dietary: dietary,
      nutrition: recipeData['nutrition'] is Map
          ? Map<String, dynamic>.from(recipeData['nutrition'] as Map)
          : <String, dynamic>{},
      mainGoal: request.mainGoal,
      allergies: List<String>.from(request.allergies),
    );
  }
}

class ParsedGenerateRecipe {
  final String title;
  final String description;
  final String cuisine;
  final String mealType;
  final String difficulty;
  final int prepTime;
  final int cookTime;
  final int servings;
  final List<Map<String, dynamic>> ingredients;
  final List<Map<String, dynamic>> instructions;
  final List<String> dietary;
  final Map<String, dynamic> nutrition;
  final String mainGoal;
  final List<String> allergies;

  const ParsedGenerateRecipe({
    required this.title,
    required this.description,
    required this.cuisine,
    required this.mealType,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.dietary,
    required this.nutrition,
    required this.mainGoal,
    required this.allergies,
  });
}
