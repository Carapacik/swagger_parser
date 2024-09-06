import 'package:yaml/yaml.dart';

import '../generator/config/generator_config.dart';
import '../generator/model/json_serializer.dart';
import '../generator/model/programming_language.dart';
import '../parser/swagger_parser_core.dart';
import 'config_exception.dart';

/// Swagger Parser Config
class SWPConfig {
  /// Creates a [SWPConfig].
  const SWPConfig({
    required this.outputDirectory,
    this.schemaPath,
    this.schemaUrl,
    this.name = 'api',
    this.language = ProgrammingLanguage.dart,
    this.jsonSerializer = JsonSerializer.jsonSerializable,
    this.rootClient = true,
    this.rootClientName = 'RestClient',
    this.clientPostfix,
    this.exportFile = true,
    this.putClientsInFolder = false,
    this.enumsToJson = false,
    this.unknownEnumValue = true,
    this.markFilesAsGenerated = true,
    this.originalHttpResponse = false,
    this.replacementRules = const [],
    this.defaultContentType = 'application/json',
    this.extrasParameterByDefault = false,
    this.dioOptionsParameterByDefault = false,
    this.pathMethodName = false,
    this.mergeClients = false,
    this.enumsParentPrefix = true,
    this.skippedParameters = const <String>[],
  });

  /// Internal constructor of [SWPConfig]
  const SWPConfig._({
    required this.outputDirectory,
    required this.schemaPath,
    required this.schemaUrl,
    required this.name,
    required this.language,
    required this.jsonSerializer,
    required this.rootClient,
    required this.rootClientName,
    required this.clientPostfix,
    required this.exportFile,
    required this.putClientsInFolder,
    required this.enumsToJson,
    required this.unknownEnumValue,
    required this.markFilesAsGenerated,
    required this.originalHttpResponse,
    required this.replacementRules,
    required this.defaultContentType,
    required this.extrasParameterByDefault,
    required this.dioOptionsParameterByDefault,
    required this.pathMethodName,
    required this.mergeClients,
    required this.enumsParentPrefix,
    required this.skippedParameters,
  });

