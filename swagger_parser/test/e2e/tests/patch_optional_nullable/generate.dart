import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final config = SWPConfig(
    outputDirectory: 'test/e2e/tests/patch_optional_nullable/expected_files',
    schemaPath: 'test/e2e/tests/patch_optional_nullable/openapi.yaml',
    jsonSerializer: JsonSerializer.freezed,
    putClientsInFolder: true,
    includeIfNull: true,
    freezedNullablePresence: true,
  );

  final processor = GenProcessor(config);
  await processor.generateFiles();
  print('Files generated successfully!');
}
