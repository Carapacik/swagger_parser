import 'package:swagger_parser/src/config/yaml_config_manager.dart';
import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Used for run `dart run swagger_parser:generate`
Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    /// Run generate from YAML config
    final configs = YamlConfigManager.parseConfigsFromYamlFile(arguments);

    generateMessage();
    for (final config in configs) {
      final generator = Generator.fromYamlConfig(config);
      await generator.generateFiles();
    }
    successMessage();
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
