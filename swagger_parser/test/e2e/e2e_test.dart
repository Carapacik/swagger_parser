import 'package:swagger_parser/src/config/swp_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'e2e_util.dart';

void main() {
  group('E2E', () {
    test('multipart request properties', () async {
      await e2eTest(
        'multipart_request_properties',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
      );
    });

    test('multipart request with ref', () async {
      await e2eTest(
        'multipart_request_with_ref',
        schemaFileName: 'openapi.yaml',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
      );
    });
    test('enum member names', () async {
      await e2eTest(
        'enum_member_names',
        schemaFileName: 'openapi.yaml',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
      );
    });
  });
}
