import 'package:args/args.dart';
import 'package:yaml/yaml.dart';

import '../utils/file_utils.dart';
import 'swp_config.dart';

///
class ConfigProcessor {
  /// Creates a [ConfigProcessor].

  const ConfigProcessor();

  ///
  YamlMap readConfigFromFile(List<String> arguments) {
    final parser = ArgParser()..addOption('file', abbr: 'f');
    final configFile = getConfigFile(
      filePath: parser.parse(arguments)['file']?.toString(),
    );
    if (configFile == null) {
      throw Exception('Can not find yaml config file.');
    }

    final yamlFileContent = configFile.readAsStringSync();
    final yamlFile = loadYaml(yamlFileContent);

    if (yamlFile is! YamlMap) {
      throw Exception(
        "Failed to extract config from the 'pubspec.yaml' file.\n"
        'Expected YAML map but got ${yamlFile.runtimeType}.',
      );
    }
    final yamlMap = yamlFile['swagger_parser'] as YamlMap?;

    if (yamlMap == null) {
      throw Exception(
        "`${configFile.path}` file does not contain a 'swagger_parser' section.",
      );
    }

    return yamlMap;
  }

  ///
  List<SWPConfig> parseConfig(YamlMap yamlMap) {
    final configs = <SWPConfig>[];

    final schemaPath = yamlMap['schema_path'] as String?;
    final schemaUrl = yamlMap['schema_url'] as String?;
    final schemas = yamlMap['schemas'] as YamlList?;

    if (schemas == null && schemaUrl == null && schemaPath == null) {
      throw Exception(
        "Config parameter 'schema_path', 'schema_url' or 'schemas' is required.",
      );
    }

    if (schemas != null && schemaPath != null ||
        schemas != null && schemaUrl != null) {
      throw Exception(
        "Config parameter 'schema_path' or 'schema_url' can't be used with 'schemas'.",
      );
    }

    if (schemas != null) {
      final rootConfig = SWPConfig.fromYaml(
        yamlMap,
        isRootConfig: true,
      );

      for (final schema in schemas) {
        if (schema is! YamlMap) {
          throw Exception("Config parameter 'schemas' must be list of maps.");
        }
        final config = SWPConfig.fromYaml(
          schema,
          rootConfig: rootConfig,
        );
        configs.add(config);
      }
    } else {
      final config = SWPConfig.fromYaml(yamlMap);
      configs.add(config);
    }

    return configs;
  }
}
