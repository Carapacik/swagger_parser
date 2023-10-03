import 'package:path/path.dart' as p;

import '../config/yaml_config.dart';
import '../parser/parser.dart';
import '../utils/case_utils.dart';
import '../utils/file_utils.dart';
import 'fill_controller.dart';
import 'generator_exception.dart';
import 'models/generated_file.dart';
import 'models/open_api_info.dart';
import 'models/programming_language.dart';
import 'models/replacement_rule.dart';
import 'models/universal_data_class.dart';
import 'models/universal_rest_client.dart';

/// Handles whole cycle of generation.
/// Can be provided with arguments
/// to specify custom path to yaml config.
final class Generator {
  /// Applies parameters directly from constructor
  /// and sets them to default if not found
  Generator({
    required String schemaContent,
    required String outputDirectory,
    ProgrammingLanguage? language,
    String? name,
    bool? isYaml,
    bool? freezed,
    bool? rootClient,
    String? clientPostfix,
    String? rootClientName,
    bool? putClientsInFolder,
    bool? squashClients,
    bool? pathMethodName,
    bool? putInFolder,
    bool? enumsToJson,
    bool? enumsPrefix,
    bool? markFilesAsGenerated,
    List<ReplacementRule>? replacementRules,
  })  : _schemaContent = schemaContent,
        _outputDirectory = outputDirectory,
        _name = name,
        _programmingLanguage = language ?? ProgrammingLanguage.dart,
        _isYaml = isYaml ?? false,
        _freezed = freezed ?? false,
        _rootClient = rootClient ?? true,
        _rootClientName = rootClientName ?? 'RestClient',
        _clientPostfix = clientPostfix ?? 'Client',
        _putClientsInFolder = putClientsInFolder ?? false,
        _squashClients = squashClients ?? false,
        _pathMethodName = pathMethodName ?? false,
        _putInFolder = putInFolder ?? false,
        _enumsToJson = enumsToJson ?? false,
        _enumsPrefix = enumsPrefix ?? false,
        _markFilesAsGenerated = markFilesAsGenerated ?? true,
        _replacementRules = replacementRules ?? const [];

  /// Applies parameters set from yaml config file
  factory Generator.fromYamlConfig(YamlConfig yamlConfig) {
    final schemaPath = yamlConfig.schemaPath;
    final configFile = schemaFile(schemaPath);
    if (configFile == null) {
      throw GeneratorException("Can't find schema file at $schemaPath.");
    }

    final isYaml = p.extension(schemaPath).toLowerCase() == '.yaml';
    final schemaContent = configFile.readAsStringSync();

    return Generator(
      schemaContent: schemaContent,
      outputDirectory: yamlConfig.outputDirectory,
      language: yamlConfig.language,
      name: yamlConfig.name,
      isYaml: isYaml,
      freezed: yamlConfig.freezed,
      rootClient: yamlConfig.rootClient,
      rootClientName: yamlConfig.rootClientName,
      clientPostfix: yamlConfig.clientPostfix,
      putClientsInFolder: yamlConfig.putClientsInFolder,
      squashClients: yamlConfig.squashClients,
      pathMethodName: yamlConfig.pathMethodName,
      putInFolder: yamlConfig.putInFolder,
      enumsToJson: yamlConfig.enumsToJson,
      enumsPrefix: yamlConfig.enumsPrefix,
      markFilesAsGenerated: yamlConfig.markFilesAsGenerated,
      replacementRules: yamlConfig.replacementRules,
    );
  }

  /// The contents of your schema file
  final String _schemaContent;

  /// Is the schema format YAML
  final bool _isYaml;

  /// Output directory
  final String _outputDirectory;

  /// Name of schema
  final String? _name;

  /// Output directory
  final ProgrammingLanguage _programmingLanguage;

  /// Use freezed to generate DTOs
  final bool _freezed;

  /// Generate root interface for all Clients
  final bool _rootClient;

  /// Root client name
  final String _rootClientName;

  /// Client postfix
  final String _clientPostfix;

  /// Put all clients in clients folder
  final bool _putClientsInFolder;

  /// Squash all clients in one client.
  final bool _squashClients;

  /// If true, use the endpoint path for the method name, if false, use operationId
  final bool _pathMethodName;

  /// If true, generated all files will be put in folder with name of schema
  final bool _putInFolder;

  /// If true, generated enums will have toJson method
  final bool _enumsToJson;

  /// If true, generated enums will have parent component name in its class name
  final bool _enumsPrefix;

  /// If true, generated files will be marked as generated
  final bool _markFilesAsGenerated;

  /// List of rules used to replace patterns in generated class names
  final List<ReplacementRule> _replacementRules;

  /// Result open api info
  late final OpenApiInfo _openApiInfo;

  /// Result data classes
  late final Iterable<UniversalDataClass> _dataClasses;

  /// Result rest clients
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
    final parser = OpenApiParser(
      _schemaContent,
      isYaml: _isYaml,
      pathMethodName: _pathMethodName,
      enumsPrefix: _enumsPrefix,
      name: _name,
      squashClients: _squashClients,
      replacementRules: _replacementRules,
    );
    _openApiInfo = parser.parseOpenApiInfo();
    _restClients = parser.parseRestClients();
    _dataClasses = parser.parseDataClasses();
  }

  /// Generate files based on parsed universal models
  Future<void> _generateFiles() async {
    final files = await _fillContent();
    for (final file in files) {
      await generateFile(
        '$_outputDirectory${_putInFolder && _name != null ? '/${_name?.toSnake}' : ''}',
        file,
      );
    }
  }

  /// Generate "virtual" files content
  Future<List<GeneratedFile>> _fillContent() async {
    final fillController = FillController(
      openApiInfo: _openApiInfo,
      programmingLanguage: _programmingLanguage,
      rootClientName: _rootClientName,
      clientPostfix: _clientPostfix,
      freezed: _freezed,
      putClientsInFolder: _putClientsInFolder,
      enumsToJson: _enumsToJson,
      markFilesAsGenerated: _markFilesAsGenerated,
    );
    final files = <GeneratedFile>[];
    for (final client in _restClients) {
      files.add(fillController.fillRestClientContent(client));
    }
    for (final dataClass in _dataClasses) {
      files.add(fillController.fillDtoContent(dataClass));
    }
    if (_rootClient &&
        _programmingLanguage == ProgrammingLanguage.dart &&
        _restClients.isNotEmpty) {
      files.add(fillController.fillRootClient(_restClients));
    }
    return files;
  }
}
