import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:yaml/yaml.dart';

import '../generator/models/json_serializer.dart';
import '../generator/models/prefer_schema_source.dart';
import '../generator/models/programming_language.dart';
import '../generator/models/replacement_rule.dart';
import '../utils/file_utils.dart';
import 'config_exception.dart';

/// Handles parsing Yaml config file
/// If file is specified arguments are parsed from it
/// Otherwise it tries to access 'swagger_parser.yaml'
/// which is a default name for config file
/// If 'swagger_parser.yaml' doesn't exist and
/// file is not specified in arguments,
/// attempts to get config from pubspec.yaml
/// If that fails, throws an exception
final class YamlConfig {
  /// Applies parameters directly from constructor
  const YamlConfig({
    required this.name,
    required this.outputDirectory,
    this.schemaPath,
    this.schemaUrl,
    this.schemaFromUrlToFile,
    this.preferSchemaSource,
    this.language,
    this.jsonSerializer,
    this.rootClient,
    this.rootClientName,
    this.exportFile,
    this.clientPostfix,
    this.putClientsInFolder,
    this.squashClients,
    this.pathMethodName,
    this.putInFolder,
    this.enumsToJson,
    this.enumsPrefix,
    this.unknownEnumValue,
    this.markFilesAsGenerated,
    this.originalHttpResponse,
    this.defaultContentType,
    this.replacementRules = const [],
    this.skipParameters = const [],
  });

