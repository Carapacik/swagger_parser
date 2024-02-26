/// Exception thrown when a parser can't parse the specification
class OpenApiParserException implements Exception {
  /// Creates a [OpenApiParserException].
  const OpenApiParserException(this.message);

  /// A message describing the parser error
  final String message;

  @override
  String toString() => 'OpenApiParserException: $message';
}
