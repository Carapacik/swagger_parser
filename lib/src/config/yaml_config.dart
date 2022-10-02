import 'package:args/args.dart';
import 'package:swagger_parser/src/config/config_exception.dart';
import 'package:swagger_parser/src/utils/file_utils.dart';
import 'package:yaml/yaml.dart';

/// Handles parsing Yaml config file
/// If file is specified arguments are parsed from it
/// Otherwise it tries to access 'swagger_parser.yaml'
/// which is a default name for config file
/// If 'swagger_parser.yaml' doesn't exist and
/// file is not specified in arguments,
/// attempts to get config from pubspec.yaml
/// If that fails, throws an exception
class YamlConfig {
  YamlConfig(List<String> arguments) {
    final parser = ArgParser()..addOption('file', abbr: 'f');
    final configFile = getConfigFile(
      filePath: parser.parse(arguments)['file']?.toString(),
    );
    if (configFile == null) {
      throw ConfigException("Can't find yaml config file.");
    }

    final yamlFileContent = configFile.readAsStringSync();
    final yamlFile = loadYaml(yamlFileContent);

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
    if (yamlConfig.containsKey('json_path')) {
      _jsonPath = yamlConfig['json_path'] as String?;
    }
    if (_jsonPath == null) {
      throw ConfigException("Config parameter 'json_path' is required");
    }
    if (yamlConfig.containsKey('output_directory')) {
      _outputDirectory = yamlConfig['output_directory'] as String?;
    }
    if (_outputDirectory == null) {
      throw ConfigException("Config parameter '_outputDirectory' is required");
    }
    if (yamlConfig.containsKey('language')) {
      _language = yamlConfig['language'].toString();
    }
    if (yamlConfig.containsKey('freezed')) {
      if (yamlConfig['freezed'] is! bool?) {
        throw ConfigException("Config parameter 'freezed' must be bool");
      }
      _freezed = yamlConfig['freezed'] as bool?;
    }
  }

  String? _outputDirectory;
  String? _jsonPath;
  String? _language;
  bool? _freezed;

  String get outputDirectory => _outputDirectory!;

  String get jsonPath => _jsonPath!;

  String? get language => _language;

  bool? get freezed => _freezed;
}
