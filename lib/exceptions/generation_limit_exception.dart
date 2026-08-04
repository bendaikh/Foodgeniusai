class GenerationLimitException implements Exception {
  final String message;

  const GenerationLimitException(this.message);

  @override
  String toString() => message;
}

class FridgeScanLimitException implements Exception {
  final String message;

  const FridgeScanLimitException(this.message);

  @override
  String toString() => message;
}
