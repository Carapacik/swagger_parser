import 'package:swagger_parser/src/config/config_processor.dart';
import 'package:swagger_parser/src/generator/model/generation_statistic.dart';
import 'package:swagger_parser/src/utils/output/output_utils.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Used for run `dart run swagger_parser`
Future<void> main(List<String> arguments) async {
  introMessage();
  try {
    const configProcessor = ConfigProcessor();

    // Read CLI input
    final argResults = parseConfigGeneratorArguments(arguments);

    // Read YAML config
    final yamlMap = configProcessor.readConfigFromFile(arguments, argResults);

    // Parse config
    final configs = configProcessor.parseConfig(yamlMap, argResults);

    GenerationStatistic? totalStatistic;
    var successSchemasCount = 0;

    generateMessage();
    for (final config in configs) {
      try {
        final processor = GenProcessor(config);
        final (openApi, statistics) = await processor.generateFiles();

        schemaStatisticsMessage(
          openApi: openApi,
          statistics: statistics,
          name: config.name,
        );
        totalStatistic = totalStatistic?.merge(statistics);
        totalStatistic ??= statistics;
        successSchemasCount++;
      } on Object catch (e, s) {
        schemaFailedMessage(e, s, name: config.name);
      }
    }

    if (configs.length > 1 && totalStatistic != null) {
      summaryStatisticsMessage(
        successCount: successSchemasCount,
        schemesCount: configs.length,
        statistics: totalStatistic,
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
