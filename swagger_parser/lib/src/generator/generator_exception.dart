/// Exception thrown when a generator is not correct
class GeneratorException implements Exception {
  /// Constructor for [GeneratorException]
  GeneratorException(this.message);

  /// A message describing the generator error
  final String message;

  @override
  String toString() => 'GeneratorException: $message';
}
