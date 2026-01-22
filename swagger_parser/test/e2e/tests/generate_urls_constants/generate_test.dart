import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final config = SWPConfig(
    outputDirectory: 'test/e2e/tests/generate_urls_constants/generated_files',
    schemaPath: 'test/e2e/tests/generate_urls_constants/openapi.yaml',
    jsonSerializer: JsonSerializer.freezed,
    putClientsInFolder: true,
    generateUrlsConstants: true,
  );

  final processor = GenProcessor(config);
  await processor.generateFiles();
  print('Files generated successfully!');
}
