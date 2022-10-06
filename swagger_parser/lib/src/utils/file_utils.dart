import 'dart:io';

import 'package:path/path.dart' as p;

import '../generator/models/generated_file.dart';

/// Checks if config exists at [filePath]
/// Config can be a file provided in arguments,
/// 'swagger_parser.yaml' as default config name
/// or pubspec.yaml containing config inside.
File? getConfigFile({String? filePath}) {
  if (filePath != null) {
    final configFile = File(p.join(_rootDirectoryPath, filePath));
    if (configFile.existsSync()) {
      return configFile;
    }
  }
  final configFile = File(p.join(_rootDirectoryPath, 'swagger_parser.yaml'));
  if (configFile.existsSync()) {
    return configFile;
  }

  final pubspecFile = File(p.join(_rootDirectoryPath, 'pubspec.yaml'));
  return pubspecFile.existsSync() ? pubspecFile : null;
}

/// Checks if json file provided in config exists
File? jsonFile(String jsonPath) {
  final jsonFile = File(p.join(_rootDirectoryPath, jsonPath));
  return jsonFile.existsSync() ? jsonFile : null;
}

/// Creates DTO file
Future<void> generateFile(
  String outputDirectory,
  GeneratedFile generatedFile,
) async {
  final file = File(p.join(outputDirectory, generatedFile.name));
  await file.create(recursive: true);
  await file.writeAsString(generatedFile.contents);
}

String get _rootDirectoryPath => Directory.current.path;
