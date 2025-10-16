import 'package:swagger_parser/src/config/config_processor.dart';
import 'package:swagger_parser/src/config/swp_config.dart';
import 'package:swagger_parser/src/generator/generator/generator.dart';
import 'package:swagger_parser/src/generator/model/generated_file.dart';
import 'package:swagger_parser/src/generator/model/generation_statistic.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';

/// Handles whole cycle of generation.
/// Can be provided with arguments
/// to specify custom path to yaml config.
class GenProcessor {
  /// Applies parameters directly from constructor
  /// and sets them to default if not found
  const GenProcessor(this.config);

  /// Config
  final SWPConfig config;

  /// Generates files based on OpenApi definition file
  Future<(OpenApiInfo, GenerationStatistic)> generateFiles() async {
    resetUniqueNameCounters();

    const configProcessor = ConfigProcessor();
    final (fileContent, isJson) = await configProcessor.fileContent(config);
    final parserConfig = config.toParserConfig(
      fileContent: fileContent,
      isJson: isJson,
    );

    final parser = OpenApiParser(parserConfig);
    final generatorConfig = config.toGeneratorConfig();
    final info = parser.openApiInfo;
    final restClients = parser.parseRestClients();
    final dataClasses = parser.parseDataClasses();
    final generator = Generator(
      generatorConfig,
      info: info,
      dataClasses: dataClasses,
      restClients: restClients,
    );

    return generator.generateFiles();
  }

  /// Generates content of files based on OpenApi definition file
  /// and return list of [GeneratedFile]
  Future<List<GeneratedFile>> generateContent(
    ({String fileContent, bool isJson}) configParameters,
  ) async {
    resetUniqueNameCounters();

    final parserConfig = config.toParserConfig(
      fileContent: configParameters.fileContent,
      isJson: configParameters.isJson,
    );
    final parser = OpenApiParser(parserConfig);

    final generatorConfig = config.toGeneratorConfig();
    final info = parser.openApiInfo;
    final restClients = parser.parseRestClients();
    final dataClasses = parser.parseDataClasses();
    final generator = Generator(
      generatorConfig,
      info: info,
      dataClasses: dataClasses,
      restClients: restClients,
    );
    return generator.generateContent();
  }
}
