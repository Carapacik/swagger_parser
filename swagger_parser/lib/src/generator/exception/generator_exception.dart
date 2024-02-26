/// Exception thrown when in generator is not correct
class GeneratorException implements Exception {
  /// Creates a  [GeneratorException].
  GeneratorException(this.message);

  /// A message describing the generator error
  final String message;

  @override
  String toString() => 'GeneratorException: $message';
}