  /// Creates a [SWPConfig] from [YamlMap].
  factory SWPConfig.fromYaml(
    YamlMap yamlMap, {
    bool isRootConfig = false,
    SWPConfig? rootConfig,
  }) {
    var schemaPath = yamlMap['schema_path']?.toString();
    if (isRootConfig && schemaPath == null) {
      schemaPath = '';
    }

    final schemaUrl = yamlMap['schema_url']?.toString();
    if (schemaUrl != null) {
      final uri = Uri.tryParse(schemaUrl);
      if (uri == null) {
        throw const ConfigException(
          "Config parameter 'schema_url' must be valid URL.",
        );
      }
    }

    if (schemaPath == null && schemaUrl == null) {
      throw const ConfigException(
        "Config parameters 'schema_path' or 'schema_url' are required.",
      );
    }

    var outputDirectory = yamlMap['output_directory']?.toString();
    if (isRootConfig && outputDirectory == null) {
      outputDirectory = '';
    }
    if (outputDirectory == null) {
      if (rootConfig == null) {
        throw const ConfigException(
          "Config parameter 'output_directory' is required.",
        );
      } else if (rootConfig.outputDirectory == '') {
        throw ConfigException(
          "Config parameter 'output_directory' for $schemaPath was not found.\n"
          "Add the 'output_directory' parameter under 'swagger_parser:' or set it for each schema.",
        );
      }
      outputDirectory = rootConfig.outputDirectory;
    }

    final rawName = yamlMap['name']?.toString();
    final name = rawName == null || rawName.isEmpty
        ? (schemaPath ?? schemaUrl)!.split('/').last.split('.').first
        : rawName;

    final defaultContentType = yamlMap['default_content_type'];
    if (defaultContentType is! String?) {
      throw const ConfigException(
        "Config parameter 'default_content_type' must be String.",
      );
    }

    final extrasParameterByDefault = yamlMap['extras_parameter_by_default'];
    if (extrasParameterByDefault is! bool?) {
      throw const ConfigException(
        "Config parameter 'extras_parameter_by_default' must be bool.",
      );
    }

    final dioOptionsParameterByDefault =
        yamlMap['dio_options_parameter_by_default'];
    if (dioOptionsParameterByDefault is! bool?) {
      throw const ConfigException(
        "Config parameter 'dio_options_parameter_by_default' must be bool.",
      );
    }

    final pathMethodName = yamlMap['path_method_name'];
    if (pathMethodName is! bool?) {
      throw const ConfigException(
        "Config parameter 'path_method_name' must be bool.",
      );
    }

    final requiredByDefault = yamlMap['required_by_default'];
    if (requiredByDefault is! bool?) {
      throw const ConfigException(
        "Config parameter 'required_by_default' must be bool.",
      );
    }

    final mergeClients = yamlMap['mergeClients'];
    if (mergeClients is! bool?) {
      throw const ConfigException(
        "Config parameter 'mergeClients' must be bool.",
      );
    }

    final enumsParentPrefix = yamlMap['enums_parent_prefix'];
    if (enumsParentPrefix is! bool?) {
      throw const ConfigException(
        "Config parameter 'enums_parent_prefix' must be bool.",
      );
    }

    final rawSkippedParameters = yamlMap['skipped_parameters'];
    if (rawSkippedParameters is! YamlList?) {
      throw const ConfigException(
        "Config parameter 'skipped_parameters' must be list.",
      );
    }
    List<String>? skippedParameters;
    if (rawSkippedParameters != null) {
      skippedParameters = [];
      for (final p in rawSkippedParameters) {
        if (p is! String) {
          throw const ConfigException(
            "Config parameter 'skipped_parameters' values must be List of String.",
          );
        }
        skippedParameters.add(p);
      }
    }

    ProgrammingLanguage? language;
    final rawLanguage = yamlMap['language']?.toString();
    if (rawLanguage != null) {
      language = ProgrammingLanguage.fromString(rawLanguage);
    }

    JsonSerializer? jsonSerializer;
    final rawJsonSerializer = yamlMap['json_serializer']?.toString();
    if (rawJsonSerializer != null) {
      jsonSerializer = JsonSerializer.fromString(rawJsonSerializer);
    }

    final rootClient = yamlMap['root_client'];
    if (rootClient is! bool?) {
      throw const ConfigException(
        "Config parameter 'root_client' must be bool.",
      );
    }

    final rootClientName = yamlMap['root_client_name'];
    if (rootClientName is! String?) {
      throw const ConfigException(
        "Config parameter 'root_client_name' must be String.",
      );
    }

    final clientPostfix = yamlMap['client_postfix'];
    if (clientPostfix is! String?) {
      throw const ConfigException(
        "Config parameter 'client_postfix' must be String.",
      );
    }

    final exportFile = yamlMap['export_file'];
    if (exportFile is! bool?) {
      throw const ConfigException(
        "Config parameter 'export_file' must be bool.",
      );
    }

    final putClientsInFolder = yamlMap['put_clients_in_folder'];
    if (putClientsInFolder is! bool?) {
      throw const ConfigException(
        "Config parameter 'put_clients_in_folder' must be bool.",
      );
    }

    final enumsToJson = yamlMap['enums_to_json'];
    if (enumsToJson is! bool?) {
      throw const ConfigException(
        "Config parameter 'enums_to_json' must be bool.",
      );
    }

    final unknownEnumValue = yamlMap['unknown_enum_value'];
    if (unknownEnumValue is! bool?) {
      throw const ConfigException(
        "Config parameter 'unknown_enum_value' must be bool.",
      );
    }

    final markFilesAsGenerated = yamlMap['mark_files_as_generated'];
    if (markFilesAsGenerated is! bool?) {
      throw const ConfigException(
        "Config parameter 'mark_files_as_generated' must be bool.",
      );
    }

    final originalHttpResponse = yamlMap['original_http_response'];
    if (originalHttpResponse is! bool?) {
      throw const ConfigException(
        "Config parameter 'original_http_response' must be bool.",
      );
    }

    final rawReplacementRules = yamlMap['replacement_rules'];
    if (rawReplacementRules is! YamlList?) {
      throw const ConfigException(
        "Config parameter 'replacement_rules' must be list.",
      );
    }
    List<ReplacementRule>? replacementRules;
    if (rawReplacementRules != null) {
      replacementRules = [];
      for (final r in rawReplacementRules) {
        if (r is! YamlMap ||
            r['pattern'] is! String ||
            r['replacement'] is! String) {
          throw const ConfigException(
            "Config parameter 'replacement_rules' values must be maps of strings "
            "and contain 'pattern' and 'replacement'.",
          );
        }
        replacementRules.add(
          ReplacementRule(
            pattern: RegExp(r['pattern'].toString()),
            replacement: r['replacement'].toString(),
          ),
        );
      }
    }

    // Default config
    final dc = SWPConfig(name: name, outputDirectory: outputDirectory);

    return SWPConfig._(
      schemaPath: schemaPath,
      schemaUrl: schemaUrl,
      outputDirectory: outputDirectory,
      name: name,
      pathMethodName: pathMethodName ?? dc.pathMethodName,
      defaultContentType: defaultContentType ?? dc.defaultContentType,
      extrasParameterByDefault:
          extrasParameterByDefault ?? dc.extrasParameterByDefault,
      dioOptionsParameterByDefault:
          dioOptionsParameterByDefault ?? dc.dioOptionsParameterByDefault,
      mergeClients: mergeClients ?? dc.mergeClients,
      enumsParentPrefix: enumsParentPrefix ?? dc.enumsParentPrefix,
      skippedParameters: skippedParameters ?? dc.skippedParameters,
      exportFile: exportFile ?? dc.exportFile,
      language: language ?? dc.language,
      jsonSerializer: jsonSerializer ?? dc.jsonSerializer,
      rootClient: rootClient ?? dc.rootClient,
      rootClientName: rootClientName ?? dc.rootClientName,
      clientPostfix: clientPostfix?.trim() ?? dc.clientPostfix,
      putClientsInFolder: putClientsInFolder ?? dc.putClientsInFolder,
      enumsToJson: enumsToJson ?? dc.enumsToJson,
      unknownEnumValue: unknownEnumValue ?? dc.unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated ?? dc.markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse ?? dc.originalHttpResponse,
      replacementRules: replacementRules ?? dc.replacementRules,
    );
  }

