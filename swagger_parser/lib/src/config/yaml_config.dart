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
  YamlConfig(List<String> arguments) {
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
    if (yamlConfig.containsKey('schema_path')) {
      _schemaFilePath = yamlConfig['schema_path'].toString();
    }
    if (_schemaFilePath == null) {
      throw const ConfigException(
        "Config parameter 'schema_path' is required.",
      );
    }

    if (yamlConfig.containsKey('output_directory')) {
      _outputDirectory = yamlConfig['output_directory'].toString();
    }
    if (_outputDirectory == null) {
      throw const ConfigException(
        "Config parameter 'output_directory' is required.",
      );
    }

    if (yamlConfig.containsKey('language')) {
      final language =
          ProgrammingLanguage.fromString(yamlConfig['language'].toString());
      if (language == null) {
        throw ConfigException(
          "'language' field must be contained in ${ProgrammingLanguage.values}.",
        );
      }
      _language = language;
    }

    if (yamlConfig.containsKey('freezed')) {
      if (yamlConfig['freezed'] is! bool?) {
        throw const ConfigException("Config parameter 'freezed' must be bool.");
      }
      _freezed = yamlConfig['freezed'] as bool?;
    }

    if (yamlConfig.containsKey('root_interface')) {
      if (yamlConfig['root_interface'] is! bool?) {
        throw const ConfigException(
          "Config parameter 'root_interface' must be bool.",
        );
      }
      _rootInterface = yamlConfig['root_interface'] as bool?;
    }

    if (yamlConfig.containsKey('client_postfix')) {
      final postfix = yamlConfig['client_postfix']?.toString();
      _clientPostfix =
          postfix == null || postfix.trim().isEmpty ? null : postfix;
    }

    if (yamlConfig.containsKey('squish_clients')) {
      if (yamlConfig['squish_clients'] is! bool?) {
        throw const ConfigException(
          "Config parameter 'squish_clients' must be bool.",
        );
      }
      _squishClients = yamlConfig['squish_clients'] as bool?;
    }

    if (yamlConfig.containsKey('path_method_name')) {
      if (yamlConfig['path_method_name'] is! bool?) {
        throw const ConfigException(
          "Config parameter 'path_method_name' must be bool.",
        );
      }
      _pathMethodName = yamlConfig['path_method_name'] as bool?;
    }

    if (yamlConfig.containsKey('enums_to_json')) {
      if (yamlConfig['enums_to_json'] is! bool?) {
        throw const ConfigException(
          "Config parameter 'enums_to_json' must be bool.",
        );
      }
      _enumsToJson = yamlConfig['enums_to_json'] as bool?;
    }

    if (yamlConfig.containsKey('enums_prefix')) {
      if (yamlConfig['enums_prefix'] is! bool?) {
        throw const ConfigException(
          "Config parameter 'enums_prefix' must be bool.",
        );
      }
      _enumsPrefix = yamlConfig['enums_prefix'] as bool?;
    }

    if (yamlConfig.containsKey('mark_files_as_generated')) {
      if (yamlConfig['mark_files_as_generated'] is! bool?) {
        throw const ConfigException(
          "Config parameter 'mark_files_as_generated' must be bool.",
        );
      }
      _markFilesAsGenerated = yamlConfig['mark_files_as_generated'] as bool?;
    }

    if (yamlConfig.containsKey('replacement_rules')) {
      if (yamlConfig['replacement_rules'] is! YamlList) {
        throw const ConfigException(
          "Config parameter 'replacement_rules' must be list.",
        );
      }
      final replacementsYamlList = yamlConfig['replacement_rules'] as YamlList;

      for (final element in replacementsYamlList) {
        if (element is! YamlMap ||
            !element.keys.contains('pattern') ||
            !element.keys.contains('replacement') ||
            element['pattern'] is! String ||
            element['replacement'] is! String) {
          throw const ConfigException(
            "Config parameter 'replacement_rules' values must be maps of strings "
            "and contain 'pattern' and 'replacement'.",
          );
        }

        _replacementRules.add(
          ReplacementRule(
            pattern: RegExp(element['pattern'].toString()),
            replacement: element['replacement'].toString(),
          ),
        );
      }
    }
  }

  String? _outputDirectory;
  String? _schemaFilePath;
  ProgrammingLanguage? _language;
  bool? _freezed;
  String? _clientPostfix;
  bool? _rootInterface;
  bool? _squishClients;
  bool? _pathMethodName;
  bool? _enumsToJson;
  bool? _enumsPrefix;
  bool? _markFilesAsGenerated;
  final List<ReplacementRule> _replacementRules = [];

  String get outputDirectory => _outputDirectory!;

  String get schemaFilePath => _schemaFilePath!;

  ProgrammingLanguage? get language => _language;

  bool? get freezed => _freezed;

  bool? get rootInterface => _rootInterface;

  String? get clientPostfix => _clientPostfix;

  bool? get squishClients => _squishClients;

  bool? get pathMethodName => _pathMethodName;

  bool? get enumsToJson => _enumsToJson;

  bool? get enumsPrefix => _enumsPrefix;

  bool? get markFilesAsGenerated => _markFilesAsGenerated;

  List<ReplacementRule> get replacementRules => _replacementRules;
}
