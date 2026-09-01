import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/generator/config_value_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseConfigList', () {
    test('accepts comma-separated and line-separated values', () {
      expect(parseConfigList('public, users\n/health'), [
        'public',
        'users',
        '/health',
      ]);
    });

    test('removes empty values', () {
      expect(parseConfigList(' , \n '), isEmpty);
    });
  });

  group('parseReplacementRules', () {
    test('creates ordered replacement rules', () {
      final List<ReplacementRule> rules = parseReplacementRules(
        '^Old => New\nModel\$ => Entity',
      );

      expect(rules, hasLength(2));
      expect(rules.first.apply('OldModel'), 'NewModel');
      expect(rules.last.apply('UserModel'), 'UserEntity');
    });

    test('rejects an invalid rule', () {
      expect(
        () => parseReplacementRules('missing separator'),
        throwsFormatException,
      );
    });
  });

  group('parseFieldParsers', () {
    test('creates field parser entries', () {
      final List<FieldParser> parsers = parseFieldParsers(
        'DateTime | parseDate | package:app/date_parser.dart',
      );

      expect(parsers, hasLength(1));
      expect(parsers.single.applyToType, 'DateTime');
      expect(parsers.single.parserName, 'parseDate');
      expect(parsers.single.parserAbsolutePath, 'package:app/date_parser.dart');
    });

    test('rejects incomplete entries', () {
      expect(
        () => parseFieldParsers('DateTime | parseDate'),
        throwsFormatException,
      );
    });
  });
}