  /// Sets the path directory of the OpenApi schema.
  final String? schemaPath;

  /// Sets the url of the OpenApi schema.
  final String? schemaUrl;

  /// Optional. Set API name for folder and export file
  /// If not specified, the file name is used.
  final String name;

  /// Required. Sets output directory for generated files (Clients and DTOs).
  final String outputDirectory;

  /// Optional. Sets the programming language.
  /// Current available languages are: dart, kotlin.
  final ProgrammingLanguage language;

  /// DART ONLY
  /// Optional. Current available serializers are: json_serializable, freezed, dart_mappable.
  final JsonSerializer jsonSerializer;

  /// Optional. Set postfix for client classes and files.
  final String? clientPostfix;

  /// DART ONLY
  /// Optional. Set 'true' to generate root client
  /// with interface and all clients instances.
  final bool rootClient;

  /// DART ONLY
  /// Optional. Set root client name.
  final String rootClientName;

  /// DART ONLY
  /// Optional. Set `true` to generate export file.
  final bool exportFile;

  /// Optional. Set `true` to put all clients in clients folder.
  final bool putClientsInFolder;

  /// DART ONLY
  /// Optional. Set `true` to include toJson() in enums.
  /// If set to `false`, serialization will use .name instead.
  final bool enumsToJson;

  /// DART ONLY
  /// Optional. Set `true` to maintain backwards compatibility when adding new values on the backend.
  final bool unknownEnumValue;

  /// Optional. Set `false` to not put a comment at the beginning of the generated files.
  final bool markFilesAsGenerated;

  /// DART ONLY
  /// Optional. Set `true` to wrap all request return types with HttpResponse.
  final bool originalHttpResponse;

  /// Optional. Set regex replacement rules for the names of the generated classes/enums.
  /// All rules are applied in order.
  final List<ReplacementRule> replacementRules;

  /// DART ONLY
  /// Default content type for all requests and responses.
  ///
  /// If the content type does not match the default, generates:
  /// `@Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})`
  final String defaultContentType;

  /// DART ONLY
  /// Add extra parameter to all requests. Supported after retrofit 4.1.0.
  ///
  /// If  value is 'true', then the annotation will be added to all requests.
  /// ```dart
  /// @POST('/path/')
  /// Future<String> myMethod({@Extras() Map<String, dynamic>? extras});
  /// ```
  final bool extrasParameterByDefault;

  /// DART ONLY
  /// Add dio options parameter to all requests.
  ///
  /// If  value is 'true', then the annotation will be added to all requests.
  /// ```dart
  /// @POST('/path/')
  /// Future<String> myMethod({@DioOptions() RequestOptions? options});
  /// ```
  final bool dioOptionsParameterByDefault;

  /// If `true`, use the endpoint path for the method name.
  /// if `false`, use `operationId`.
  final bool pathMethodName;

  /// Set `true` to merge all clients in single client.
  final bool mergeClients;

  /// Set 'true' to set enum prefix from parent component.
  final bool enumsParentPrefix;

  /// List of parameter names that should skip during parsing
  final List<String> skippedParameters;

  /// Convert [SWPConfig] to [GeneratorConfig]
  GeneratorConfig toGeneratorConfig() {
    return GeneratorConfig(
      name: name,
      outputDirectory: outputDirectory,
      language: language,
      jsonSerializer: jsonSerializer,
      defaultContentType: defaultContentType,
      extrasParameterByDefault: extrasParameterByDefault,
      dioOptionsParameterByDefault: dioOptionsParameterByDefault,
      rootClient: rootClient,
      rootClientName: rootClientName,
      clientPostfix: clientPostfix,
      exportFile: exportFile,
      putClientsInFolder: putClientsInFolder,
      enumsToJson: enumsToJson,
      unknownEnumValue: unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse,
      replacementRules: replacementRules,
    );
  }

  /// Convert [SWPConfig] to [ParserConfig]
  ParserConfig toParserConfig({
    required String fileContent,
    required bool isJson,
  }) {
    return ParserConfig(
      fileContent,
      isJson: isJson,
      name: name,
      defaultContentType: defaultContentType,
      pathMethodName: pathMethodName,
      mergeClients: mergeClients,
      enumsParentPrefix: enumsParentPrefix,
      skippedParameters: skippedParameters,
      replacementRules: replacementRules,
    );
  }
}
