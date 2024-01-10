import 'package:swagger_parser/src/config/yaml_config.dart';
import 'package:swagger_parser/src/generator/models/prefer_schema_source.dart';
import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Used for run `dart run swagger_parser`
Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    /// Run generate from YAML config
    final configs = YamlConfig.parseConfigsFromYamlFile(arguments);

    generateMessage();
    for (final config in configs) {
      final generator = Generator.fromYamlConfig(config);
      await generator.fetchSchemaContent(PreferSchemaSource.url);
    }

    doneExtractMessage();
  } on Exception catch (e) {
    exitWithError('Failed to extract schemas from url.\n$e');
  }
}
