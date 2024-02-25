import 'package:swagger_parser/src/config/config_processor.dart';
import 'package:swagger_parser/src/generator/models/generation_statistics.dart';
import 'package:swagger_parser/src/utils/output/io_output.dart'
    if (dart.library.html) 'package:swagger_parser/src/utils/output/web_output.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Used for run `dart run swagger_parser`
Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    /// Run generate from YAML config
    const configProcessor = ConfigProcessor();
    final yamlMap = configProcessor.readConfigFromFile(arguments);
    final configs = configProcessor.parseConfig(yamlMap);

    GenerationStatistics? totalStats;
    var successSchemasCount = 0;

    generateMessage();
    for (final config in configs) {
      try {
        final generator = Generator.fromConfig(config);
        final (openApi, stats) = await generator.generateFiles();

        schemaStatisticsMessage(
          openApi: openApi,
          statistics: stats,
          name: config.name,
        );
        totalStats = totalStats?.merge(stats);
        totalStats ??= stats;
        successSchemasCount++;
      } on Object catch (e, s) {
        schemaFailedMessage(e, s, name: config.name);
      }
    }

    if (configs.length > 1 && totalStats != null) {
      summaryStatisticsMessage(
        successCount: successSchemasCount,
        schemesCount: configs.length,
        statistics: totalStats,
      );
    }

    successMessage(
      successSchemasCount: successSchemasCount,
      schemesCount: configs.length,
    );
  } on Exception catch (e) {
    exitWithError('Failed to generate files.\n$e');
  }
}
