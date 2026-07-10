class GenerationLimitException implements Exception {
  final String message;

  const GenerationLimitException(this.message);

  @override
  String toString() => message;
}
