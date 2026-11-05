import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final config = SWPConfig(
    outputDirectory: 'test/e2e/tests/components_responses_ref/generated_files',
    schemaPath: 'test/e2e/tests/components_responses_ref/openapi.yaml',
    jsonSerializer: JsonSerializer.freezed,
    putClientsInFolder: true,
  );

  final processor = GenProcessor(config);
  await processor.generateFiles();
  print('Files generated successfully!');
}
