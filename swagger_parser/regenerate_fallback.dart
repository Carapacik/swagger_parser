import 'package:swagger_parser/swagger_parser.dart';
import 'test/e2e/e2e_util.dart';

void main() async {
  await e2eTest(
    'xof/fallback_union_mappable',
    (outputDirectory, schemaPath) => SWPConfig(
      outputDirectory: outputDirectory,
      schemaPath: schemaPath,
      jsonSerializer: JsonSerializer.dartMappable,
      putClientsInFolder: true,
      dartMappableConvenientWhen: false,
    ),
    schemaFileName: 'fallback_union.json',
    generateExpectedFiles: true,
  );
}
