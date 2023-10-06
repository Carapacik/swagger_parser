import 'package:swagger_parser/src/config/yaml_config.dart';
import 'package:swagger_parser/src/generator/models/generation_statistics.dart';
import 'package:swagger_parser/src/utils/utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Used for run `dart run swagger_parser`
Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    /// Run generate from YAML config
    final configs = YamlConfig.parseConfigsFromYamlFile(arguments);

    GenerationStatistics? totalStats;
    var successSchemasCount = 0;

    generateMessage();
    for (final config in configs) {
      try {
        final generator = Generator.fromYamlConfig(config);
        final (openApi, stats) = await generator.generateFiles();

        schemaStatisticsMessage(
          name: config.name,
          openApi: openApi,
          statistics: stats,
        );
        totalStats = totalStats?.merge(stats);
        totalStats ??= stats;
        successSchemasCount++;
      } on Object catch (e, s) {
        schemaFailedMessage(
          name: config.name,
          error: e,
          stack: s,
        );
      }
    }

    if (configs.length > 1 && totalStats != null) {
      summaryStatisticsMessage(
        successCount: successSchemasCount,
        schemasCount: configs.length,
        statistics: totalStats,
      );
    }

    doneMessage(
      successSchemasCount: successSchemasCount,
      schemasCount: configs.length,
    );
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
