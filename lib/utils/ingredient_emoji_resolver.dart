/// Maps normalized ingredient names to food emojis for Detected Ingredients cards.
class IngredientEmojiResolver {
  static const String fallbackEmoji = '🥣';

  static const Map<String, String> _canonical = {
    // Vegetables
    'tomato': '🍅',
    'cucumber': '🥒',
    'lettuce': '🥬',
    'onion': '🧅',
    'garlic': '🧄',
    'carrot': '🥕',
    'potato': '🥔',
    'bell_pepper': '🫑',
    'broccoli': '🥦',
    'spinach': '🥬',
    'zucchini': '🥒',
    'mushroom': '🍄',
    // Fruits
    'apple': '🍎',
    'banana': '🍌',
    'orange': '🍊',
    'lemon': '🍋',
    'avocado': '🥑',
    'strawberry': '🍓',
    // Herbs / spices
    'parsley': '🌿',
    'cilantro': '🌿',
    'basil': '🌿',
    'mint': '🌿',
    'cinnamon': '🧂',
    'paprika': '🌶️',
    'cumin': '🧂',
    'black_pepper': '🧂',
    'salt': '🧂',
    // Dairy
    'milk': '🥛',
    'cheese': '🧀',
    'butter': '🧈',
    'yogurt': '🥛',
    'cream': '🥛',
    'egg': '🥚',
    // Protein
    'chicken': '🍗',
    'beef': '🥩',
    'lamb': '🥩',
    'salmon': '🐟',
    'tuna': '🐟',
    'fish': '🐟',
    'shrimp': '🍤',
    // Grains / legumes
    'rice': '🍚',
    'pasta': '🍝',
    'flour': '🌾',
    'bread': '🍞',
    'chickpeas': '🫘',
    'lentils': '🫘',
    'beans': '🫘',
    // Other
    'olive_oil': '🫒',
    'honey': '🍯',
    'sugar': '🍬',
    'almond': '🥜',
    'soy_sauce': '🥣',
    'tomato_sauce': '🍅',
  };

  static const Map<String, String> _aliases = {
    'tomatoes': 'tomato',
    'cherry tomato': 'tomato',
    'cherry tomatoes': 'tomato',
    'red tomato': 'tomato',
    'roma tomato': 'tomato',
    'cucumbers': 'cucumber',
    'onions': 'onion',
    'red onion': 'onion',
    'yellow onion': 'onion',
    'carrots': 'carrot',
    'potatoes': 'potato',
    'bell pepper': 'bell_pepper',
    'bell peppers': 'bell_pepper',
    'red pepper': 'bell_pepper',
    'green pepper': 'bell_pepper',
    'peppers': 'bell_pepper',
    'mushrooms': 'mushroom',
    'apples': 'apple',
    'bananas': 'banana',
    'oranges': 'orange',
    'lemons': 'lemon',
    'avocados': 'avocado',
    'strawberries': 'strawberry',
    'eggs': 'egg',
    'chicken breast': 'chicken',
    'chicken thigh': 'chicken',
    'ground beef': 'beef',
    'beef steak': 'beef',
    'steak': 'beef',
    'prawn': 'shrimp',
    'prawns': 'shrimp',
    'shrimps': 'shrimp',
    'fish fillet': 'fish',
    'white fish': 'fish',
    'chickpea': 'chickpeas',
    'lentil': 'lentils',
    'bean': 'beans',
    'black beans': 'beans',
    'kidney beans': 'beans',
    'olive oil': 'olive_oil',
    'extra virgin olive oil': 'olive_oil',
    'black pepper': 'black_pepper',
    'sea salt': 'salt',
    'table salt': 'salt',
    'coriander': 'cilantro',
    'fresh parsley': 'parsley',
    'fresh basil': 'basil',
    'fresh mint': 'mint',
    'garlic clove': 'garlic',
    'baby spinach': 'spinach',
    'courgette': 'zucchini',
    'courgettes': 'zucchini',
    'yoghurt': 'yogurt',
    'heavy cream': 'cream',
    'sour cream': 'cream',
    'cheddar': 'cheese',
    'mozzarella': 'cheese',
    'parmesan': 'cheese',
    'soy sauce': 'soy_sauce',
    'tomato sauce': 'tomato_sauce',
    'almonds': 'almond',
    'spaghetti': 'pasta',
    'noodles': 'pasta',
  };

  static String resolve(String ingredientName) {
    final normalized = _normalize(ingredientName);
    if (normalized.isEmpty) return fallbackEmoji;

    final key = _matchKey(normalized);
    if (key == null) return fallbackEmoji;
    return _canonical[key] ?? fallbackEmoji;
  }

  static String? _matchKey(String normalized) {
    if (_canonical.containsKey(normalized)) return normalized;
    if (_aliases.containsKey(normalized)) return _aliases[normalized];

    final aliasKeys = _aliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final alias in aliasKeys) {
      if (normalized.contains(alias)) return _aliases[alias];
    }

    final canonicalKeys = _canonical.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final key in canonicalKeys) {
      final spaced = key.replaceAll('_', ' ');
      if (normalized.contains(key) ||
          normalized.contains(spaced) ||
          spaced.contains(normalized)) {
        return key;
      }
    }

    return null;
  }

  static String _normalize(String value) {
    var normalized = value.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (normalized.endsWith('ies') && normalized.length > 4) {
      normalized = '${normalized.substring(0, normalized.length - 3)}y';
    } else if (normalized.endsWith('oes') && normalized.length > 4) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('ses') && normalized.length > 4) {
      normalized = normalized.substring(0, normalized.length - 2);
    } else if (normalized.endsWith('s') &&
        !normalized.endsWith('ss') &&
        normalized.length > 3) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized.trim();
  }
}