  /// Applies parameters from YAML file
  factory YamlConfig.fromYaml(
    YamlMap yamlConfig, {
    bool isRootConfig = false,
    YamlConfig? rootConfig,
  }) {
    String? schemaPath;

    schemaPath = yamlConfig['schema_path']?.toString();
    if (isRootConfig && schemaPath == null) {
      schemaPath = '';
    }

    final schemaUrl = yamlConfig['schema_url']?.toString();
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

    var outputDirectory = yamlConfig['output_directory']?.toString();
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

    final rawName = yamlConfig['name'];
    if (rawName is! String?) {
      throw const ConfigException(
        "Config parameter 'name' must be String.",
      );
    }

    final name = rawName == null || rawName.isEmpty
        ? (schemaPath ?? schemaUrl)!
                .split('/')
                .lastOrNull
                ?.split('.')
                .firstOrNull ??
            'unknown'
        : rawName;

    final schemaFromUrlToFile = yamlConfig['schema_from_url_to_file'];
    if (schemaFromUrlToFile is! bool?) {
      throw const ConfigException(
        "Config parameter 'schema_from_url_to_file' must be bool.",
      );
    }

    PreferSchemaSource? preferSchemaSource;
    final rawPreferSchemeSource =
        yamlConfig['prefer_schema_source']?.toString();
    if (rawPreferSchemeSource != null) {
      preferSchemaSource = PreferSchemaSource.fromString(rawPreferSchemeSource);
      if (preferSchemaSource == null) {
        throw ConfigException(
          "'prefer_schema_source' field must be contained in ${PreferSchemaSource.values.map((e) => e.name)}.",
        );
      }
    }

    ProgrammingLanguage? language;
    final rawLanguage = yamlConfig['language']?.toString();
    if (rawLanguage != null) {
      language = ProgrammingLanguage.fromString(rawLanguage);
      if (language == null) {
        throw ConfigException(
          "'language' field must be contained in ${ProgrammingLanguage.values.map((e) => e.name)}.",
        );
      }
    }

    JsonSerializer? jsonSerializer;
    final rawJsonSerializer = yamlConfig['json_serializer']?.toString();
    if (rawJsonSerializer != null) {
      jsonSerializer = JsonSerializer.fromString(rawJsonSerializer);
      if (jsonSerializer == null) {
        throw ConfigException(
          "'json_serializer' field must be contained in ${JsonSerializer.values.map((e) => e.name)}.",
        );
      }
    }

    final rootClient =
        yamlConfig['root_client'] ?? yamlConfig['root_interface'];
    if (rootClient is! bool?) {
      throw const ConfigException(
        "Config parameter 'root_client' must be bool.",
      );
    }

    final rootClientName = yamlConfig['root_client_name'];
    if (rootClientName is! String?) {
      throw const ConfigException(
        "Config parameter 'root_client_name' must be String.",
      );
    }

    final exportFile = yamlConfig['export_file'];
    if (exportFile is! bool?) {
      throw const ConfigException(
        "Config parameter 'export_file' must be bool.",
      );
    }

    final rawClientPostfix = yamlConfig['client_postfix']?.toString().trim();

    final clientPostfix =
        rawClientPostfix?.isEmpty ?? false ? null : rawClientPostfix;

    final putClientsInFolder =
        yamlConfig['put_clients_in_folder'] ?? yamlConfig['squish_clients'];
    if (putClientsInFolder is! bool?) {
      throw const ConfigException(
        "Config parameter 'put_clients_in_folder' must be bool.",
      );
    }

    final putInFolder = yamlConfig['put_in_folder'];
    if (putInFolder is! bool?) {
      throw const ConfigException(
        "Config parameter 'put_in_folder' must be bool.",
      );
    }

    final squashClients = yamlConfig['squash_clients'];
    if (squashClients is! bool?) {
      throw const ConfigException(
        "Config parameter 'squash_clients' must be bool.",
      );
    }

    final pathMethodName = yamlConfig['path_method_name'];
    if (pathMethodName is! bool?) {
      throw const ConfigException(
        "Config parameter 'path_method_name' must be bool.",
      );
    }

    final enumsToJson = yamlConfig['enums_to_json'];
    if (enumsToJson is! bool?) {
      throw const ConfigException(
        "Config parameter 'enums_to_json' must be bool.",
      );
    }

    final enumsPrefix = yamlConfig['enums_prefix'];
    if (enumsPrefix is! bool?) {
      throw const ConfigException(
        "Config parameter 'enums_prefix' must be bool.",
      );
    }

    final unknownEnumValue = yamlConfig['unknown_enum_value'];
    if (unknownEnumValue is! bool?) {
      throw const ConfigException(
        "Config parameter 'unknown_enum_value' must be bool.",
      );
    }

    final markFilesAsGenerated = yamlConfig['mark_files_as_generated'];
    if (markFilesAsGenerated is! bool?) {
      throw const ConfigException(
        "Config parameter 'mark_files_as_generated' must be bool.",
      );
    }

    final defaultContentType = yamlConfig['default_content_type'];
    if (defaultContentType is! String?) {
      throw const ConfigException(
        "Config parameter 'default_content_type' must be String.",
      );
    }

    final originalHttpResponse = yamlConfig['original_http_response'];
    if (originalHttpResponse is! bool?) {
      throw const ConfigException(
        "Config parameter 'original_http_response' must be bool.",
      );
    }

    final rawReplacementRules = yamlConfig['replacement_rules'];
    if (rawReplacementRules is! YamlList?) {
      throw const ConfigException(
        "Config parameter 'replacement_rules' must be list.",
      );
    }

    List<ReplacementRule>? replacementRules;
    if (rawReplacementRules != null) {
      replacementRules ??= [];
      for (final element in rawReplacementRules) {
        if (element is! YamlMap ||
            element['pattern'] is! String ||
            element['replacement'] is! String) {
          throw const ConfigException(
            "Config parameter 'replacement_rules' values must be maps of strings "
            "and contain 'pattern' and 'replacement'.",
          );
        }
        replacementRules.add(
          ReplacementRule(
            pattern: RegExp(element['pattern'].toString()),
            replacement: element['replacement'].toString(),
          ),
        );
      }
    }

    final rawSkipParameters = yamlConfig['skip_parameters'];
    if (rawSkipParameters is! YamlList?) {
      throw const ConfigException(
        "Config parameter 'skip_fields' must be list.",
      );
    }
    final skipParameters = <String>[];
    if (rawSkipParameters != null) {
      for (final element in rawSkipParameters) {
        if (element is! String) {
          throw const ConfigException(
            "Config parameter 'skip_fields' values must be List of String.",
          );
        }
        skipParameters.add(element);
      }
    }

    return YamlConfig(
      name: name,
      schemaPath: schemaPath,
      outputDirectory: outputDirectory,
      schemaUrl: schemaUrl,
      schemaFromUrlToFile:
          schemaFromUrlToFile ?? rootConfig?.schemaFromUrlToFile,
      preferSchemaSource: preferSchemaSource ?? rootConfig?.preferSchemaSource,
      language: language ?? rootConfig?.language,
      jsonSerializer: jsonSerializer ?? rootConfig?.jsonSerializer,
      rootClient: rootClient ?? rootConfig?.rootClient,
      rootClientName: rootClientName ?? rootConfig?.rootClientName,
      exportFile: exportFile ?? rootConfig?.exportFile,
      clientPostfix: clientPostfix ?? rootConfig?.clientPostfix,
      putInFolder: putInFolder ?? rootConfig?.putInFolder,
      putClientsInFolder: putClientsInFolder ?? rootConfig?.putClientsInFolder,
      squashClients: squashClients ?? rootConfig?.squashClients,
      pathMethodName: pathMethodName ?? rootConfig?.pathMethodName,
      originalHttpResponse:
          originalHttpResponse ?? rootConfig?.originalHttpResponse,
      enumsToJson: enumsToJson ?? rootConfig?.enumsToJson,
      enumsPrefix: enumsPrefix ?? rootConfig?.enumsPrefix,
      unknownEnumValue: unknownEnumValue ?? rootConfig?.unknownEnumValue,
      markFilesAsGenerated:
          markFilesAsGenerated ?? rootConfig?.markFilesAsGenerated,
      defaultContentType: defaultContentType ?? rootConfig?.defaultContentType,
      replacementRules: replacementRules ?? rootConfig?.replacementRules ?? [],
      skipParameters: skipParameters,
    );
  }

