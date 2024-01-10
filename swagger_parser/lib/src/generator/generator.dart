import 'dart:convert';

import 'package:path/path.dart' as p;

import '../config/yaml_config.dart';
import '../parser/parser.dart';
import '../utils/case_utils.dart';
import '../utils/file_utils.dart';
import '../utils/utils.dart';
import 'fill_controller.dart';
import 'generator_exception.dart';
import 'models/generated_file.dart';
import 'models/generation_statistics.dart';
import 'models/json_serializer.dart';
import 'models/open_api_info.dart';
import 'models/prefer_schema_source.dart';
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
    required String outputDirectory,
    String? schemaPath,
    String? schemaUrl,
    String? schemaContent,
    bool? isYaml,
    bool? schemaFromUrlToFile,
    PreferSchemaSource? preferSchemeSource,
    ProgrammingLanguage? language,
    String? name,
    JsonSerializer? jsonSerializer,
    bool? rootClient,
    String? clientPostfix,
    bool? exportFile,
    String? rootClientName,
    bool? putClientsInFolder,
    bool? squashClients,
    bool? originalHttpResponse,
    bool? pathMethodName,
    bool? putInFolder,
    bool? enumsToJson,
    bool? enumsPrefix,
    bool? unknownEnumValue,
    String? defaultContentType,
    bool? markFilesAsGenerated,
    List<ReplacementRule>? replacementRules,
    List<String>? skipParameters,
  })  : _schemaPath = schemaPath,
        _schemaUrl = schemaUrl,
        _schemaContent = schemaContent,
        _isYaml = isYaml ?? false,
        _schemaFromUrlToFile = schemaFromUrlToFile ?? true,
        _preferSchemeSource = preferSchemeSource ?? PreferSchemaSource.url,
        _outputDirectory = outputDirectory,
        _name = name,
        _programmingLanguage = language ?? ProgrammingLanguage.dart,
        _jsonSerializer = jsonSerializer ?? JsonSerializer.jsonSerializable,
        _rootClient = rootClient ?? true,
        _rootClientName = rootClientName ?? 'RestClient',
        _exportFile = exportFile ?? true,
        _clientPostfix = clientPostfix ?? 'Client',
        _putClientsInFolder = putClientsInFolder ?? false,
        _squashClients = squashClients ?? false,
        _originalHttpResponse = originalHttpResponse ?? false,
        _pathMethodName = pathMethodName ?? false,
        _putInFolder = putInFolder ?? false,
        _enumsToJson = enumsToJson ?? false,
        _enumsPrefix = enumsPrefix ?? false,
        _unknownEnumValue = unknownEnumValue ?? true,
        _markFilesAsGenerated = markFilesAsGenerated ?? true,
        _defaultContentType = defaultContentType ?? 'application/json',
        _replacementRules = replacementRules ?? const [],
        _skipParameters = skipParameters ?? const [];

  /// Applies parameters set from yaml config file
  factory Generator.fromYamlConfig(YamlConfig yamlConfig) {
    return Generator(
      outputDirectory: yamlConfig.outputDirectory,
      schemaPath: yamlConfig.schemaPath,
      schemaUrl: yamlConfig.schemaUrl,
      schemaFromUrlToFile: yamlConfig.schemaFromUrlToFile,
      preferSchemeSource: yamlConfig.preferSchemaSource,
      language: yamlConfig.language,
      name: yamlConfig.name,
      jsonSerializer: yamlConfig.jsonSerializer,
      rootClient: yamlConfig.rootClient,
      rootClientName: yamlConfig.rootClientName,
      exportFile: yamlConfig.exportFile,
      clientPostfix: yamlConfig.clientPostfix,
      putClientsInFolder: yamlConfig.putClientsInFolder,
      squashClients: yamlConfig.squashClients,
      originalHttpResponse: yamlConfig.originalHttpResponse,
      pathMethodName: yamlConfig.pathMethodName,
      putInFolder: yamlConfig.putInFolder,
      enumsToJson: yamlConfig.enumsToJson,
      enumsPrefix: yamlConfig.enumsPrefix,
      unknownEnumValue: yamlConfig.unknownEnumValue,
      markFilesAsGenerated: yamlConfig.markFilesAsGenerated,
      replacementRules: yamlConfig.replacementRules,
      skipParameters: yamlConfig.skipParameters,
    );
  }

  /// The contents of your schema file
  String? _schemaContent;

  /// Is the schema format YAML
  bool _isYaml;

  /// The path to your schema file
  final String? _schemaPath;

  /// The url to your schema file
  final String? _schemaUrl;

  /// If true, schema will be extracted from url and saved to file
  final bool _schemaFromUrlToFile;

  /// Prefer schema from url or file
  final PreferSchemaSource _preferSchemeSource;

  /// Output directory
  final String _outputDirectory;

  /// Name of schema
  final String? _name;

  /// Output directory
  final ProgrammingLanguage _programmingLanguage;

  /// Use freezed to generate DTOs
  final JsonSerializer _jsonSerializer;

  /// Generate root client for all Clients
  final bool _rootClient;

  /// Root client name
  final String _rootClientName;

  /// Generate export file
  final bool _exportFile;

  /// Client postfix
  final String _clientPostfix;

  /// Put all clients in clients folder
  final bool _putClientsInFolder;

  /// Squash all clients in one client.
  final bool _squashClients;

  /// Generate request methods with HttpResponse<Entity>
  final bool _originalHttpResponse;

  /// If true, use the endpoint path for the method name, if false, use operationId
  final bool _pathMethodName;

  /// If true, generated all files will be put in folder with name of schema
  final bool _putInFolder;

  /// If true, generated enums will have toJson method
  final bool _enumsToJson;

  /// If true, generated enums will have parent component name in its class name
  final bool _enumsPrefix;

  /// If true, adds an unknown value for all enums to maintain backward compatibility when adding new values on the backend.
  final bool _unknownEnumValue;

  /// If true, generated files will be marked as generated
  final bool _markFilesAsGenerated;

  /// Content type for all requests, default 'application/json'
  final String _defaultContentType;

  /// List of rules used to replace patterns in generated class names
  final List<ReplacementRule> _replacementRules;

  /// Skip parameters when generate
  final List<String> _skipParameters;

  /// Result open api info
  late final OpenApiInfo _openApiInfo;

  /// Result data classes
  late final Iterable<UniversalDataClass> _dataClasses;

  /// Result rest clients
  late final Iterable<UniversalRestClient> _restClients;

  int _totalFiles = 0;
  int _totalLines = 0;

  /// Generates files based on OpenApi definition file
  Future<(OpenApiInfo, GenerationStatistics)> generateFiles() async {
    final stopwatch = Stopwatch()..start();

    await fetchSchemaContent();
    _parseOpenApiDefinitionFile();
    await _generateFiles();

    stopwatch.stop();

    return (
      _openApiInfo,
      GenerationStatistics(
        totalFiles: _totalFiles,
        totalLines: _totalLines,
        totalRestClients: _restClients.length,
        totalDataClasses: _dataClasses.length,
        totalRequests:
            _restClients.fold(0, (val, el) => val + el.requests.length),
        timeElapsed: stopwatch.elapsed,
      )
    );
  }

  /// Generates content of files based on OpenApi definition file
  /// and return list of [GeneratedFile]
  Future<List<GeneratedFile>> generateContent() async {
    await fetchSchemaContent();
    _parseOpenApiDefinitionFile();
    return _fillContent();
  }

  Future<void> fetchSchemaContent([
    PreferSchemaSource? preferSchemeSource,
  ]) async {
    final url = _schemaUrl;
    final path = _schemaPath;

    if (((preferSchemeSource ?? _preferSchemeSource) ==
                PreferSchemaSource.url ||
            path == null) &&
        url != null) {
      final extension = p.extension(url).toLowerCase();
      _isYaml = switch (extension) {
        '.yaml' => true,
        '.json' => false,
        _ => throw GeneratorException(
            'Unsupported $url extension: $extension',
          ),
      };
      extractingSchemaFromUrlMessage(url);
      _schemaContent = await schemaFromUrl(url);
      if (_schemaFromUrlToFile && path != null) {
        if (!_isYaml) {
          final formattedJson = const JsonEncoder.withIndent('    ')
              .convert(jsonDecode(_schemaContent!));
          writeSchemaToFile(formattedJson, path);
        } else {
          writeSchemaToFile(_schemaContent!, path);
        }
      }
    } else if (path != null) {
      final configFile = schemaFile(path);
      if (configFile == null) {
        throw GeneratorException("Can't find schema file at $path.");
      }
      final extension = p.extension(path).toLowerCase();
      _isYaml = switch (extension) {
        '.yaml' => true,
        '.json' => false,
        _ => throw GeneratorException(
            'Unsupported $path extension: $extension',
          ),
      };
      _schemaContent = configFile.readAsStringSync();
    } else if (_schemaContent == null) {
      throw GeneratorException(
        "Parameters 'schemaPath' or 'schemaUrl' or 'schemaContent' are required",
      );
    }
  }

  /// Parse definition file content and fill list of [UniversalRestClient]
  /// and list of [UniversalDataClass]
  void _parseOpenApiDefinitionFile() {
    final parser = OpenApiParser(
      _schemaContent!,
      isYaml: _isYaml,
      pathMethodName: _pathMethodName,
      enumsPrefix: _enumsPrefix,
      name: _name,
      squashClients: _squashClients,
      replacementRules: _replacementRules,
      originalHttpResponse: _originalHttpResponse,
      defaultContentType: _defaultContentType,
      skipParameters: _skipParameters,
    );
    _openApiInfo = parser.parseOpenApiInfo();
    _restClients = parser.parseRestClients();
    _dataClasses = parser.parseDataClasses();
  }

  /// Generate files based on parsed universal models
  Future<void> _generateFiles() async {
    final files = await _fillContent();
    _totalFiles += files.length;
    for (final file in files) {
      _totalLines += RegExp('\n').allMatches(file.contents).length;
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
      exportFileName: _name ?? 'export',
      jsonSerializer: _jsonSerializer,
      putClientsInFolder: _putClientsInFolder,
      enumsToJson: _enumsToJson,
      unknownEnumValue: _unknownEnumValue,
      markFilesAsGenerated: _markFilesAsGenerated,
      defaultContentType: _defaultContentType,
    );

    final restClientFiles =
        _restClients.map(fillController.fillRestClientContent).toList();

    final dataClassesFiles =
        _dataClasses.map(fillController.fillDtoContent).toList();

    final rootClientFile = _programmingLanguage == ProgrammingLanguage.dart &&
            _rootClient &&
            _restClients.isNotEmpty
        ? fillController.fillRootClient(_restClients)
        : null;

    final exportFile =
        _programmingLanguage == ProgrammingLanguage.dart && _exportFile
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

    return files;
  }
}
