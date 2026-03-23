# OpenAI Integration Guide for GourmetAI

## ✅ What's Been Implemented

Your GourmetAI app now has **full OpenAI integration** for generating recipes and images using GPT-4 and DALL-E!

### Features Added:

1. **AI Settings Management**
   - Store OpenAI API keys securely in Firestore
   - Configure AI model settings (GPT-4, tokens, temperature)
   - Select image generation provider (DALL-E 3, DALL-E 2, Stable Diffusion)

2. **Recipe Generation with OpenAI**
   - Users can describe what they're craving
   - AI generates complete recipes with:
     - Title and description
     - Ingredients with quantities
     - Step-by-step instructions
     - Nutritional information
     - Cuisine type and difficulty level

3. **Image Generation with DALL-E**
   - Generate professional food photography for recipes
   - Support for DALL-E 3 (1024x1024) and DALL-E 2 (512x512)

## 🚀 How to Use

### Step 1: Configure OpenAI API Key (Admin Only)

1. **Get an OpenAI API Key:**
   - Go to https://platform.openai.com/api-keys
   - Create a new API key
   - Copy the key (starts with `sk-...`)

2. **Configure in Admin Panel:**
   - Log in to your app as admin
   - Go to **Admin Dashboard** → **API Settings**
   - Paste your OpenAI API key
   - Configure settings:
     - **Model**: `gpt-4` (recommended) or `gpt-3.5-turbo` (cheaper)
     - **Max Tokens**: `2000` (default)
     - **Temperature**: `0.7` (default)
     - **Image Provider**: Select DALL-E 3 or DALL-E 2
   - Click **Save Settings**

### Step 2: Generate Recipes (User)

1. **Navigate to Recipe Creation:**
   - Click "Create Recipe" from the home page
   
2. **Fill in Details:**
   - **What are you craving?**: e.g., "Creamy Italian Pasta"
   - **Meal Type**: Breakfast, Lunch, Dinner, etc.
   - **Dietary**: Vegetarian, Vegan, Keto, etc.
   - **Servings**: Number of people
   - **Portion Size**: Small, Medium, Large

3. **Generate Recipe:**
   - Click **"Create My Recipe"**
   - Wait ~10-20 seconds while AI generates your recipe
   - Recipe will be automatically saved to "My Creations"

## 📁 Files Created/Modified

### New Files:
- `lib/models/ai_settings_model.dart` - Model for AI settings
- `lib/services/ai_settings_service.dart` - Service to save/load AI settings from Firestore
- `lib/services/openai_service.dart` - Service to interact with OpenAI API

### Modified Files:
- `lib/admin/screens/admin_api_settings_page.dart` - Now actually saves settings to Firestore
- `lib/screens/recipe_form_page.dart` - Now generates recipes using OpenAI
- `pubspec.yaml` - Added `http` package for API calls

## 🔧 Technical Details

### OpenAI API Endpoints Used:

1. **Chat Completions** (Recipe Generation)
   - Endpoint: `https://api.openai.com/v1/chat/completions`
   - Model: GPT-4 or GPT-3.5-turbo
   - Generates structured JSON recipes

2. **Image Generation** (DALL-E)
   - Endpoint: `https://api.openai.com/v1/images/generations`
   - Model: DALL-E 3 or DALL-E 2
   - Generates food photography

### Data Flow:

```
User Input → OpenAI API → Parse JSON → Save to Firestore → Display in App
```

### Cost Estimates (OpenAI Pricing):

- **GPT-4**: ~$0.03 per recipe generation
- **GPT-3.5-turbo**: ~$0.002 per recipe generation
- **DALL-E 3**: $0.040 per image
- **DALL-E 2**: $0.020 per image

## 🛡️ Security

- API keys are stored in Firestore under `admin_settings/ai_settings`
- Only authenticated users can generate recipes
- Consider setting up Firestore security rules to restrict API key access to admins only

### Recommended Firestore Security Rule:

```javascript
match /admin_settings/{document=**} {
  allow read, write: if request.auth != null && 
                       get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
}
```

## 🐛 Troubleshooting

### "OpenAI API key not configured" Error
- Make sure you've entered your API key in Admin → API Settings
- Click "Save Settings" after entering the key
- Refresh the page

### "Failed to generate recipe" Error
- Check your OpenAI API key is valid
- Ensure you have sufficient credits in your OpenAI account
- Check the error message for details

### Recipe Format Issues
- The AI response is parsed as JSON
- If parsing fails, check the OpenAI response format
- You may need to adjust the prompt in `openai_service.dart`

## 📝 Future Enhancements

You can extend this integration with:

1. **Image Generation for Every Recipe**
   - Automatically generate images after recipe creation
   - Store image URLs in Firestore

2. **Recipe Variations**
   - Let users request variations of existing recipes
   - "Make it vegetarian", "Double the recipe", etc.

3. **Ingredient Substitutions**
   - Ask AI for ingredient alternatives
   - Dietary restrictions handling

4. **Batch Recipe Generation**
   - Generate multiple recipes at once
   - Weekly meal planning

5. **Cost Tracking**
   - Track API usage and costs
   - Set budget limits

## 📚 Documentation Links

- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)
- [GPT-4 Guide](https://platform.openai.com/docs/guides/gpt)
- [DALL-E Guide](https://platform.openai.com/docs/guides/images)
- [OpenAI Pricing](https://openai.com/pricing)

---

**Need Help?** Check the code comments in the service files for detailed explanations of how each function works.
