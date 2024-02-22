import '../config/swp_config.dart';
import '../parser/swagger_parser_core.dart';
import '../utils/case_utils.dart';
import '../utils/file_utils.dart';
import '../utils/type_utils.dart';
import 'fill_controller.dart';
import 'generator_exception.dart';
import 'models/generated_file.dart';
import 'models/generation_statistics.dart';
import 'models/json_serializer.dart';
import 'models/programming_language.dart';
import 'models/replacement_rule.dart';

/// Handles whole cycle of generation.
/// Can be provided with arguments
/// to specify custom path to yaml config.
final class Generator {
  /// Applies parameters directly from constructor
  /// and sets them to default if not found
  Generator({
    required this.config,
    required String outputDirectory,
    String? schemaPath,
    String? schemaUrl,
    String? schemaContent,
    bool? isYaml,
    bool? requiredByDefault,
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
    bool? enumParentPrefix,
    bool? unknownEnumValue,
    String? defaultContentType,
    bool? markFilesAsGenerated,
    List<ReplacementRule>? replacementRules,
  })  : _schemaPath = schemaPath,
        _schemaUrl = schemaUrl,
        _schemaContent = schemaContent,
        _isYaml = isYaml ?? false,
        _outputDirectory = outputDirectory,
        _requiredByDefault = requiredByDefault ?? true,
        _name = name,
        _programmingLanguage = language ?? ProgrammingLanguage.dart,
        _jsonSerializer = jsonSerializer ?? JsonSerializer.jsonSerializable,
        _rootClient = rootClient ?? true,
        _rootClientName = rootClientName ?? 'RestClient',
        _exportFile = exportFile ?? true,
        _clientPostfix = clientPostfix ?? 'Client',
        _putClientsInFolder = putClientsInFolder ?? false,
        _originalHttpResponse = originalHttpResponse ?? false,
        _putInFolder = putInFolder ?? false,
        _enumsToJson = enumsToJson ?? false,
        _unknownEnumValue = unknownEnumValue ?? true,
        _markFilesAsGenerated = markFilesAsGenerated ?? true,
        _defaultContentType = defaultContentType ?? 'application/json';

  /// Applies parameters set from yaml config file
  factory Generator.fromConfig(SWPConfig config) {
    return Generator(
      config: config,
      outputDirectory: config.outputDirectory,
      schemaPath: config.schemaPath,
      schemaUrl: config.schemaUrl,
      language: config.language,
      name: config.name,
      jsonSerializer: config.jsonSerializer,
      rootClient: config.rootClient,
      rootClientName: config.rootClientName,
      exportFile: config.exportFile,
      clientPostfix: config.clientPostfix,
      putClientsInFolder: config.putClientsInFolder,
      squashClients: config.mergeClients,
      originalHttpResponse: config.originalHttpResponse,
      pathMethodName: config.pathMethodName,
      putInFolder: config.putInFolder,
      enumsToJson: config.enumsToJson,
      enumParentPrefix: config.enumsParentPrefix,
      unknownEnumValue: config.unknownEnumValue,
      markFilesAsGenerated: config.markFilesAsGenerated,
      replacementRules: config.replacementRules,
    );
  }

  final SWPConfig config;

  /// The contents of your schema file
  String? _schemaContent;

  /// Is the schema format YAML
  bool _isYaml;

  /// The path to your schema file
  final String? _schemaPath;

  /// The url to your schema file
  final String? _schemaUrl;

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

  /// It is used if the value does not have the annotations 'required' and 'nullable'.
  /// If the value is 'true', then value be 'required',
  /// if the value is 'false', then 'nullable'.
  final bool _requiredByDefault;

  /// Generate export file
  final bool _exportFile;

  /// Client postfix
  final String _clientPostfix;

  /// Put all clients in clients folder
  final bool _putClientsInFolder;

  /// Generate request methods with HttpResponse<Entity>
  final bool _originalHttpResponse;

