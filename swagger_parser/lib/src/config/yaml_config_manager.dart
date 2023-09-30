import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import '../utils/file_utils.dart';
import 'config_exception.dart';
import 'yaml_config.dart';

abstract final class YamlConfigManager {
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
    final schemas = yamlMap['schemas'] as YamlList?;

    if (schemas == null && schemaPath == null) {
      throw const ConfigException(
        "Config parameter 'schema_path' or 'schemas' is required.",
      );
    }

    if (schemas != null && schemaPath != null) {
      throw const ConfigException(
        "Config parameter 'schema_path' and 'schemas' can't be used together.",
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
}
