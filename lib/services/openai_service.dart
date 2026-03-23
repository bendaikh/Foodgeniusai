import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_storage/firebase_storage.dart';
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

  Future<RecipeModel> generateRecipe({
    required String craving,
    String? mealType,
    String? dietary,
    int servings = 2,
    String? portionSize,
  }) async {
    if (settings.openaiApiKey == null || settings.openaiApiKey!.isEmpty) {
      throw Exception('OpenAI API key not configured. Please configure it in Admin Settings.');
    }

    final prompt = _buildRecipePrompt(
      craving: craving,
      mealType: mealType,
      dietary: dietary,
      servings: servings,
      portionSize: portionSize,
    );

    try {
      print('🔑 Making OpenAI API request...');
      print('Model: ${settings.openaiModel}');
      print('Craving: $craving');
      
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
            'content': 'You are a professional chef and recipe creator. You MUST respond with valid JSON only, no other text. Ensure all strings are properly escaped and complete.'
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
        return _parseRecipeFromAI(content, craving);
      } else {
        print('❌ OpenAI API error: ${response.statusCode}');
        print('Response: ${response.body}');
        final errorData = jsonDecode(response.body);
        throw Exception('OpenAI API error: ${errorData['error']['message']}');
      }
    } catch (e) {
      throw Exception('Failed to generate recipe: $e');
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

  String _buildRecipePrompt({
    required String craving,
    String? mealType,
    String? dietary,
    required int servings,
    String? portionSize,
  }) {
    return '''
You are a professional chef. Create a recipe for: $craving

Requirements:
${mealType != null ? '- Meal Type: $mealType' : ''}
${dietary != null ? '- Dietary: $dietary' : ''}
- Servings: $servings
${portionSize != null ? '- Portion Size: $portionSize' : ''}

IMPORTANT: Return ONLY valid JSON, no other text. Use this exact structure:

{
  "title": "Recipe Name Here",
  "description": "Brief appetizing description",
  "cuisine": "Italian",
  "mealType": "${mealType ?? 'Main Course'}",
  "difficulty": "easy",
  "prepTime": 15,
  "cookTime": 30,
  "servings": $servings,
  "ingredients": [
    {"name": "pasta", "amount": "200", "unit": "g"},
    {"name": "tomatoes", "amount": "4", "unit": "pieces"}
  ],
  "instructions": [
    {"step": 1, "text": "Boil water in a large pot"},
    {"step": 2, "text": "Cook pasta according to package"}
  ],
  "dietary": ["${dietary ?? 'None'}"],
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

  RecipeModel _parseRecipeFromAI(String content, String originalCraving) {
    try {
      print('🔍 Raw AI Response:');
      print(content);
      print('---');
      
      // Try to extract JSON from the response
      String jsonStr = content.trim();
      
      // Remove markdown code blocks if present
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
      
      // Find JSON object boundaries
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}');
      
      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd + 1);
      }
      
      // Check if JSON is complete
      if (!jsonStr.endsWith('}')) {
        print('⚠️ JSON appears truncated, attempting to fix...');
        // Try to close open strings and objects
        int openBraces = 0;
        int openBrackets = 0;
        bool inString = false;
        
        for (int i = 0; i < jsonStr.length; i++) {
          final char = jsonStr[i];
          if (char == '"' && (i == 0 || jsonStr[i - 1] != '\\')) {
            inString = !inString;
          } else if (!inString) {
            if (char == '{') openBraces++;
            if (char == '}') openBraces--;
            if (char == '[') openBrackets++;
            if (char == ']') openBrackets--;
          }
        }
        
        // Close incomplete string
        if (inString) {
          jsonStr += '"';
        }
        
        // Close incomplete arrays
        for (int i = 0; i < openBrackets; i++) {
          jsonStr += ']';
        }
        
        // Close incomplete objects
        for (int i = 0; i < openBraces; i++) {
          jsonStr += '}';
        }
        
        print('🔧 Fixed JSON');
      }
      
      print('🔍 Extracted JSON:');
      print(jsonStr);
      print('---');

      final recipeData = jsonDecode(jsonStr);

      // Parse ingredients
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
      
      // If no ingredients parsed, add a default one
      if (ingredients.isEmpty) {
        ingredients.add({
          'name': 'See full recipe for ingredients',
          'amount': '',
          'unit': '',
        });
      }

      // Parse instructions
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
      
      // If no instructions parsed, add a default one
      if (instructions.isEmpty) {
        instructions.add({
          'step': 1,
          'text': 'Please refer to the full recipe for detailed instructions.',
        });
      }

      print('✅ Recipe parsed successfully: ${recipeData['title']}');

      return RecipeModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        title: recipeData['title']?.toString() ?? originalCraving,
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
    } catch (e) {
      print('❌ Parse error: $e');
      throw Exception('Failed to parse recipe from AI response: $e');
    }
  }
}
