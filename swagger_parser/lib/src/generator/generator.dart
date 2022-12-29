import 'package:path/path.dart' as p;

import '../config/yaml_config.dart';
import '../parser/parser.dart';
import '../utils/case_utils.dart';
import '../utils/file_utils.dart';
import 'fill_controller.dart';
import 'generator_exception.dart';
import 'models/generated_file.dart';
import 'models/programming_lang.dart';
import 'models/universal_data_class.dart';
import 'models/universal_rest_client.dart';

/// Handles whole cycle of generation.
/// Can be provided with arguments
/// to specify custom path to yaml config.
class Generator {
  /// Applies parameters set from yaml config file
  /// and sets them to default if not found
  Generator.fromYamlConfig(List<String> arguments) {
    final yamlConfig = YamlConfig(arguments);

    _outputDirectory = yamlConfig.outputDirectory;

    final schemaFilePath = yamlConfig.schemaFilePath;
    final configFile = jsonFile(schemaFilePath);
    if (configFile == null) {
      throw GeneratorException("Can't find json file at $schemaFilePath.");
    }
    _isYaml = p.extension(schemaFilePath).toLowerCase() == 'yaml';
    _schemaContent = configFile.readAsStringSync();

    if (yamlConfig.language != null) {
      final parsedLang = ProgrammingLanguage.fromString(yamlConfig.language);
      if (parsedLang == null) {
        throw GeneratorException(
          "'language' field must be contained in ${ProgrammingLanguage.values}.",
        );
      }
      _programmingLanguage = parsedLang;
    }

    if (yamlConfig.freezed != null) {
      _freezed = yamlConfig.freezed!;
    }

    if (yamlConfig.squishClients != null) {
      _squishClients = yamlConfig.squishClients!;
    }

    if (yamlConfig.clientPostfix != null) {
      _clientPostfix = yamlConfig.clientPostfix!;
    }
  }

  /// Applies parameters directly from constructor
  /// without Yaml file
  Generator.fromString({
    required String jsonContent,
    required ProgrammingLanguage language,
    String clientPostfix = 'ApiClient',
    bool freezed = false,
    bool squishClients = false,
    bool isYaml = false,
  }) {
    _schemaContent = jsonContent;
    _programmingLanguage = language;
    _outputDirectory = '';
    _clientPostfix = clientPostfix;
    _squishClients = squishClients;
    _freezed = freezed;
    _isYaml = isYaml;
  }

  /// The contents of your schema file
  late final String _schemaContent;

  /// Output directory
  late final String _outputDirectory;

  /// Output directory
  ProgrammingLanguage _programmingLanguage = ProgrammingLanguage.dart;

  /// Client postfix
  String _clientPostfix = 'ApiClient';

  /// User freezed to generate DTOs
  bool _freezed = false;

  /// Is squish Clients
  bool _squishClients = false;

  /// Is the schema format YAML
  bool _isYaml = false;

  late final Iterable<UniversalDataClass> _dataClasses;
  late final Iterable<UniversalRestClient> _restClients;

  /// Generates files based on swagger json
  Future<void> generateFiles() async {
    _parseSwaggerJson();
    await _generateFiles();
  }

  /// Generates content
  /// and return list of [GeneratedFile]
  Future<List<GeneratedFile>> generateContent() async {
    _parseSwaggerJson();
    return _fillContent();
  }

  /// Parse json content and fill list of [UniversalRestClient]
  /// and list of [UniversalDataClass]
  void _parseSwaggerJson() {
    final parser = OpenApiParser(_schemaContent, isYaml: _isYaml);
    _restClients = parser.parseRestClients();
    _dataClasses = parser.parseDataClasses();
  }

  /// Generate files with content
  Future<void> _generateFiles() async {
    final files = await _fillContent();
    for (final file in files) {
      await generateFile(_outputDirectory, file);
    }
  }

  /// Get files content
  Future<List<GeneratedFile>> _fillContent() async {
    final writeController = FillController(
      clientPostfix: _clientPostfix.toPascal,
      programmingLanguage: _programmingLanguage,
      freezed: _freezed,
      squishClients: _squishClients,
    );
    final files = <GeneratedFile>[];
    for (final client in _restClients) {
      files.add(await writeController.fillRestClientContent(client));
    }
    for (final dataClass in _dataClasses) {
      files.add(await writeController.fillDtoContent(dataClass));
    }
    return files;
  }
}
