import '../../parser/swagger_parser_core.dart';
import '../../utils/file/io_file.dart';
import '../config/generator_config.dart';
import '../model/generated_file.dart';
import '../model/generation_statistic.dart';
import '../model/programming_language.dart';
import 'fill_controller.dart';

/// Handles whole cycle of generation.
class Generator {
  /// Creates a [Generator].
  const Generator(
    this.config, {
    required this.info,
    required this.dataClasses,
    required this.restClients,
  });

  /// [GeneratorConfig] that [Generator] use
  final GeneratorConfig config;

  /// Api file info
  final OpenApiInfo info;

  /// Data classes list used for generation
  final List<UniversalDataClass> dataClasses;

  /// Rest clients list used for generate
  final List<UniversalRestClient> restClients;

  /// Generates files based on OpenApi definition file
  Future<(OpenApiInfo, GenerationStatistic)> generateFiles() async {
    final stopwatch = Stopwatch()..start();
    final (totalFiles, totalLines) = await _generateFiles();
    stopwatch.stop();

    return (
      info,
      GenerationStatistic(
        totalFiles: totalFiles,
        totalLines: totalLines,
        totalDataClasses: dataClasses.length,
        totalRestClients: restClients.length,
        totalRequests: restClients.fold(0, (v, e) => v + e.requests.length),
        timeElapsed: stopwatch.elapsed,
      ),
    );
  }

  /// Generates content of files based on OpenApi definition file
  /// and return list of [GeneratedFile]
  List<GeneratedFile> generateContent() {
    final fillController = FillController(config: config, info: info);

    final dataClassesFiles =
        dataClasses.map(fillController.fillDtoContent).toList();
    final restClientFiles =
        restClients.map(fillController.fillRestClientContent).toList();

    final rootClientFile = config.language == ProgrammingLanguage.dart &&
            config.rootClient &&
            restClients.isNotEmpty
        ? fillController.fillRootClient(restClients)
        : null;

    final exportFile = config.language == ProgrammingLanguage.dart &&
            config.exportFile &&
            !config.mergeOutputs
        ? fillController.fillExportFile(
            restClients: restClientFiles,
            dataClasses: dataClassesFiles,
            rootClient: rootClientFile,
          )
        : null;

    final files = [
      ...restClientFiles,
      ...dataClassesFiles,
      if (rootClientFile != null) rootClientFile,
      if (exportFile != null) exportFile,
    ];

    if (config.mergeOutputs) {
      return [fillController.fillMergedOutputs(files)];
    }

    return fillController.addGeneratedFileComments(files);
  }

  /// Main function used to create files
  Future<(int, int)> _generateFiles() async {
    var totalFiles = 0;
    var totalLines = 0;
    final files = generateContent();
    totalFiles += files.length;
    for (final file in files) {
      totalLines += RegExp('\n').allMatches(file.content).length;
      await generateFile(config.outputDirectory, file);
    }
    return (totalFiles, totalLines);
  }
}
