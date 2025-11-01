import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final config = SWPConfig(
    outputDirectory:
        'test/e2e/tests/infer_required_from_nullable/generated_files',
    schemaPath: 'test/e2e/tests/infer_required_from_nullable/openapi.yaml',
    jsonSerializer: JsonSerializer.freezed,
    putClientsInFolder: true,
    inferRequiredFromNullable: true,
  );

  final processor = GenProcessor(config);
  await processor.generateFiles();
  print('Files generated successfully!');
}
