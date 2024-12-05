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
    this.generateValidator = false,
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
    required this.generateValidator,
  });

  /// Creates a [SWPConfig] from [YamlMap].
  factory SWPConfig.fromYaml(
    YamlMap yamlMap, {
    bool isRootConfig = false,
    SWPConfig? rootConfig,
  }) {
    var schemaPath =
        yamlMap['schema_path']?.toString() ?? rootConfig?.schemaPath;
    if (isRootConfig && schemaPath == null) {
      schemaPath = '';
    }

    final schemaUrl =
        yamlMap['schema_url']?.toString() ?? rootConfig?.schemaUrl;
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

    var outputDirectory =
        yamlMap['output_directory']?.toString() ?? rootConfig?.outputDirectory;
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

    final defaultContentType = yamlMap['default_content_type'] as String? ??
        rootConfig?.defaultContentType;
    final extrasParameterByDefault =
        yamlMap['extras_parameter_by_default'] as bool? ??
            rootConfig?.extrasParameterByDefault;
    final dioOptionsParameterByDefault =
        yamlMap['dio_options_parameter_by_default'] as bool? ??
            rootConfig?.dioOptionsParameterByDefault;
    final pathMethodName =
        yamlMap['path_method_name'] as bool? ?? rootConfig?.pathMethodName;
    final mergeClients =
        yamlMap['merge_clients'] as bool? ?? rootConfig?.mergeClients;
    final enumsParentPrefix = yamlMap['enums_parent_prefix'] as bool? ??
        rootConfig?.enumsParentPrefix;

    final rawSkippedParameters = yamlMap['skipped_parameters'] as YamlList?;
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
    } else if (rootConfig?.skippedParameters != null) {
      skippedParameters = List.from(rootConfig!.skippedParameters);
    }

    final rawLanguage = yamlMap['language']?.toString();
    final language = rawLanguage == null
        ? rootConfig?.language
        : ProgrammingLanguage.fromString(rawLanguage);

    JsonSerializer? jsonSerializer;
    final rawJsonSerializer = yamlMap['json_serializer']?.toString();
    if (rawJsonSerializer != null) {
      jsonSerializer = JsonSerializer.fromString(rawJsonSerializer);
    } else if (rootConfig?.jsonSerializer != null) {
      jsonSerializer = rootConfig!.jsonSerializer;
    }

    final rootClient =
        yamlMap['root_client'] as bool? ?? rootConfig?.rootClient;
    final rootClientName =
        yamlMap['root_client_name'] as String? ?? rootConfig?.rootClientName;
    final clientPostfix =
        yamlMap['client_postfix'] as String? ?? rootConfig?.clientPostfix;
    final exportFile =
        yamlMap['export_file'] as bool? ?? rootConfig?.exportFile;
    final putClientsInFolder = yamlMap['put_clients_in_folder'] as bool? ??
        rootConfig?.putClientsInFolder;
    final enumsToJson =
        yamlMap['enums_to_json'] as bool? ?? rootConfig?.enumsToJson;
    final unknownEnumValue =
        yamlMap['unknown_enum_value'] as bool? ?? rootConfig?.unknownEnumValue;
    final markFilesAsGenerated = yamlMap['mark_files_as_generated'] as bool? ??
        rootConfig?.markFilesAsGenerated;
    final originalHttpResponse = yamlMap['original_http_response'] as bool? ??
        rootConfig?.originalHttpResponse;

    final rawReplacementRules = yamlMap['replacement_rules'] as YamlList?;
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
    } else if (rootConfig?.replacementRules != null) {
      replacementRules = List.from(rootConfig!.replacementRules);
    }

    final generateValidator =
        yamlMap['generate_validator'] as bool? ?? rootConfig?.generateValidator;

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
      generateValidator: generateValidator ?? dc.generateValidator,
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

  /// Set `true` to generate validator for freezed.
  final bool generateValidator;

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
      generateValidator: generateValidator,
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
