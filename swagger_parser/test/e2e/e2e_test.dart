import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'e2e_util.dart';

void main() {
  group('E2E', () {
    test('multipart request properties', () async {
      await e2eTest(
        'multipart_request_properties',
        (outputDirectory, schemaContent) => Generator(
          outputDirectory: outputDirectory,
          schemaContent: schemaContent,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
      );
    });

    test('multipart request with ref', () async {
      await e2eTest(
        'multipart_request_with_ref',
        schemaFileName: 'openapi.yaml',
        (outputDirectory, schemaContent) => Generator(
          outputDirectory: outputDirectory,
          schemaContent: schemaContent,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          isYaml: true,
        ),
      );
    });
    test('multipart request with ref', () async {
      await e2eTest(
        'enum_members_with_leading_dash_and_pre_existing_enum_members',
        schemaFileName: 'openapi.yaml',
        (outputDirectory, schemaContent) => Generator(
          outputDirectory: outputDirectory,
          schemaContent: schemaContent,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          isYaml: true,
        ),
      );
    });
  });
}
