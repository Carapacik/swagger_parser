import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'e2e_util.dart';

void main() {
  group('E2E', () {
    test('enum_member_names', () async {
      await e2eTest(
        'enum_member_names',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          enumsParentPrefix: false,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('multipart_request_properties', () async {
      await e2eTest(
        'multipart_request_properties',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.json',
      );
    });

    test('multipart_request_with_ref', () async {
      await e2eTest(
        'multipart_request_with_ref',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    // https://github.com/Carapacik/swagger_parser/issues/223
    test('corrector', () async {
      await e2eTest(
        'corrector',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          replacementRules: [
            ReplacementRule(pattern: RegExp('V1'), replacement: ''),
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'DTO'),
          ],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    // https://github.com/Carapacik/swagger_parser/issues/224
    // https://github.com/Carapacik/swagger_parser/issues/214
    test('request_unnamed_types', () async {
      await e2eTest(
        'request_unnamed_types',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.json',
      );
    });

    test('nullable_types', () async {
      await e2eTest(
        'nullable_types',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });
  });

  group('basic', () {
    test('additional_properties_class.2.0', () async {
      await e2eTest(
        'basic/additional_properties_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'additional_properties_class.2.0.json',
      );
    });

    test('additional_properties_class.3.0', () async {
      await e2eTest(
        'basic/additional_properties_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'additional_properties_class.3.0.json',
      );
    });

    test('basic_requests.2.0', () async {
      await e2eTest(
        'basic/basic_requests.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'basic_requests.2.0.json',
      );
    });

    test('basic_requests.3.0', () async {
      await e2eTest(
        'basic/basic_requests.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'basic_requests.3.0.json',
      );
    });

    test('basic_types_class.2.0', () async {
      await e2eTest(
        'basic/basic_types_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'basic_types_class.2.0.json',
      );
    });

    test('basic_types_class.3.0', () async {
      await e2eTest(
        'basic/basic_types_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'basic_types_class.3.0.json',
      );
    });

    test('empty_class.2.0', () async {
      await e2eTest(
        'basic/empty_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'empty_class.2.0.json',
      );
    });

    test('empty_class.3.0', () async {
      await e2eTest(
        'basic/empty_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'empty_class.3.0.json',
      );
    });

    test('enum_class', () async {
      await e2eTest(
        'basic/enum_class',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'enum_class.json',
      );
    });

    test('of_like_class.3.1', () async {
      await e2eTest(
        'basic/of_like_class.3.1',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'of_like_class.3.1.json',
      );
    });

    test('reference_types_class.2.0', () async {
      await e2eTest(
        'basic/reference_types_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'reference_types_class.2.0.json',
      );
    });

    test('reference_types_class.3.0', () async {
      await e2eTest(
        'basic/reference_types_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'reference_types_class.3.0.json',
      );
    });

    test('replacement_rules.2.0', () async {
      await e2eTest(
        'basic/replacement_rules.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          putClientsInFolder: true,
          replacementRules: [
            ReplacementRule(pattern: RegExp('List'), replacement: 'Lizt'),
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'DTO'),
          ],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('replacement_rules.3.1', () async {
      await e2eTest(
        'basic/replacement_rules.3.1',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          replacementRules: [
            ReplacementRule(pattern: RegExp('V1'), replacement: ''),
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'DTO'),
          ],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('wrapping_collections.2.0', () async {
      await e2eTest(
        'basic/wrapping_collections.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'wrapping_collections.2.0.json',
      );
    });

    test('wrapping_collections.3.0', () async {
      await e2eTest(
        'basic/wrapping_collections.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'wrapping_collections.3.0.json',
      );
    });
  });
}
