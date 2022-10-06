class GeneratorException implements Exception {
  GeneratorException(this.message);

  final String message;

  @override
  String toString() => 'GeneratorException: $message';
}
