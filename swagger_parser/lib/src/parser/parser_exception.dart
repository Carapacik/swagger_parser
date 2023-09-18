/// Exception thrown when a parser can't parse the schema
class ParserException implements Exception {
  /// Constructor for [ParserException]
  const ParserException(this.message);

  /// A message describing the parser error
  final String message;

  @override
  String toString() => 'ParserException: $message';
}
