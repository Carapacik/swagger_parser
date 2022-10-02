import 'dart:io';

import 'package:path/path.dart' as p;

/// Checks if config exists.
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
File? jsonInfo(String jsonPath) {
  final jsonFile = File(p.join(_rootDirectoryPath, jsonPath));
  return jsonFile.existsSync() ? jsonFile : null;
}

/// Creates DTO file
Future<File> createDtoFile(
  String directory,
  String fileName,
  String content,
) async {
  final file = File(_getDtoPath(directory, fileName));
  await file.create(recursive: true);
  await file.writeAsString(content);
  return file;
}

/// Creates Rest client file
Future<File> createRestClientFile(
  String directory,
  String folder,
  String content,
  String fileName,
) async {
  final file = File(_getRestClientPath(directory, folder, fileName));
  await file.create(recursive: true);
  await file.writeAsString(content);
  return file;
}

String _getDtoPath(String outputDir, String fileName) =>
    p.join(_rootDirectoryPath, outputDir, 'shared_models', fileName);

String _getRestClientPath(
  String outputDir,
  String folderName,
  String fileName,
) =>
    p.join(_rootDirectoryPath, outputDir, folderName, fileName);

String get _rootDirectoryPath => Directory.current.path;
