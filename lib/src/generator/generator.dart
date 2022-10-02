import 'package:collection/collection.dart';
import 'package:swagger_parser/src/config/yaml_config.dart';
import 'package:swagger_parser/src/generator/generator_exception.dart';
import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/generator/write_controller.dart';
import 'package:swagger_parser/src/parser/parser.dart';

/// Handles whole cycle of generation.
/// Can be provided with arguments
/// to specify custom path to yaml config.
class Generator {
  /// Applies parameters set in yaml config file
  /// and sets them to default if not found
  Generator(List<String> arguments) {
    final yamlConfig = YamlConfig(arguments);

    _jsonPath = yamlConfig.jsonPath;
    _outputDirectory = yamlConfig.outputDirectory;

    _programmingLanguage = ProgrammingLanguage.dart;
    if (yamlConfig.language != null) {
      final parsedLang = ProgrammingLanguage.values
          .firstWhereOrNull((e) => e.name == yamlConfig.language);
      if (parsedLang == null) {
        throw GeneratorException(
          "'language' field must be contained in ${ProgrammingLanguage.values}",
        );
      }
      _programmingLanguage = parsedLang;
    }

    _freezed = false;
    if (yamlConfig.freezed != null) {
      _freezed = yamlConfig.freezed!;
    }
  }

  late final String _jsonPath;
  late final String _outputDirectory;
  late ProgrammingLanguage _programmingLanguage;
  late bool _freezed;
  late final Iterable<UniversalDataClass> _dataClasses;
  late final Iterable<UniversalRestClient> _restClients;

  /// Generates files based on swagger json
  Future<void> generateAsync() async {
    _parseSwaggerJson();
    await _generateFiles();
  }

  void _parseSwaggerJson() {
    final parser = OpenApiJsonParser(_jsonPath);
    _restClients = parser.parseRestClients();
    _dataClasses = parser.parseDataClasses();
  }

  Future<void> _generateFiles() async {
    final writeController = WriteController(
      _outputDirectory,
      _programmingLanguage,
      freezed: _freezed,
    );
    for (final client in _restClients) {
      await writeController.generateRestClient(client);
    }
    for (final dataClass in _dataClasses) {
      await writeController.generateDto(dataClass);
    }
  }
}
