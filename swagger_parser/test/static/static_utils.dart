import 'dart:io';
import 'package:path/path.dart' as p;

// Create a test project and add all the necessary dependencies
// to run swagger_parser and the generated clients
Future<void> setupBaseProject({
  required String projectPath,
  required String swaggerParserPath,
}) async {
  // Create the test project
  final createProjectResult =
      await Process.run('dart', ['create', projectPath, '--force']);
  assert(
    createProjectResult.exitCode == 0,
    'Failed to create project ${createProjectResult.stderr}',
  );

  // Add swagger_parser to the pubspec.yaml
  final addSwaggerParseResult = await Process.run(
    'dart',
    [
      'pub',
      'add',
      "swagger_parser:{'path':'$swaggerParserPath'}",
    ],
    workingDirectory: projectPath,
  );
  assert(
    addSwaggerParseResult.exitCode == 0,
    'Failed to add swagger_parser dependency ${addSwaggerParseResult.stderr}',
  );

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
    workingDirectory: projectPath,
  );
  assert(
    addRemainingDependencies.exitCode == 0,
    'Failed to add remaining dependencies ${addRemainingDependencies.stderr}',
  );

  // Add build config
  final buildConfigFile = File(p.join(projectPath, 'build.yaml'));
  await buildConfigFile.writeAsString('''
global_options:
  freezed:
    runs_before:
      - json_serializable
  json_serializable:
    runs_before:
      - retrofit_generator''');
}

/// Returns a formatted string with the exit code, stdout and stderr of a process
String formatProcessResult(ProcessResult result) {
  return 'Exit code: ${result.exitCode}\n'
      'Stdout: ${result.stdout}\n'
      'Stderr: ${result.stderr}';
}

String formatErrorAndStacktrace(Object? error, StackTrace? stacktrace) {
  return 'Error: $error\nStacktrace: $stacktrace';
}
