import 'package:swagger_parser/src/config/yaml_config_manager.dart';
import 'package:swagger_parser/src/generator/models/generation_statistics.dart';
import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Used for run `dart run swagger_parser:generate`
Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    /// Run generate from YAML config
    final configs = YamlConfigManager.parseConfigsFromYamlFile(arguments);

    GenerationStatistics? allStats;

    generateMessage();
    for (final config in configs) {
      final generator = Generator.fromYamlConfig(config);
      final (openApi, stats) = await generator.generateFiles();

      schemaStatisticsMessage(config.name, openApi, stats);

      allStats = allStats?.merge(stats);
      allStats ??= stats;
    }

    if (configs.length > 1 && allStats != null) {
      summaryStatisticsMessage(configs.length, allStats);
    }

    successMessage();
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
