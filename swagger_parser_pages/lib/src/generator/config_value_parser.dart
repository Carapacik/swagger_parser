import 'package:swagger_parser/swagger_parser.dart';

List<String> parseConfigList(String source) => source
    .split(RegExp(r'[,\n]'))
    .map((value) => value.trim())
    .where((value) => value.isNotEmpty)
    .toList(growable: false);

List<ReplacementRule> parseReplacementRules(String source) => source
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .map((line) {
      final int separator = line.indexOf('=>');
      if (separator < 0) {
        throw FormatException(
          'Invalid replacement rule "$line". Use: pattern => replacement',
        );
      }
      return ReplacementRule(
        pattern: RegExp(line.substring(0, separator).trim()),
        replacement: line.substring(separator + 2).trim(),
      );
    })
    .toList(growable: false);

List<FieldParser> parseFieldParsers(String source) => source
    .split('\n')
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .map((line) {
      final List<String> parts = line
          .split('|')
          .map((value) => value.trim())
          .toList(growable: false);
      if (parts.length != 3 || parts.any((part) => part.isEmpty)) {
        throw FormatException(
          'Invalid field parser "$line". Use: Type | parserName | path',
        );
      }
      return FieldParser(
        applyToType: parts[0],
        parserName: parts[1],
        parserAbsolutePath: parts[2],
      );
    })
    .toList(growable: false);

extension NullableList<T> on List<T> {
  List<T>? get nullIfEmpty => isEmpty ? null : this;
}
