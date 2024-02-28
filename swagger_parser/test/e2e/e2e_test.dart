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
  });
}
