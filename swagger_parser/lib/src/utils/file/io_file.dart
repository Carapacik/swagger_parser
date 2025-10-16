import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/generator/model/generated_file.dart';

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

/// Checks if schema file provided in config exists
File? schemaFile(String filePath) {
  final file = File(p.join(_rootDirectoryPath, filePath));
  return file.existsSync() ? file : null;
}

///
Future<String> schemaFromUrl(String url) async {
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  final data = await response.transform<String>(utf8.decoder).join();
  return data;
}

///
void writeSchemaToFile(String schemaContent, String filePath) {
  File(p.join(_rootDirectoryPath, filePath)).writeAsStringSync(schemaContent);
}

/// Creates DTO file
Future<void> generateFile(
  String outputDirectory,
  GeneratedFile generatedFile,
) async {
  final file = File(p.join(outputDirectory, generatedFile.name));
  await file.create(recursive: true);
  await file.writeAsString(generatedFile.content);
}

///
String get _rootDirectoryPath => Directory.current.path;
