import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/generator/models/replacement_rule.dart';

import '../config/yaml_config.dart';
import '../parser/parser.dart';
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
    final configFile = schemaFile(schemaFilePath);
    if (configFile == null) {
      throw GeneratorException("Can't find schema file at $schemaFilePath.");
    }
    _isYaml = p.extension(schemaFilePath).toLowerCase() == '.yaml';
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
    if (yamlConfig.rootInterface != null) {
      _rootInterface = yamlConfig.rootInterface!;
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
    _replacementRules = yamlConfig.replacementRules;
  }

  /// Applies parameters directly from constructor
  /// without config YAML file
  Generator.fromString({
    required String schemaContent,
    required ProgrammingLanguage language,
    String? clientPostfix,
    bool freezed = false,
    bool rootInterface = true,
    bool squishClients = false,
    bool isYaml = false,
  }) {
    _schemaContent = schemaContent;
    _programmingLanguage = language;
    _outputDirectory = '';
    _clientPostfix = clientPostfix ?? 'Client';
    _rootInterface = rootInterface;
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
  String _clientPostfix = 'Client';

  List<ReplacementRule> _replacementRules = [];

  /// Generate root interface for all Clients
  bool _rootInterface = true;

  /// Use freezed to generate DTOs
  bool _freezed = false;

  /// Squish Clients in one folder
  bool _squishClients = false;

  /// Is the schema format YAML
  bool _isYaml = false;

  late final Iterable<UniversalDataClass> _dataClasses;
  late final Iterable<UniversalRestClient> _restClients;

  /// Generates files based on OpenApi definition file
  Future<void> generateFiles() async {
    _parseOpenApiDefinitionFile();
    await _generateFiles();
  }

  /// Generates content of files based on OpenApi definition file
  /// and return list of [GeneratedFile]
  Future<List<GeneratedFile>> generateContent() async {
    _parseOpenApiDefinitionFile();
    return _fillContent();
  }

  /// Parse definition file content and fill list of [UniversalRestClient]
  /// and list of [UniversalDataClass]
  void _parseOpenApiDefinitionFile() {
    final parser =
        OpenApiParser(_schemaContent, _replacementRules, isYaml: _isYaml);
    _restClients = parser.parseRestClients();
    _dataClasses = parser.parseDataClasses();
  }

  /// Generate files based on parsed universal models
  Future<void> _generateFiles() async {
    final files = await _fillContent();
    for (final file in files) {
      await generateFile(_outputDirectory, file);
    }
  }

  /// Generate "virtual" files content
  Future<List<GeneratedFile>> _fillContent() async {
    final fillController = FillController(
      programmingLanguage: _programmingLanguage,
      clientPostfix: _clientPostfix,
      freezed: _freezed,
      squishClients: _squishClients,
    );
    final files = <GeneratedFile>[];
    for (final client in _restClients) {
      files.add(fillController.fillRestClientContent(client));
    }
    for (final dataClass in _dataClasses) {
      files.add(fillController.fillDtoContent(dataClass));
    }
    if (_rootInterface && _programmingLanguage == ProgrammingLanguage.dart) {
      files.add(fillController.fillRootInterface(_restClients));
    }
    return files;
  }
}
