import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import '../generator/models/programming_lang.dart';
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
    required this.schemaFilePath,
    required this.outputDirectory,
    this.language,
    this.freezed,
    this.rootInterface,
    this.clientPostfix,
    this.squishClients,
    this.pathMethodName,
    this.enumsToJson,
    this.enumsPrefix,
    this.markFilesAsGenerated,
    this.replacementRules = const [],
  });

  /// Applies parameters from YAML file
  factory YamlConfig.fromYamlFile(List<String> arguments) {
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

    final yamlConfig = yamlFile['swagger_parser'] as YamlMap?;
    if (yamlConfig == null) {
      throw ConfigException(
        "`${configFile.path}` file does not contain a 'swagger_parser' section.",
      );
    }

    final schemaFilePath = yamlConfig['schema_path']?.toString();
    if (schemaFilePath == null) {
      throw const ConfigException(
        "Config parameter 'schema_path' is required.",
      );
    }

    final outputDirectory = yamlConfig['output_directory']?.toString();
    if (outputDirectory == null) {
      throw const ConfigException(
        "Config parameter 'output_directory' is required.",
      );
    }

    ProgrammingLanguage? language;
    final rawLanguage = yamlConfig['language']?.toString();
    if (rawLanguage != null) {
      language = ProgrammingLanguage.fromString(rawLanguage);
      if (language == null) {
        throw ConfigException(
          "'language' field must be contained in ${ProgrammingLanguage.values}.",
        );
      }
    }

    final freezed = yamlConfig['freezed'];
    if (freezed is! bool?) {
      throw const ConfigException("Config parameter 'freezed' must be bool.");
    }

    final rootInterface = yamlConfig['root_interface'];
    if (rootInterface is! bool?) {
      throw const ConfigException(
        "Config parameter 'root_interface' must be bool.",
      );
    }
    final rawClientPostfix = yamlConfig['client_postfix']?.toString().trim();

    final clientPostfix =
        rawClientPostfix?.isEmpty ?? false ? null : rawClientPostfix;

    final squishClients = yamlConfig['squish_clients'];
    if (squishClients is! bool?) {
      throw const ConfigException(
        "Config parameter 'squish_clients' must be bool.",
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

    final markFilesAsGenerated = yamlConfig['mark_files_as_generated'];
    if (markFilesAsGenerated is! bool?) {
      throw const ConfigException(
        "Config parameter 'mark_files_as_generated' must be bool.",
      );
    }

    final rawReplacementRules = yamlConfig['replacement_rules'];
    if (rawReplacementRules is! YamlList?) {
      throw const ConfigException(
        "Config parameter 'replacement_rules' must be list.",
      );
    }

    final replacementRules = <ReplacementRule>[];
    for (final element in rawReplacementRules ?? []) {
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

    return YamlConfig(
      schemaFilePath: schemaFilePath,
      outputDirectory: outputDirectory,
      language: language,
      freezed: freezed,
      rootInterface: rootInterface,
      clientPostfix: clientPostfix,
      squishClients: squishClients,
      pathMethodName: pathMethodName,
      enumsToJson: enumsToJson,
      enumsPrefix: enumsPrefix,
      markFilesAsGenerated: markFilesAsGenerated,
      replacementRules: replacementRules,
    );
  }

  final String schemaFilePath;
  final String outputDirectory;
  final ProgrammingLanguage? language;
  final bool? freezed;
  final String? clientPostfix;
  final bool? rootInterface;
  final bool? squishClients;
  final bool? pathMethodName;
  final bool? enumsToJson;
  final bool? enumsPrefix;
  final bool? markFilesAsGenerated;
  final List<ReplacementRule> replacementRules;
}
