import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main() async {
  final swaggerParserPackagePath = p.current;
  final schemasPath = p.join('test', 'schemas');
  final schemaFiles = Directory(schemasPath)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();
  final tempProjectDir = await Directory.systemTemp.createTemp(
    'temp_project',
  );
  try {
    // Create a basic dart project
    final createProjectResult =
        await Process.run('dart', ['create', tempProjectDir.path, '--force']);
    if (createProjectResult.exitCode != 0) {
      print(createProjectResult.stdout);
      print(createProjectResult.stderr);
    }

    // Add swagger_parser to the pubspec.yaml
    final addSwaggerParseResult = await Process.run(
      'dart',
      [
        'pub',
        'add',
        "swagger_parser:{'path':'$swaggerParserPackagePath'}",
      ],
      workingDirectory: tempProjectDir.path,
    );
    if (addSwaggerParseResult.exitCode != 0) {
      print(addSwaggerParseResult.stdout);
      print(addSwaggerParseResult.stderr);
      throw Exception('Failed to add swagger_parser dependency');
    }

    // Add all dependencies to the pubspec.yaml
    final addRemainingDependencies = await Process.run(
      'dart',
      [
        'pub',
        'add',
        // Dependencies
        'dart_mappable',
        'dio',
        'freezed_annotation',
        'json_annotation',
        'retrofit',
        // Dev dependencies
        'dev:build_runner',
        'dev:dart_mappable_builder',
        'dev:freezed',
        'dev:json_serializable',
        'dev:retrofit_generator',
      ],
      workingDirectory: tempProjectDir.path,
    );
    if (addRemainingDependencies.exitCode != 0) {
      print(addRemainingDependencies.stdout);
      print(addRemainingDependencies.stderr);
      throw Exception('Failed to add other swagger_parser dependencies');
    }

    // Add build config
    final buildConfigFile = File(p.join(tempProjectDir.path, 'build.yaml'));
    await buildConfigFile.writeAsString('''
global_options:
  freezed:
    runs_before:
      - json_serializable
  json_serializable:
    runs_before:
      - retrofit_generator''');

    for (final schemaFile in schemaFiles) {
      for (final jsonFormatter in [
        'json_serializable',
        'freezed',
        'dart_mappable'
      ]) {
        await testSingleSchema(schemaFile, tempProjectDir, jsonFormatter);
      }
    }
  } finally {
    // Clean up the test project
    try {
      // await tempProjectDir.delete(recursive: true);
      // ignore: avoid_catches_without_on_clauses, empty_catches
    } catch (e) {}
  }
  // for (final schema in schemas) {
  //   await testSchema(tempTestProjectDir, schema);
  //   break;
  // }
}

Future<void> testSingleSchema(
    File schema, Directory tempTestProjectDir, String jsonFormatter) async {
  // Create swagger_parser_config.yaml
  final configText = '''
swagger_parser:
  # You must provide the file path and/or url to the OpenApi schema.

  # Sets the OpenApi schema path directory for api definition.
  schema_path: ${schema.absolute.path}

  # Sets the url of the OpenApi schema.
  # schema_url: https://petstore.swagger.io/v2/swagger.json

  # Required. Sets output directory for generated files (Clients and DTOs).
  output_directory: lib/api

  # Optional. Set API name for folder and export file
  # If not specified, the file name is used.
  name: tested_api # We are setting this because it is possible that the filename of our test file may be strange

  # Optional. Sets the programming language.
  # Current available languages are: dart, kotlin.
  language: dart

  # Optional (dart only).
  # Current available serializers are: json_serializable, freezed, dart_mappable.
  json_serializer: $jsonFormatter

''';
  final apiClientFolder =
      Directory(p.join(tempTestProjectDir.path, 'lib', 'api'));
  final configFilePath =
      p.join(tempTestProjectDir.path, 'swagger_parser_config.yaml');

  final configFile = File(configFilePath);
  try {
    await configFile.writeAsString(configText);

    // Run the swagger_parser
    final runResult = await Process.run(
      'dart',
      ['run', 'swagger_parser', '-f', configFile.absolute.path],
      workingDirectory: tempTestProjectDir.path,
    );
    if (runResult.exitCode != 0) {
      print(runResult.stdout);
      print(runResult.stderr);
      throw Exception('Failed to run swagger_parser');
    }
    // Check that a folder named api was created

    if (!apiClientFolder.existsSync()) {
      throw Exception('Failed to create api folder');
    }
    // Run the builder
    final buildResult = await Process.run(
      'dart',
      ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
      workingDirectory: tempTestProjectDir.path,
    );
    if (buildResult.exitCode != 0) {
      print(buildResult.stdout);
      print(buildResult.stderr);
      throw Exception('Failed to run build_runner');
    }
    // Run the analyzer
    final analyzeResult = await Process.run(
      'dart',
      ['analyze', 'lib'],
      workingDirectory: tempTestProjectDir.path,
    );
    if (analyzeResult.exitCode != 0) {
      print(analyzeResult.stdout);
      print(analyzeResult.stderr);
      throw Exception(
          'Analyzer failed on ${p.basename(schema.path)} $jsonFormatter');
    } else {
      print('Success - ${p.basename(schema.path)} $jsonFormatter');
    }
  } finally {
    // Try to remove the swagger_parser_config and generated api client
    try {
      await configFile.delete();
      await apiClientFolder.delete(recursive: true);
      // ignore: avoid_catches_without_on_clauses, empty_catches
    } catch (e) {}
  }
}
