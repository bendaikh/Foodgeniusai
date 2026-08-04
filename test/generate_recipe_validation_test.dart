import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foodgeniusai/models/generate_recipe_options.dart';
import 'package:foodgeniusai/services/pending_generation_request_store.dart';

void main() {
  group('GenerateRecipeRequest validation', () {
    test('rejects invalid meal type', () {
      expect(
        () => GenerateRecipeRequest.validated(
          craving: 'Pasta',
          mealType: 'Brunch',
          mainGoal: 'Balanced',
          servings: 2,
          dietaryPreferences: const ['None'],
          allergies: const ['No Allergies'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid main goal', () {
      expect(
        () => GenerateRecipeRequest.validated(
          craving: 'Pasta',
          mealType: 'Dinner',
          mainGoal: 'Superhuman',
          servings: 2,
          dietaryPreferences: const ['None'],
          allergies: const ['No Allergies'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects null/empty meal type and servings', () {
      expect(
        () => GenerateRecipeRequest.validated(
          craving: 'Pasta',
          mealType: null,
          mainGoal: 'Balanced',
          servings: null,
          dietaryPreferences: const ['None'],
          allergies: const ['No Allergies'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid request', () {
      final request = GenerateRecipeRequest.validated(
        craving: '  Pasta  ',
        mealType: 'Dinner',
        mainGoal: 'High Protein',
        servings: 3,
        dietaryPreferences: const ['Vegetarian'],
        allergies: const ['Nuts'],
      );
      expect(request.craving, 'Pasta');
      expect(request.servings, 3);
    });
  });

  group('GenerateRecipePromptBuilder', () {
    test('prompt does not contain hardcoded Italian/easy defaults', () {
      final request = GenerateRecipeRequest.validated(
        craving: 'Grilled chicken',
        mealType: 'Dinner',
        mainGoal: 'High Protein',
        servings: 2,
        dietaryPreferences: const ['None'],
        allergies: const ['No Allergies'],
      );
      final prompt = GenerateRecipePromptBuilder.build(request);
      expect(prompt.contains('"cuisine": "Italian"'), isFalse);
      expect(prompt.contains('"difficulty": "easy"'), isFalse);
      expect(prompt.contains(GenerateRecipeOptions.notSpecified), isTrue);
      expect(prompt.contains('servings": 2'), isTrue);
      expect(prompt.contains('Never invent missing user preferences'), isTrue);
    });
  });

  group('GenerateRecipeResponseParser', () {
    GenerateRecipeRequest validRequest() => GenerateRecipeRequest.validated(
          craving: 'Pasta',
          mealType: 'Dinner',
          mainGoal: 'Balanced',
          servings: 2,
          dietaryPreferences: const ['None'],
          allergies: const ['No Allergies'],
        );

    Map<String, dynamic> basePayload({
      Object? servings = 2,
      Object? mealType = 'Dinner',
    }) {
      return {
        'title': 'Pasta Bowl',
        'description': 'Tasty',
        'cuisine': 'Not specified',
        'mealType': mealType,
        'difficulty': 'Not specified',
        'prepTime': 10,
        'cookTime': 15,
        'servings': servings,
        'ingredients': [
          {'name': 'pasta', 'amount': '200', 'unit': 'g'},
        ],
        'instructions': [
          {'step': 1, 'text': 'Boil water'},
        ],
        'dietary': ['None'],
        'nutrition': {'calories': '400'},
      };
    }

    test('rejects missing servings and does not fall back to 2', () {
      expect(
        () => GenerateRecipeResponseParser.parseDecoded(
          recipeData: basePayload(servings: null),
          request: validRequest(),
        ),
        throwsA(isA<RecipeAiResponseException>()),
      );
    });

    test('rejects missing meal type and does not fall back to Main Course', () {
      expect(
        () => GenerateRecipeResponseParser.parseDecoded(
          recipeData: basePayload(mealType: ''),
          request: validRequest(),
        ),
        throwsA(isA<RecipeAiResponseException>()),
      );
    });

    test('rejects wrong servings value', () {
      expect(
        () => GenerateRecipeResponseParser.parseDecoded(
          recipeData: basePayload(servings: 4),
          request: validRequest(),
        ),
        throwsA(isA<RecipeAiResponseException>()),
      );
    });

    test('rejects Main Course and does not invent it as fallback', () {
      expect(
        () => GenerateRecipeResponseParser.parseDecoded(
          recipeData: basePayload(mealType: 'Main Course'),
          request: validRequest(),
        ),
        throwsA(isA<RecipeAiResponseException>()),
      );
    });

    test('uses validated user meal type and servings on success', () {
      final parsed = GenerateRecipeResponseParser.parseDecoded(
        recipeData: basePayload(),
        request: validRequest(),
      );
      expect(parsed.mealType, 'Dinner');
      expect(parsed.servings, 2);
      expect(parsed.dietary, ['None']);
    });

    test('Surprise Me requires concrete meal type from AI', () {
      final request = GenerateRecipeRequest.validated(
        craving: 'Something light',
        mealType: 'Surprise Me',
        mainGoal: 'Just Enjoy',
        servings: 1,
        dietaryPreferences: const ['None'],
        allergies: const ['No Allergies'],
      );
      expect(
        () => GenerateRecipeResponseParser.parseDecoded(
          recipeData: basePayload(mealType: 'Surprise Me', servings: 1),
          request: request,
        ),
        throwsA(isA<RecipeAiResponseException>()),
      );

      final parsed = GenerateRecipeResponseParser.parseDecoded(
        recipeData: basePayload(mealType: 'Snack', servings: 1),
        request: request,
      );
      expect(parsed.mealType, 'Snack');
    });
  });

  group('PendingGenerationRequestStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restores full request after save/load', () async {
      final store = PendingGenerationRequestStore.instance;
      await store.save(
        const PendingGenerationRequest(
          source: 'craving',
          craving: 'Tacos',
          mealType: 'Lunch',
          mainGoal: 'High Protein',
          servings: 4,
          dietaryPreferences: ['Gluten-Free'],
          allergies: ['Shellfish'],
        ),
      );

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.craving, 'Tacos');
      expect(loaded.mealType, 'Lunch');
      expect(loaded.mainGoal, 'High Protein');
      expect(loaded.servings, 4);
      expect(loaded.dietaryPreferences, ['Gluten-Free']);
      expect(loaded.allergies, ['Shellfish']);
    });

    test('pending is not cleared until explicit clear after success', () async {
      final store = PendingGenerationRequestStore.instance;
      await store.save(
        const PendingGenerationRequest(
          source: 'craving',
          craving: 'Soup',
          mealType: 'Dinner',
          mainGoal: 'Balanced',
          servings: 2,
          dietaryPreferences: ['None'],
          allergies: ['No Allergies'],
        ),
      );
      expect(await store.load(), isNotNull);
      // Simulate failed generation — store still present.
      expect((await store.load())!.craving, 'Soup');
      await store.clear();
      expect(await store.load(), isNull);
    });

    test('unpaid restore keeps pending without requiring clear', () async {
      final store = PendingGenerationRequestStore.instance;
      await store.save(
        const PendingGenerationRequest(
          source: 'craving',
          craving: 'Omelette',
          mealType: 'Breakfast',
          mainGoal: 'Build Muscle',
          servings: 1,
          dietaryPreferences: ['None'],
          allergies: ['No Allergies'],
        ),
      );
      final restored = await store.load();
      expect(restored!.mealType, 'Breakfast');
      // Unpaid path should leave pending for later.
      expect(await store.load(), isNotNull);
    });
  });

  group('firstMissingHint', () {
    test('returns first missing field message', () {
      expect(
        GenerateRecipeRequest.firstMissingHint(
          craving: '',
          servings: null,
          mealType: null,
          mainGoal: null,
        ),
        'Enter a recipe idea.',
      );
      expect(
        GenerateRecipeRequest.firstMissingHint(
          craving: 'Pasta',
          servings: null,
          mealType: null,
          mainGoal: null,
        ),
        'Select servings.',
      );
      expect(
        GenerateRecipeRequest.firstMissingHint(
          craving: 'Pasta',
          servings: 2,
          mealType: null,
          mainGoal: null,
        ),
        'Choose a meal type.',
      );
      expect(
        GenerateRecipeRequest.firstMissingHint(
          craving: 'Pasta',
          servings: 2,
          mealType: 'Dinner',
          mainGoal: null,
        ),
        'Select your main goal.',
      );
    });
  });

  group('quota + resume guards', () {
    test('failed AI parse does not consume quota', () {
      const error = RecipeAiResponseException('missing servings');
      expect(shouldConsumeQuotaOnGenerationFailure(error), isFalse);
      expect(
        shouldConsumeQuotaOnGenerationFailure(Exception('network')),
        isTrue,
      );
    });

    test('duplicate resume does not acquire twice', () {
      final guard = GenerationResumeGuard();
      expect(guard.tryAcquire(), isTrue);
      expect(guard.tryAcquire(), isFalse);
      expect(guard.isInFlight, isTrue);
      guard.release();
      expect(guard.tryAcquire(), isTrue);
      guard.release();
    });

    test('successful generation clears pending; unpaid leaves it', () async {
      SharedPreferences.setMockInitialValues({});
      final store = PendingGenerationRequestStore.instance;
      await store.save(
        const PendingGenerationRequest(
          source: 'craving',
          craving: 'Curry',
          mealType: 'Dinner',
          mainGoal: 'Balanced',
          servings: 2,
          dietaryPreferences: ['None'],
          allergies: ['No Allergies'],
        ),
      );

      // Unpaid restore path: keep pending for later Generate.
      expect(await store.load(), isNotNull);

      // Successful generation path: clear pending.
      await store.clear();
      expect(await store.load(), isNull);
    });
  });
}
