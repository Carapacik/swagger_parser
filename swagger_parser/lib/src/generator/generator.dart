import 'package:path/path.dart' as p;

import '../config/yaml_config.dart';
import '../parser/parser.dart';
import '../utils/file_utils.dart';
import 'fill_controller.dart';
import 'generator_exception.dart';
import 'models/generated_file.dart';
import 'models/open_api_info.dart';
import 'models/programming_lang.dart';
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
    required ProgrammingLanguage? language,
    required bool? isYaml,
    required bool? freezed,
    required bool? rootInterface,
    required String? rootClientName,
    required String? clientPostfix,
    required bool? squishClients,
    required bool? pathMethodName,
    required bool? enumsToJson,
    required bool? enumsPrefix,
    required bool? markFilesAsGenerated,
    required List<ReplacementRule>? replacementRules,
  })  : _schemaContent = schemaContent,
        _outputDirectory = outputDirectory,
        _programmingLanguage = language ?? ProgrammingLanguage.dart,
        _isYaml = isYaml ?? false,
        _freezed = freezed ?? false,
        _rootInterface = rootInterface ?? true,
        _rootClientName = rootClientName ?? 'RestClient',
        _clientPostfix = clientPostfix ?? 'Client',
        _squishClients = squishClients ?? false,
        _pathMethodName = pathMethodName ?? false,
        _enumsToJson = enumsToJson ?? false,
        _enumsPrefix = enumsPrefix ?? false,
        _markFilesAsGenerated = markFilesAsGenerated ?? true,
        _replacementRules = replacementRules ?? const [];

  /// Applies parameters set from yaml config file
  factory Generator.fromYamlConfig(YamlConfig yamlConfig) {
    final schemaFilePath = yamlConfig.schemaFilePath;
    final configFile = schemaFile(schemaFilePath);
    if (configFile == null) {
      throw GeneratorException("Can't find schema file at $schemaFilePath.");
    }

    final isYaml = p.extension(schemaFilePath).toLowerCase() == '.yaml';
    final schemaContent = configFile.readAsStringSync();

    return Generator(
      schemaContent: schemaContent,
      outputDirectory: yamlConfig.outputDirectory,
      isYaml: isYaml,
      language: yamlConfig.language,
      freezed: yamlConfig.freezed,
      rootInterface: yamlConfig.rootInterface,
      rootClientName: yamlConfig.rootClientName,
      clientPostfix: yamlConfig.clientPostfix,
      squishClients: yamlConfig.squishClients,
      pathMethodName: yamlConfig.pathMethodName,
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

  /// Output directory
  final ProgrammingLanguage _programmingLanguage;

  /// Use freezed to generate DTOs
  final bool _freezed;

  /// Generate root interface for all Clients
  final bool _rootInterface;

  /// Root client name
  final String _rootClientName;

  /// Client postfix
  final String _clientPostfix;

  /// Squish Clients in one folder
  final bool _squishClients;

  /// If true, use the endpoint path for the method name, if false, use operationId
  final bool _pathMethodName;

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
      await generateFile(_outputDirectory, file);
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
      squishClients: _squishClients,
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
    if (_rootInterface &&
        _programmingLanguage == ProgrammingLanguage.dart &&
        _restClients.isNotEmpty) {
      files.add(fillController.fillRootInterface(_restClients));
    }
    return files;
  }
}
