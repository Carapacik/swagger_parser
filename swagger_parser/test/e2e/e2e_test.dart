import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'e2e_util.dart';

void main() {
  group('E2E', () {
    test('enum member names', () async {
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

    test('multipart request properties', () async {
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

    test('multipart request properties with requiredByDefault false', () async {
      await e2eTest(
        'multipart_request_properties_required_by_default_false',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          requiredByDefault: false,
        ),
        schemaFileName: '../multipart_request_properties/openapi.json',
      );
    });

    test('multipart request with ref', () async {
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
          requiredByDefault: false,
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

    test('request_unnamed_types with requiredByDefault false', () async {
      await e2eTest(
        'request_unnamed_types_required_by_default_false',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          requiredByDefault: false,
        ),
        schemaFileName: '../request_unnamed_types/openapi.json',
      );
    });
  });
}
