import '../../config/config_processor.dart';
import '../../config/swp_config.dart';
import '../../parser/swagger_parser_core.dart';
import '../model/generated_file.dart';
import '../model/generation_statistic.dart';
import 'generator.dart';

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
