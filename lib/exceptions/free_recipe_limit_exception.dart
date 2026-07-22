class FreeRecipeLimitException implements Exception {
  final String message;

  const FreeRecipeLimitException([
    this.message =
        'You\'ve used your free recipe. Subscribe to generate more AI recipes.',
  ]);

  @override
  String toString() => message;
}
