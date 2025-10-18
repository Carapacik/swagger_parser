import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final config = SWPConfig(
    outputDirectory: 'test/e2e/tests/include_if_null/generated_files',
    schemaPath: 'test/e2e/tests/include_if_null/openapi.yaml',
    jsonSerializer: JsonSerializer.freezed,
    putClientsInFolder: true,
    includeIfNull: true,
  );

  final processor = GenProcessor(config);
  await processor.generateFiles();
  print('Files generated successfully!');
}
