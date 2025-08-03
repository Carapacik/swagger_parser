import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  group('parseConfigGeneratorArguments', () {
    group('CLI arguments parsing', () {
      test('should parse file argument with full name', () {
        final result = parseConfigGeneratorArguments(['--file', 'config.yaml']);
        expect(result['file'], equals('config.yaml'));
      });

      test('should parse file argument with abbreviation', () {
        final result = parseConfigGeneratorArguments(['-f', 'config.yaml']);
        expect(result['file'], equals('config.yaml'));
      });

      test('should parse schema_path argument', () {
        final result =
            parseConfigGeneratorArguments(['--schema_path', 'openapi.yaml']);
        expect(result['schema_path'], equals('openapi.yaml'));
      });

      test('should parse schema_url argument', () {
        final result = parseConfigGeneratorArguments(
            ['--schema_url', 'https://api.example.com/openapi.json']);
        expect(result['schema_url'],
            equals('https://api.example.com/openapi.json'));
      });

      test('should parse name argument', () {
        final result = parseConfigGeneratorArguments(['--name', 'api']);
        expect(result['name'], equals('api'));
      });

      test('should parse output_directory argument', () {
        final result =
            parseConfigGeneratorArguments(['--output_directory', 'lib/api']);
        expect(result['output_directory'], equals('lib/api'));
      });

      test('should parse json_serializer argument', () {
        final result = parseConfigGeneratorArguments(
            ['--json_serializer', 'json_annotation']);
        expect(result['json_serializer'], equals('json_annotation'));
      });
    });

    group('Multiple arguments', () {
      test('should parse multiple arguments correctly', () {
        final result = parseConfigGeneratorArguments([
          '--file',
          'config.yaml',
          '--schema_path',
          'openapi.yaml',
          '--output_directory',
          'lib/api',
          '--json_serializer',
          'freezed'
        ]);

        expect(result['file'], equals('config.yaml'));
        expect(result['schema_path'], equals('openapi.yaml'));
        expect(result['output_directory'], equals('lib/api'));
        expect(result['json_serializer'], equals('freezed'));
      });

      test('should parse mixed full names and abbreviations', () {
        final result = parseConfigGeneratorArguments([
          '-f',
          'config.yaml',
          '--schema_url',
          'https://api.example.com/openapi.json',
          '--output_directory',
          'lib/generated'
        ]);

        expect(result['file'], equals('config.yaml'));
        expect(result['schema_url'],
            equals('https://api.example.com/openapi.json'));
        expect(result['output_directory'], equals('lib/generated'));
      });
    });

    group('Argument values with special characters', () {
      test('should handle paths with spaces', () {
        final result =
            parseConfigGeneratorArguments(['--file', 'my config file.yaml']);
        expect(result['file'], equals('my config file.yaml'));
      });

      test('should handle URLs with query parameters', () {
        final result = parseConfigGeneratorArguments([
          '--schema_url',
          'https://api.example.com/openapi.json?version=1.0&format=json'
        ]);
        expect(
            result['schema_url'],
            equals(
                'https://api.example.com/openapi.json?version=1.0&format=json'));
      });

      test('should handle paths with special characters', () {
        final result = parseConfigGeneratorArguments(
            ['--output_directory', 'lib/api-v2.0']);
        expect(result['output_directory'], equals('lib/api-v2.0'));
      });
    });

    group('Empty and null values', () {
      test('should handle empty arguments list', () {
        final result = parseConfigGeneratorArguments([]);

        // All arguments should be null when not provided
        expect(result['file'], isNull);
        expect(result['schema_path'], isNull);
        expect(result['schema_url'], isNull);
        expect(result['output_directory'], isNull);
        expect(result['json_serializer'], isNull);
        expect(result['help'], isFalse);
      });

      test('should handle empty string values', () {
        final result = parseConfigGeneratorArguments(
            ['--file', '', '--schema_path', '', '--json_serializer', '']);

        expect(result['file'], equals(''));
        expect(result['schema_path'], equals(''));
        expect(result['json_serializer'], equals(''));
      });
    });

    group('Argument validation', () {
      test('should throw FormatException for unknown arguments', () {
        expect(
          () => parseConfigGeneratorArguments(['--unknown-arg', 'value']),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for missing argument value', () {
        expect(
          () => parseConfigGeneratorArguments(['--file']),
          throwsA(isA<FormatException>()),
        );
      });

      test('should throw FormatException for unknown abbreviation', () {
        expect(
          () => parseConfigGeneratorArguments(['-x', 'value']),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Edge cases', () {
      test('should handle argument with equals sign', () {
        final result = parseConfigGeneratorArguments(['--file=config.yaml']);
        expect(result['file'], equals('config.yaml'));
      });

      test('should handle multiple equal signs in value', () {
        final result = parseConfigGeneratorArguments(
            ['--schema_url=https://api.example.com/openapi.json?a=b&c=d']);
        expect(result['schema_url'],
            equals('https://api.example.com/openapi.json?a=b&c=d'));
      });

      test('should handle arguments with dashes in values', () {
        final result = parseConfigGeneratorArguments(
            ['--output_directory', 'lib/api-client-v2']);
        expect(result['output_directory'], equals('lib/api-client-v2'));
      });
    });
  });
}
