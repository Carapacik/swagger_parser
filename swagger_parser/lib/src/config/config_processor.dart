import 'dart:convert' show JsonEncoder, jsonDecode;
import 'dart:io' show exit;

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../utils/file/io_file.dart';
import '../utils/output/io_output.dart';
import 'config_exception.dart';
import 'swp_config.dart';

/// This class is used to process the config
class ConfigProcessor {
  /// Creates a [ConfigProcessor].
  const ConfigProcessor();

  static const List<(String flag, String help, String? abbr)> cliArgs = [
    (
      'file',
      'Path to the configuration file (swagger_parser.yaml)',
      'f',
    ),
    (
      'schema_path',
      'Path to the OpenAPI/Swagger schema file',
      null,
    ),
    (
      'schema_url',
      'URL to the OpenAPI/Swagger schema',
      null,
    ),
    (
      'output_directory',
      'Directory where generated files will be saved',
      null,
    ),
    (
      'json_serializer',
      'JSON serializer to use (e.g., json_annotation, dart_mappable)',
      null,
    ),
  ];

  /// Parses the provided [arguments] and returns the [ArgResults]
  /// depending on the defined [cliArgs].
  ///
  /// will show help message if `help` flag is provided.
  ArgResults readCliInput(List<String> arguments) {
    final parser = ArgParser()
      // Add help flag
      ..addFlag(
        'help',
        abbr: 'h',
        help: 'Show this help message',
        negatable: false,
      );

    // Add options with descriptions
    for (final arg in cliArgs) {
      parser.addOption(arg.$1, help: arg.$2, abbr: arg.$3);
    }

    final argResults = parser.parse(arguments);

    // Check if help was requested
    if (argResults['help'] == true) {
      printHelpMessage(parser);
      exit(0);
    }

    return argResults;
  }

  /// Process arguments and read config from file
  YamlMap readConfigFromFile(List<String> arguments, ArgResults? argResults) {
    final configFile = getConfigFile(
      filePath: argResults?['file']?.toString(),
    );
    if (configFile == null) {
      throw const ConfigException('Can not find yaml config file.');
    }

    final yamlFileContent = configFile.readAsStringSync();
    final yamlFile = loadYaml(yamlFileContent);

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

    return yamlMap;
  }

  /// Parse [YamlMap] to List of [SWPConfig]
  List<SWPConfig> parseConfig(YamlMap yamlMap, [ArgResults? argResults]) {
    final configs = <SWPConfig>[];

    final schemaPath = argResults?['schema_path']?.toString() ??
        yamlMap['schema_path'] as String?;
    final schemaUrl = argResults?['schema_url']?.toString() ??
        yamlMap['schema_url'] as String?;
    final schemes = yamlMap['schemes'] as YamlList?;

    if (schemes == null && schemaUrl == null && schemaPath == null) {
      throw const ConfigException(
        "Config parameter 'schema_path', 'schema_url' or 'schemes' is required.",
      );
    }

    if (schemes != null && schemaPath != null ||
        schemes != null && schemaUrl != null) {
      throw const ConfigException(
        "Config parameter 'schema_path' or 'schema_url' can't be used with 'schemes'.",
      );
    }

    if (schemes != null) {
      final rootConfig = SWPConfig.fromYamlWithOverrides(yamlMap, argResults,
          isRootConfig: true);

      for (final schema in schemes) {
        if (schema is! YamlMap) {
          throw const ConfigException(
            "Config parameter 'schemes' must be list of maps.",
          );
        }
        final config = SWPConfig.fromYamlWithOverrides(schema, argResults,
            rootConfig: rootConfig);
        configs.add(config);
      }
    } else {
      final config = SWPConfig.fromYamlWithOverrides(yamlMap, argResults);
      configs.add(config);
    }

    return configs;
  }

  /// Get file content and isJson from config parameters
  Future<(String, bool)> fileContent(SWPConfig config) async {
    var isJson = true;
    late String fileContent;
    if (config.schemaPath != null) {
      final file = schemaFile(config.schemaPath!);
      if (file == null) {
        throw ConfigException(
          'Can not find schema file at ${config.schemaPath}',
        );
      }
      final fileExtension = p.extension(config.schemaPath!).toLowerCase();
      isJson = switch (fileExtension) {
        '.json' => true,
        '.yaml' => false,
        _ => true,
      };
      fileContent = file.readAsStringSync();
    } else if (config.schemaUrl != null) {
      (fileContent, isJson) = await schemaFromUrlToFile(config);
    } else {
      throw const ConfigException('`schema_path` or `schema_url` are required');
    }
    return (fileContent, isJson);
  }

  /// Write schemes from urls to local files
  Future<(String, bool)> schemaFromUrlToFile(SWPConfig config) async {
    // It can transfer to GenProcessor.
    if (config.schemaUrl != null) {
      final fileExtension = p.extension(config.schemaUrl!).toLowerCase();
      final isJson = switch (fileExtension) {
        '.json' => true,
        '.yaml' => false,
        _ => true,
      };
      final schemaContent = await schemaFromUrl(config.schemaUrl!);
      if (isJson) {
        final formattedJson = const JsonEncoder.withIndent(
          '    ',
        ).convert(jsonDecode(schemaContent));
        writeSchemaToFile(
          formattedJson,
          p.basenameWithoutExtension(config.schemaUrl!) + fileExtension,
        );
      } else {
        writeSchemaToFile(
          schemaContent,
          p.basenameWithoutExtension(config.schemaUrl!) + fileExtension,
        );
      }
      return (schemaContent, isJson);
    }
    throw const ConfigException('`schema_url` is empty');
  }
}
