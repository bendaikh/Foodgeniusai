import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
import '../models/generate_recipe_options.dart';
import '../models/recipe_model.dart';
import '../models/ai_settings_model.dart';

class OpenAIService {
  final AISettingsModel settings;

  OpenAIService(this.settings);

  Future<String> testConnection() async {
    if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      print('🔑 Testing OpenAI API connection...');
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.openaiApiKey}',
        },
        body: jsonEncode({
          'model': settings.openaiModel ?? 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': 'Say "API connection successful" in exactly 3 words.',
            }
          ],
          'max_tokens': 20,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('✅ API test successful: $content');
        return content;
      } else {
        print('❌ API error: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error']['message']);
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
      rethrow;
    }
  }

  Future<List<RecipeModel>> generateRecipesFromIngredients({
    required List<String> ingredients,
    int numberOfRecipes = 1,
    String? recipeType,
    String? recipeTypeConstraint,
    String? cuisine,
    String? cuisineConstraint,
    String? cookingTime,
    String? cookingTimeConstraint,
    String? difficulty,
    String? difficultyConstraint,
    String? difficultyJsonValue,
    String? dietary,
    String? language,
    String? countryCode,
    String? measurementSystem,
    List<String>? originalDetectedIngredients,
  }) async {
    if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
      throw Exception('OpenAI API key not configured. Please configure it in Admin Settings.');
    }

    final prompt = _buildIngredientsPrompt(
      ingredients: ingredients,
      numberOfRecipes: numberOfRecipes,
      recipeType: recipeType,
      recipeTypeConstraint: recipeTypeConstraint,
      cuisine: cuisine,
      cuisineConstraint: cuisineConstraint,
      cookingTime: cookingTime,
      cookingTimeConstraint: cookingTimeConstraint,
      difficulty: difficulty,
      difficultyConstraint: difficultyConstraint,
      difficultyJsonValue: difficultyJsonValue,
      dietary: dietary,
      language: language,
      countryCode: countryCode,
      measurementSystem: measurementSystem,
      originalDetectedIngredients: originalDetectedIngredients,
    );

    try {
      print('🔑 Making OpenAI API request for recipes from ingredients...');
      print('Ingredients: ${ingredients.join(", ")}');
      print(
        '[ScanFridge] AI request recipeType=${recipeType ?? 'none'} '
        'cuisine=${cuisine ?? 'Any Cuisine'} '
        'cookingTime=${cookingTime ?? 'Any Time'} '
        'difficulty=${difficulty ?? 'Any Level'} '
        'dietary=${dietary ?? 'None'} language=${language ?? 'default'} '
        'country=${countryCode ?? 'unknown'} '
        'measurement=${measurementSystem ?? 'default'}',
      );
      
      final model = settings.openaiModel ?? 'gpt-4o-mini';
      final supportsJsonMode = model.contains('gpt-4-turbo') || 
                                model.contains('gpt-4o') ||
                                model.contains('gpt-3.5-turbo-1106') ||
                                model.contains('gpt-3.5-turbo-0125');
      
      final requestBody = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional chef and recipe creator. You MUST respond with valid JSON only, no other text. Ensure all strings are properly escaped and complete. Never silently change the user\'s selected recipe type, cuisine, cooking time, difficulty, or dietary preferences. When a required recipe type is specified, generate only that type.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': (settings.maxTokens ?? 2000) * 2,
        'temperature': settings.temperature ?? 0.7,
      };
      
      if (supportsJsonMode) {
        requestBody['response_format'] = {'type': 'json_object'};
        print('✅ Using JSON mode');
      } else {
        print('⚠️ JSON mode not supported by $model, using regular mode');
        requestBody['max_tokens'] = ((settings.maxTokens ?? 2000) * 2) + 1000;
      }
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.openaiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('📥 Received response from OpenAI');
        return _parseMultipleRecipesFromAI(content, ingredients);
      } else {
        print('❌ OpenAI API error: ${response.statusCode}');
        print('Response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${errorData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to generate recipes: $e');
    }
  }

  Future<RecipeModel> generateRecipe({
    required String craving,
    required String mealType,
    required String mainGoal,
    required List<String> dietaryPreferences,
    required List<String> allergies,
    required int servings,
  }) async {
    if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
      throw Exception('OpenAI API key not configured. Please configure it in Admin Settings.');
    }

    final GenerateRecipeRequest request;
    try {
      request = GenerateRecipeRequest.validated(
        craving: craving,
        mealType: mealType,
        mainGoal: mainGoal,
        servings: servings,
        dietaryPreferences: dietaryPreferences,
        allergies: allergies,
      );
    } on ArgumentError catch (e) {
      throw Exception(e.message);
    }

    final prompt = GenerateRecipePromptBuilder.build(request);

    try {
      print('🔑 Making OpenAI API request...');
      print('Model: ${settings.openaiModel}');
      print(
        '[GenerateRecipe] craving="${request.craving}" mealType=${request.mealType} '
        'mainGoal=${request.mainGoal} servings=${request.servings} '
        'dietary=${request.dietaryPreferences.join(', ')} '
        'allergies=${request.allergies.join(', ')}',
      );
      
      // Check if model supports JSON mode
      final model = settings.openaiModel ?? 'gpt-4o-mini';
      final supportsJsonMode = model.contains('gpt-4-turbo') || 
                                model.contains('gpt-4o') ||
                                model.contains('gpt-3.5-turbo-1106') ||
                                model.contains('gpt-3.5-turbo-0125');
      
      final requestBody = {
        'model': model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a professional chef and recipe creator. You MUST respond with valid JSON only, no other text. Ensure all strings are properly escaped and complete. Never invent servings, meal type, main goal, dietary preferences, or allergies — use only the values provided by the user.'
          },
          {
            'role': 'user',
            'content': prompt,
          }
        ],
        'max_tokens': settings.maxTokens ?? 2000,
        'temperature': settings.temperature ?? 0.7,
      };
      
      // Only add response_format for models that support it
      if (supportsJsonMode) {
        requestBody['response_format'] = {'type': 'json_object'};
        print('✅ Using JSON mode');
      } else {
        print('⚠️ JSON mode not supported by $model, using regular mode');
        // For models without JSON mode, increase tokens to avoid truncation
        requestBody['max_tokens'] = (settings.maxTokens ?? 2000) + 500;
      }
      
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.openaiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        print('📥 Received response from OpenAI');
        return _parseStandardRecipeFromAI(content, request);
      } else {
        print('❌ OpenAI API error: ${response.statusCode}');
        print('Response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${errorData['error']['message']}');
      }
    } on RecipeAiResponseException {
      rethrow;
    } catch (e) {
      if (e is RecipeAiResponseException) rethrow;
      throw Exception('Failed to generate recipe: $e');
    }
  }

  RecipeModel _parseStandardRecipeFromAI(
    String content,
    GenerateRecipeRequest request,
  ) {
    try {
      print('🔍 Raw AI Response:');
      print(content);
      print('---');

      var jsonStr = content.trim();
      if (content.contains('```json')) {
        final start = content.indexOf('```json') + 7;
        final end = content.indexOf('```', start);
        if (end > start) {
          jsonStr = content.substring(start, end).trim();
        }
      } else if (content.contains('```')) {
        final start = content.indexOf('```') + 3;
        final end = content.indexOf('```', start);
        if (end > start) {
          jsonStr = content.substring(start, end).trim();
        }
      }

      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1 || jsonEnd <= jsonStart) {
        throw const RecipeAiResponseException(
          'The AI returned an incomplete recipe. Please try again.',
        );
      }
      jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);

      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        throw const RecipeAiResponseException(
          'The AI returned an invalid recipe format. Please try again.',
        );
      }

      final parsed = GenerateRecipeResponseParser.parseDecoded(
        recipeData: Map<String, dynamic>.from(decoded),
        request: request,
      );

      print('✅ Recipe parsed successfully: ${parsed.title}');

      return RecipeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: parsed.title,
        description: parsed.description,
        cuisine: parsed.cuisine,
        mealType: parsed.mealType,
        difficulty: parsed.difficulty,
        prepTime: parsed.prepTime,
        cookTime: parsed.cookTime,
        totalTime: parsed.prepTime + parsed.cookTime,
        servings: parsed.servings,
        ingredients: parsed.ingredients,
        instructions: parsed.instructions,
        dietary: parsed.dietary,
        nutrition: parsed.nutrition,
        imageUrl: null,
        createdAt: DateTime.now(),
      );
    } on RecipeAiResponseException {
      rethrow;
    } catch (e) {
      print('❌ Parse error: $e');
      throw RecipeAiResponseException(
        'Failed to parse recipe from AI response. Please try again.',
      );
    }
  }

  /// Detect visible food ingredients from a fridge/pantry photo.
  /// Additive helper only — does not alter recipe generation prompts or flows.
  Future<List<String>> detectIngredientsFromImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
      throw Exception(
        'OpenAI API key not configured. Please ask admin to configure it in Admin Settings.',
      );
    }

    final base64Image = base64Encode(imageBytes);
    // Use a dedicated vision-capable model for fridge scanning only.
    // This does not affect recipe text generation or image generation models.
    const scanVisionModel = 'gpt-4o-mini';
    final normalizedMimeType =
        mimeType.startsWith('image/') ? mimeType : 'image/jpeg';
    final imageDataUrl = 'data:$normalizedMimeType;base64,$base64Image';

    final requestBody = <String, dynamic>{
      'model': scanVisionModel,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are a food ingredient recognition assistant. Identify edible ingredients visible in photos of fridges, pantries, or kitchens. Respond with valid JSON only.',
        },
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  'Identify all clearly visible edible ingredients in this image. Return JSON only in this exact shape: {"ingredients":["Eggs","Milk"]}. Use short common ingredient names. Do not invent items you cannot see. If none are visible, return {"ingredients":[]}.',
            },
            {
              'type': 'image_url',
              'image_url': {
                'url': imageDataUrl,
              },
            },
          ],
        },
      ],
      'max_tokens': 800,
      'temperature': 0.2,
      'response_format': {'type': 'json_object'},
    };

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.openaiApiKey}',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'OpenAI API error: ${errorData['error']['message']}',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'] as String;
      return _parseDetectedIngredients(content);
    } catch (e) {
      throw Exception('Failed to detect ingredients: $e');
    }
  }

  List<String> _parseDetectedIngredients(String content) {
    try {
      String cleaned = content.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
            .replaceFirst(RegExp(r'\s*```$'), '');
      }

      final decoded = jsonDecode(cleaned);
      final raw = decoded is Map ? decoded['ingredients'] : decoded;
      if (raw is! List) return [];

      final seen = <String>{};
      final ingredients = <String>[];
      for (final item in raw) {
        final name = item.toString().trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (seen.contains(key)) continue;
        seen.add(key);
        ingredients.add(name);
      }
      return ingredients;
    } catch (e) {
      throw Exception('Failed to parse detected ingredients: $e');
    }
  }

  Future<String> generateRecipeImage(String recipeTitle, String description, {String? userId}) async {
    if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    // Ultra-realistic prompt for food photography
    final prompt = '''
Ultra-realistic professional food photography of $recipeTitle.
$description

IMPORTANT: The image must look extremely realistic, like a real photograph taken with a high-end DSLR camera.
- Shot in a professional kitchen or restaurant setting
- Perfect natural lighting with soft shadows
- Sharp focus on the food with shallow depth of field
- Hyper-realistic textures and details (you can see individual grains, moisture, steam)
- Authentic colors that look exactly like real food
- Professional food styling and plating
- 8K resolution quality
- Photorealistic, not artistic or illustrated
- Restaurant-quality presentation
- Natural, appetizing appearance
- Realistic steam, garnishes, and food textures
- Magazine-quality food photography
- The image should be indistinguishable from a real photograph
'''.trim();

    print('🖼️ Generating ultra-realistic image with gpt-image-1...');

    try {
      // Request image URL (gpt-image-1 doesn't support response_format)
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${settings.openaiApiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-image-1',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
          'quality': 'high',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📦 API Response: ${response.body}');
        
        // Try to get the image URL or base64 data
        String? imageUrl;
        String? base64Image;
        
        if (data['data'] != null && data['data'].isNotEmpty) {
          final imageData = data['data'][0];
          imageUrl = imageData['url'];
          base64Image = imageData['b64_json'];
        }
        
        if (imageUrl != null && imageUrl.isNotEmpty) {
          print('✅ Image URL received: $imageUrl');

          // Download and upload to Firebase Storage
          if (userId != null) {
            print('📥 Downloading image from gpt-image-1...');
            final imageResponse = await http.get(Uri.parse(imageUrl));
            
            if (imageResponse.statusCode == 200) {
              final imageBytes = imageResponse.bodyBytes;
              print('✅ Image downloaded: ${imageBytes.length} bytes');
              
              print('📤 Uploading to Firebase Storage...');
              final permanentUrl = await _uploadBytesToFirebase(imageBytes, userId);
              print('✅ Image saved permanently: $permanentUrl');
              return permanentUrl;
            } else {
              throw Exception('Failed to download image from URL');
            }
          }

          // If no userId, return the temporary URL
          return imageUrl;
        } else if (base64Image != null && base64Image.isNotEmpty) {
          print('✅ Image received as base64');
          
          // Upload base64 image to Firebase Storage
          if (userId != null) {
            final imageBytes = base64Decode(base64Image);
            print('📤 Uploading to Firebase Storage...');
            final permanentUrl = await _uploadBytesToFirebase(imageBytes, userId);
            print('✅ Image saved permanently: $permanentUrl');
            return permanentUrl;
          }
          
          return 'data:image/png;base64,$base64Image';
        } else {
          throw Exception('No image data received from API');
        }
      } else {
        print('❌ Image generation error: ${response.statusCode}');
        print('Response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception('Image generation error: ${errorData['error']['message']}');
      }
    } catch (e) {
      print('❌ Failed to generate image: $e');
      throw Exception('Failed to generate image: $e');
    }
  }

  Future<String> _uploadBytesToFirebase(Uint8List imageBytes, String userId) async {
    try {
      // Upload to Firebase Storage
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'recipe_$timestamp.png';
      final path = 'recipes/$userId/$filename';
      
      final storageRef = FirebaseStorage.instance.ref().child(path);
      
      final uploadTask = await storageRef.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/png',
          customMetadata: {
            'uploaded': DateTime.now().toIso8601String(),
            'source': 'gpt-image-1',
          },
        ),
      );
      
      final permanentUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Uploaded to Firebase: $permanentUrl');
      
      return permanentUrl;
    } catch (e) {
      print('❌ Error uploading to Firebase: $e');
      rethrow;
    }
  }

  String _buildIngredientsPrompt({
    required List<String> ingredients,
    required int numberOfRecipes,
    String? recipeType,
    String? recipeTypeConstraint,
    String? cuisine,
    String? cuisineConstraint,
    String? cookingTime,
    String? cookingTimeConstraint,
    String? difficulty,
    String? difficultyConstraint,
    String? difficultyJsonValue,
    String? dietary,
    String? language,
    String? countryCode,
    String? measurementSystem,
    List<String>? originalDetectedIngredients,
  }) {
    final editedList = ingredients.join(', ');
    final detectedList = (originalDetectedIngredients == null ||
            originalDetectedIngredients.isEmpty)
        ? editedList
        : originalDetectedIngredients.join(', ');
    final mealTypeForJson = (recipeType != null &&
            recipeType.isNotEmpty &&
            recipeType.toLowerCase() != 'surprise me' &&
            recipeType.toLowerCase() != 'surprise')
        ? recipeType
        : 'Main Course';
    final cuisineForJson =
        (cuisine != null && cuisine.isNotEmpty) ? cuisine : 'International';
    final difficultyForJson =
        (difficultyJsonValue != null && difficultyJsonValue.isNotEmpty)
            ? difficultyJsonValue
            : 'easy';
    final dietaryValue =
        (dietary != null && dietary.isNotEmpty) ? dietary : 'None';

    final preferenceLines = <String>[
      if (dietaryValue != 'None')
        '- Dietary restrictions: $dietaryValue (MANDATORY — must fully respect)',
      if (language != null && language.isNotEmpty)
        '- Write the recipe in this language: $language',
      if (countryCode != null && countryCode.isNotEmpty)
        '- User country/region: $countryCode',
      if (measurementSystem != null && measurementSystem.isNotEmpty)
        '- Use $measurementSystem units for amounts and temperatures',
    ];

    final typeBlock = (recipeTypeConstraint != null &&
            recipeTypeConstraint.trim().isNotEmpty)
        ? '''

=== RECIPE TYPE (MANDATORY unless Surprise Me) ===
Selected type: ${recipeType ?? 'Surprise Me'}
$recipeTypeConstraint
- Do not silently change this preference.
- The "mealType" field in the JSON MUST match the recipe type you generate.
- Do not return a drink when Main Dish, Salad, Soup, Dessert, Snack, or Breakfast is selected.
- Do not return solid food when Smoothie / Juice is selected.
=== END RECIPE TYPE ===
'''
        : '''

- Make recipes diverse (different cuisines, cooking methods, meal types)
''';

    final cuisineBlock = (cuisineConstraint != null &&
            cuisineConstraint.trim().isNotEmpty)
        ? '''

=== CUISINE PREFERENCE ===
Selected cuisine: ${cuisine ?? 'Any Cuisine'}
$cuisineConstraint
- Do not silently change this preference.
- The "cuisine" field in the JSON should reflect the cuisine you actually used.
=== END CUISINE ===
'''
        : '';

    final timeBlock = (cookingTimeConstraint != null &&
            cookingTimeConstraint.trim().isNotEmpty)
        ? '''

=== COOKING TIME PREFERENCE ===
Selected time: ${cookingTime ?? 'Any Time'}
$cookingTimeConstraint
- Do not silently change this preference.
- prepTime + cookTime in the JSON MUST respect the selected range.
=== END COOKING TIME ===
'''
        : '';

    final difficultyBlock = (difficultyConstraint != null &&
            difficultyConstraint.trim().isNotEmpty)
        ? '''

=== DIFFICULTY PREFERENCE ===
Selected difficulty: ${difficulty ?? 'Any Level'}
$difficultyConstraint
- Do not silently change this preference.
=== END DIFFICULTY ===
'''
        : '';

    return '''
You are a professional chef. Create $numberOfRecipes recipe(s) using these ingredients.

Originally detected ingredients: $detectedList
Final ingredients after user review/editing: $editedList

HARD RULES:
1. Selected recipe type is mandatory unless "Surprise Me" / Surprise is selected.
2. Selected cuisine must be respected unless "Any Cuisine" is selected.
3. Total time (prepTime + cookTime) must respect the chosen time range unless "Any Time" is selected.
4. Difficulty must match the selected level unless "Any Level" is selected.
5. Dietary restrictions are mandatory when provided.
6. Prioritize the detected / edited ingredients.
7. Clearly list any essential missing ingredients in a top-level "missingIngredients" string array.
8. Do not silently change the user's selected preferences.
9. Return structured JSON compatible with the schema below.
10. Keep measurements and localization consistent with the user preferences below.

Requirements:
- Each recipe should primarily use the final edited ingredients list
- Common pantry staples (salt, pepper, oil, basic spices) are okay
- Each recipe should be complete and realistic
- Do not invent many unavailable essential ingredients just to force a cuisine style
${preferenceLines.isEmpty ? '' : '${preferenceLines.join('\n')}\n'}
$typeBlock$cuisineBlock$timeBlock$difficultyBlock
IMPORTANT: Return ONLY valid JSON, no other text. Use this exact structure:

{
  "recipes": [
    {
      "title": "Recipe Name Here",
      "description": "Brief appetizing description",
      "cuisine": "$cuisineForJson",
      "mealType": "$mealTypeForJson",
      "difficulty": "$difficultyForJson",
      "prepTime": 15,
      "cookTime": 30,
      "servings": 2,
      "ingredients": [
        {"name": "pasta", "amount": "200", "unit": "g"},
        {"name": "tomatoes", "amount": "4", "unit": "pieces"}
      ],
      "instructions": [
        {"step": 1, "text": "Boil water in a large pot"},
        {"step": 2, "text": "Cook pasta according to package"}
      ],
      "dietary": ["$dietaryValue"],
      "nutrition": {
        "calories": "350",
        "protein": "25g",
        "carbs": "40g",
        "fat": "10g"
      }
    }
  ],
  "missingIngredients": ["optional specialty item if truly essential"]
}

Return ONLY the JSON object, nothing else.
''';
  }

  List<RecipeModel> _parseMultipleRecipesFromAI(String content, List<String> originalIngredients) {
    try {
      print('🔍 Raw AI Response:');
      print(content);
      print('---');
      
      String jsonStr = content.trim();
      
      if (content.contains('```json')) {
        final start = content.indexOf('```json') + 7;
        final end = content.indexOf('```', start);
        if (end > start) {
          jsonStr = content.substring(start, end).trim();
        }
      } else if (content.contains('```')) {
        final start = content.indexOf('```') + 3;
        final end = content.indexOf('```', start);
        if (end > start) {
          jsonStr = content.substring(start, end).trim();
        }
      }
      
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }
      
      print('🔍 Extracted JSON:');
      print(jsonStr);
      print('---');

      final responseData = jsonDecode(jsonStr);
      final List<RecipeModel> recipes = [];

      if (responseData['recipes'] != null) {
        for (var recipeData in responseData['recipes']) {
          final recipe = _parseRecipeData(recipeData, originalIngredients.join(', '));
          recipes.add(recipe);
        }
      }

      print('✅ Parsed ${recipes.length} recipes successfully');
      return recipes;
    } catch (e) {
      print('❌ Parse error: $e');
      throw Exception('Failed to parse recipes from AI response: $e');
    }
  }

  RecipeModel _parseRecipeData(Map<String, dynamic> recipeData, String fallbackTitle) {
    List<Map<String, dynamic>> ingredients = [];
    if (recipeData['ingredients'] != null) {
      for (var ing in recipeData['ingredients']) {
        if (ing is Map) {
          ingredients.add({
            'name': ing['name']?.toString() ?? '',
            'amount': ing['amount']?.toString() ?? '',
            'unit': ing['unit']?.toString() ?? '',
          });
        } else if (ing is String) {
          ingredients.add({
            'name': ing,
            'amount': '',
            'unit': '',
          });
        }
      }
    }
    
    if (ingredients.isEmpty) {
      ingredients.add({
        'name': 'See full recipe for ingredients',
        'amount': '',
        'unit': '',
      });
    }

    List<Map<String, dynamic>> instructions = [];
    if (recipeData['instructions'] != null) {
      int step = 1;
      for (var inst in recipeData['instructions']) {
        if (inst is Map) {
          instructions.add({
            'step': inst['step'] ?? step,
            'text': inst['text']?.toString() ?? '',
          });
        } else if (inst is String) {
          instructions.add({
            'step': step,
            'text': inst,
          });
        }
        step++;
      }
    }
    
    if (instructions.isEmpty) {
      instructions.add({
        'step': 1,
        'text': 'Please refer to the full recipe for detailed instructions.',
      });
    }

    return RecipeModel(
      id: DateTime.now().millisecondsSinceEpoch.toString() + '_${ingredients.length}',
      userId: '',
      title: recipeData['title']?.toString() ?? fallbackTitle,
      description: recipeData['description']?.toString() ?? 'A delicious recipe',
      cuisine: recipeData['cuisine']?.toString() ?? 'International',
      mealType: recipeData['mealType']?.toString() ?? 'Main Course',
      difficulty: recipeData['difficulty']?.toString() ?? 'intermediate',
      prepTime: int.tryParse(recipeData['prepTime']?.toString() ?? '15') ?? 15,
      cookTime: int.tryParse(recipeData['cookTime']?.toString() ?? '30') ?? 30,
      totalTime: (int.tryParse(recipeData['prepTime']?.toString() ?? '15') ?? 15) + 
                 (int.tryParse(recipeData['cookTime']?.toString() ?? '30') ?? 30),
      servings: int.tryParse(recipeData['servings']?.toString() ?? '2') ?? 2,
      ingredients: ingredients,
      instructions: instructions,
      dietary: recipeData['dietary'] != null 
          ? List<String>.from(recipeData['dietary'])
          : [],
      nutrition: recipeData['nutrition'] != null
          ? Map<String, dynamic>.from(recipeData['nutrition'])
          : {},
      imageUrl: null,
      createdAt: DateTime.now(),
    );
  }
}
