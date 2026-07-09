/// Normalizes recipe payloads before writing to Firestore (web-safe types).
Map<String, dynamic> sanitizeRecipeForFirestore(Map<String, dynamic> data) {
  final sanitized = Map<String, dynamic>.from(data);

  final ingredients = sanitized['ingredients'];
  if (ingredients is List) {
    sanitized['ingredients'] = ingredients.map((ing) {
      if (ing is Map) {
        return {
          'name': '${ing['name'] ?? ''}',
          'amount': '${ing['amount'] ?? ''}',
          'unit': '${ing['unit'] ?? ''}',
        };
      }
      return ing;
    }).toList();
  }

  final instructions = sanitized['instructions'];
  if (instructions is List) {
    sanitized['instructions'] = instructions.map((inst) {
      if (inst is Map) {
        final step = inst['step'];
        return {
          'step': step is num ? step.toInt() : int.tryParse('$step') ?? 0,
          'text': '${inst['text'] ?? ''}',
        };
      }
      return inst;
    }).toList();
  }

  for (final key in ['prepTime', 'cookTime', 'totalTime', 'servings', 'views', 'saves']) {
    final value = sanitized[key];
    if (value is num) {
      sanitized[key] = value.toInt();
    }
  }

  if (sanitized['dietary'] is List) {
    sanitized['dietary'] =
        (sanitized['dietary'] as List).map((item) => '$item').toList();
  }

  if (sanitized['nutrition'] is Map) {
    final nutrition = Map<String, dynamic>.from(sanitized['nutrition'] as Map);
    nutrition.updateAll((_, value) => '$value');
    sanitized['nutrition'] = nutrition;
  }

  sanitized['userId'] = '${sanitized['userId'] ?? ''}';
  sanitized['isPublic'] = sanitized['isPublic'] ?? true;

  return sanitized;
}
