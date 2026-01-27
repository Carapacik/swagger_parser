/// {@template field_parser}
/// Configuration for a field parser
/// {@endtemplate}
class FieldParser {
  /// {@macro field_parser}
  const FieldParser({
    required this.applyToType,
    required this.parserName,
    required this.parserAbsolutePath,
  });

  /// The type of the field to apply the parser to
  final String applyToType;

  /// The name of the parser
  final String parserName;

  /// The absolute path to the parser
  final String parserAbsolutePath;

  @override
  String toString() {
    return 'FieldParser(applyToType: $applyToType, parserName: $parserName, parserAbsolutePath: $parserAbsolutePath)';
  }
}