  /// If true, generated all files will be put in folder with name of schema
  final bool _putInFolder;

  /// If true, generated enums will have toJson method
  final bool _enumsToJson;

  /// If true, adds an unknown value for all enums to maintain backward compatibility when adding new values on the backend.
  final bool _unknownEnumValue;

  /// If true, generated files will be marked as generated
  final bool _markFilesAsGenerated;

  /// Content type for all requests, default 'application/json'
  final String _defaultContentType;

  /// Result open api info
  late OpenApiInfo _openApiInfo;

  /// Result data classes
  late Iterable<UniversalDataClass> _dataClasses;

  /// Result rest clients
  late Iterable<UniversalRestClient> _restClients;

  int _totalFiles = 0;
  int _totalLines = 0;

  /// Generates files based on OpenApi definition file
  Future<(OpenApiInfo, GenerationStatistics)> generateFiles() async {
    final stopwatch = Stopwatch()..start();
    resetUniqueNameCounters();

    // await fetchSchemaContent();
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
    resetUniqueNameCounters();

    // await fetchSchemaContent();
    _parseOpenApiDefinitionFile();
    return _fillContent();
  }

  // /// Fetch schema from prefer source
  // Future<void> fetchSchemaContent([
  //   PreferSchemaSource? preferSchemeSource,
  // ]) async {
  //   final url = _schemaUrl;
  //   final path = _schemaPath;
  //
  //   if (((preferSchemeSource ?? _preferSchemeSource) ==
  //               PreferSchemaSource.url ||
  //           path == null) &&
  //       url != null) {
  //     final extension = p.extension(url).toLowerCase();
  //     _isYaml = switch (extension) {
  //       '.yaml' => true,
  //       '.json' => false,
  //       _ => throw GeneratorException(
  //           'Unsupported $url extension: $extension',
  //         ),
  //     };
  //
  //     _schemaContent = await schemaFromUrl(url);
  //     if (_schemaFromUrlToFile && path != null) {
  //       if (!_isYaml) {
  //         final formattedJson = const JsonEncoder.withIndent('    ')
  //             .convert(jsonDecode(_schemaContent!));
  //         writeSchemaToFile(formattedJson, path);
  //       } else {
  //         writeSchemaToFile(_schemaContent!, path);
  //       }
  //     }
  //   } else if (path != null) {
  //     final configFile = schemaFile(path);
  //     if (configFile == null) {
  //       throw GeneratorException("Can't find schema file at $path.");
  //     }
  //     final extension = p.extension(path).toLowerCase();
  //     _isYaml = switch (extension) {
  //       '.yaml' => true,
  //       '.json' => false,
  //       _ => throw GeneratorException(
  //           'Unsupported $path extension: $extension',
  //         ),
  //     };
  //     _schemaContent = configFile.readAsStringSync();
  //   } else if (_schemaContent == null) {
  //     throw GeneratorException(
  //       "Parameters 'schemaPath' or 'schemaUrl' or 'schemaContent' are required",
  //     );
  //   }
  // }

  /// Parse definition file content and fill list of [UniversalRestClient]
  /// and list of [UniversalDataClass]
  Future<void> _parseOpenApiDefinitionFile() async {
    var fileContent = '';
    if (config.schemaPath != null && config.schemaPath!.isNotEmpty) {
      final configFile = schemaFile(config.schemaPath!);
      if (configFile == null) {
        throw GeneratorException(
          'Can not find schema file at ${config.schemaPath}.',
        );
      }
      fileContent = await configFile.readAsString();
    } else {
      // TODO(Carapacik): get schema from url and save to file
      // than read content
    }
    final parserConfig =
        config.toParserConfig(fileContent: fileContent, isJson: true);
    final parser = OpenApiParser(parserConfig);
    _openApiInfo = parser.openApiInfo;
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
        '$_outputDirectory${_putInFolder && _name != null ? '/${_name.toSnake}' : ''}',
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
      originalHttpResponse: _originalHttpResponse,
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
