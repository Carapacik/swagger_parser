import 'package:swagger_parser/swagger_parser.dart';

Future<void> main() async {
  final config = SWPConfig(
    outputDirectory: 'test/e2e/tests/field_parsers/generated_files',
    schemaPath: 'test/e2e/tests/field_parsers/openapi.yaml',
    jsonSerializer: JsonSerializer.jsonSerializable,
    putClientsInFolder: true,
    fieldParsers: [
      const FieldParser(
        applyToType: 'int',
        parserName: 'CustomIntParser',
        parserAbsolutePath:
            'package:your_package/lib/utils/parsers/custom_int_parser.dart',
      ),
      const FieldParser(
        applyToType: 'int?',
        parserName: 'CustomNullableIntParser',
        parserAbsolutePath:
            'package:your_package/lib/utils/parsers/custom_nullable_int_parser.dart',
      ),
      const FieldParser(
        applyToType: 'bool',
        parserName: 'CustomBoolParser',
        parserAbsolutePath:
            'package:your_package/lib/utils/parsers/custom_bool_parser.dart',
      ),
    ],
  );

  final processor = GenProcessor(config);
  await processor.generateFiles();
  print('Files generated successfully!');
}
