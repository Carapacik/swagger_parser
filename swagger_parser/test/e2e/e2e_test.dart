import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'e2e_util.dart';

void main() {
  group('E2E', () {
    test('multipart', () async {
      await e2eTest(
        'multipart',
        (outputDirectory, schemaContent) => Generator(
          outputDirectory: outputDirectory,
          schemaContent: schemaContent,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
      );
    });
  });
}