  static List<YamlConfig> parseConfigsFromYamlFile(List<String> arguments) {
    final parser = ArgParser()..addOption('file', abbr: 'f');
    final configFile = getConfigFile(
      filePath: parser.parse(arguments)['file']?.toString(),
    );
    if (configFile == null) {
      throw const ConfigException("Can't find yaml config file.");
    }

    final yamlFileContent = configFile.readAsStringSync();
    final dynamic yamlFile = loadYaml(yamlFileContent);

    if (yamlFile is! YamlMap) {
      throw ConfigException(
        "Failed to extract config from the 'pubspec.yaml' file.\n"
        'Expected YAML map but got ${yamlFile.runtimeType}.',
      );
    }

    final yamlMap = yamlFile['swagger_parser'] as YamlMap?;

    if (yamlMap == null) {
      throw ConfigException(
        "`${configFile.path}` file does not contain a 'swagger_parser' section.",
      );
    }

    final configs = <YamlConfig>[];

    final schemaPath = yamlMap['schema_path'] as String?;
    final schemaUrl = yamlMap['schema_url'] as String?;
    final schemas = yamlMap['schemas'] as YamlList?;

    if (schemas == null && schemaUrl == null && schemaPath == null) {
      throw const ConfigException(
        "Config parameter 'schema_path', 'schema_url' or 'schemas' is required.",
      );
    }

    if (schemas != null && schemaPath != null ||
        schemas != null && schemaUrl != null) {
      throw const ConfigException(
        "Config parameter 'schema_path' or 'schema_url' can't be used with 'schemas'.",
      );
    }

    if (schemas != null) {
      final rootConfig = YamlConfig.fromYaml(
        yamlMap,
        isRootConfig: true,
      );

      for (final schema in schemas) {
        if (schema is! YamlMap) {
          throw const ConfigException(
            "Config parameter 'schemas' must be list of maps.",
          );
        }
        final config = YamlConfig.fromYaml(
          schema,
          rootConfig: rootConfig,
        );
        configs.add(config);
      }
    } else {
      final config = YamlConfig.fromYaml(yamlMap);
      configs.add(config);
    }

    return configs;
  }

  final String name;
  final String outputDirectory;
  final String? schemaPath;
  final String? schemaUrl;
  final bool? schemaFromUrlToFile;
  final PreferSchemaSource? preferSchemaSource;
  final ProgrammingLanguage? language;
  final JsonSerializer? jsonSerializer;
  final String? clientPostfix;
  final bool? rootClient;
  final String? rootClientName;
  final bool? exportFile;
  final bool? squashClients;
  final bool? pathMethodName;
  final bool? putClientsInFolder;
  final bool? putInFolder;
  final bool? enumsToJson;
  final bool? enumsPrefix;
  final bool? unknownEnumValue;
  final bool? markFilesAsGenerated;
  final String? defaultContentType;
  final bool? originalHttpResponse;
  final List<ReplacementRule> replacementRules;
  final List<String> skipParameters;
}
