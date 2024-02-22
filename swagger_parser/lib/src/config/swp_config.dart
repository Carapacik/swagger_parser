import 'package:yaml/yaml.dart';

import '../generator/config/generator_config.dart';
import '../generator/models/json_serializer.dart';
import '../generator/models/programming_language.dart';
import '../generator/models/replacement_rule.dart';
import '../parser/config/parser_config.dart';

/// Swagger Parser Config
class SWPConfig {
  /// Creates a [SWPConfig].
  const SWPConfig({
    required this.schemaPath,
    required this.schemaUrl,
    required this.name,
    required this.outputDirectory,
    this.language = ProgrammingLanguage.dart,
    this.jsonSerializer = JsonSerializer.jsonSerializable,
    this.rootClient = false,
    this.rootClientName,
    this.clientPostfix,
    this.exportFile = false,
    this.putClientsInFolder = false,
    this.putInFolder = false,
    this.enumsToJson = false,
    this.unknownEnumValue = false,
    this.markFilesAsGenerated = true,
    this.originalHttpResponse = false,
    this.replacementRules = const [],
    this.defaultContentType = 'application/json',
    this.pathMethodName = false,
    this.requiredByDefault = true,
    this.mergeClients = false,
    this.enumParentPrefix = true,
    this.skippedParameters = const <String>[],
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
        throw Exception(
          "Config parameter 'schema_url' must be valid URL.",
        );
      }
    }

    if (schemaPath == null && schemaUrl == null) {
      throw Exception(
        "Config parameters 'schema_path' or 'schema_url' are required.",
      );
    }

    var outputDirectory = yamlMap['output_directory']?.toString();
    if (isRootConfig && outputDirectory == null) {
      outputDirectory = '';
    }
    if (outputDirectory == null) {
      if (rootConfig == null) {
        throw Exception(
          "Config parameter 'output_directory' is required.",
        );
      } else if (rootConfig.outputDirectory == '') {
        throw Exception(
          "Config parameter 'output_directory' for $schemaPath was not found.\n"
          "Add the 'output_directory' parameter under 'swagger_parser:' or set it for each schema.",
        );
      }
      outputDirectory = rootConfig.outputDirectory;
    }

    final rawName = yamlMap['name']?.toString();
    final name = rawName == null || rawName.isEmpty
        ? (schemaPath ?? schemaUrl)!
                .split('/')
                .lastOrNull
                ?.split('.')
                .firstOrNull ??
            'unknown'
        : rawName;

    return SWPConfig(
      schemaPath: schemaPath,
      schemaUrl: schemaUrl,
      name: name,
      outputDirectory: outputDirectory,
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
  final String? rootClientName;

  /// DART ONLY
  /// Optional. Set `true` to generate export file.
  final bool exportFile;

  /// Optional. Set `true` to put all clients in clients folder.
  final bool putClientsInFolder;

  /// Optional. Set to `true` to put the all api in its folder.
  final bool putInFolder;

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
  /// @Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})
  final String defaultContentType;

  /// DART ONLY
  /// It is used if the value does not have the annotations `required` and `nullable`.
  /// If the value is `true`, then value be `required`.
  /// If the value is `false`, then `nullable`.
  final bool requiredByDefault;

  /// If `true`, use the endpoint path for the method name.
  /// if `false`, use `operationId`.
  final bool pathMethodName;

  /// Set `true` to merge all clients in single client.
  final bool mergeClients;

  /// Set 'true' to set enum prefix from parent component.
  final bool enumParentPrefix;

  /// List of parameter names that should skip during parsing
  final List<String> skippedParameters;

  GeneratorConfig toGeneratorConfig() {
    return GeneratorConfig(
      name: name,
      outputDirectory: outputDirectory,
      language: language,
      jsonSerializer: jsonSerializer,
      rootClient: rootClient,
      rootClientName: rootClientName,
      clientPostfix: clientPostfix,
      exportFile: exportFile,
      putClientsInFolder: putClientsInFolder,
      putInFolder: putInFolder,
      enumsToJson: enumsToJson,
      unknownEnumValue: unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse,
      replacementRules: replacementRules,
    );
  }

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
      requiredByDefault: requiredByDefault,
      mergeClients: mergeClients,
      enumParentPrefix: enumParentPrefix,
      skippedParameters: skippedParameters,
    );
  }
}
