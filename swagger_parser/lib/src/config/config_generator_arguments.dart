import 'dart:io';

import 'package:args/args.dart';

import '../utils/output/output_utils.dart';

/// Returns the [ArgResults] based on the [configGeneratorArguments]
/// for the [arguments] provided when running
/// `dart run swagger_parser [arguments]`
///
/// will show help message if `help` flag is provided.
ArgResults parseConfigGeneratorArguments(List<String> arguments) {
  final parser = ArgParser()
    ..addFlag('help', help: 'Show help message', abbr: 'h', negatable: false);

  for (final arg in configGeneratorArguments) {
    parser.addOption(arg.$1, help: arg.$2, abbr: arg.$3);
  }

  final argResults = parser.parse(arguments);

  if (argResults['help'] == true) {
    printHelpMessage(parser);
    exit(0);
  }

  return argResults;
}

/// List of arguments for the `generate` command.
const List<(String flag, String help, String? abbr)> configGeneratorArguments =
    [
  (
    'file',
    'Path to the configuration file - default: swagger_parser.yaml',
    'f',
  ),
  (
    'name',
    'Name for the folder and export file - default: file name',
    null,
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
    'JSON serializer to use (json_serializable, freezed, dart_mappable) - default: json_serializable',
    null,
  ),
];
