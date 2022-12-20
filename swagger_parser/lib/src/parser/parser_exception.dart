class ParserException implements Exception {
  const ParserException(this.message);

  final String message;

  @override
  String toString() => 'ParserException: $message';
}
