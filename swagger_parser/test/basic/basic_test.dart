import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

String formatFailedProcessResult(ProcessResult result) {
  return 'Exit code: ${result.exitCode}\n'
      'Stdout: ${result.stdout}\n'
      'Stderr: ${result.stderr}';
}

void main() {
  // Absolute path to the swagger_parser package
  final swaggerParserPackagePath = p.current;

  // Get all the schema files
  final schemasPath = p.join('test', 'schemas');
  final schemaFiles = Directory(schemasPath)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();

  // Set the path to the temp test project
  final testProjectPath =
      p.join(Directory.systemTemp.absolute.path, 'temp_test_project');
  final clientOutputPath = p.join(testProjectPath, 'lib', 'api');

  setUp(() async {
    // Create the test project
    final createProjectResult =
        await Process.run('dart', ['create', testProjectPath, '--force']);
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
        "swagger_parser:{'path':'$swaggerParserPackagePath'}",
      ],
      workingDirectory: testProjectPath,
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
      workingDirectory: testProjectPath,
    );
    assert(
      addRemainingDependencies.exitCode == 0,
      'Failed to add remaining dependencies ${addRemainingDependencies.stderr}',
    );

    // Add build config
    final buildConfigFile = File(p.join(testProjectPath, 'build.yaml'));
    await buildConfigFile.writeAsString('''
global_options:
  freezed:
    runs_before:
      - json_serializable
  json_serializable:
    runs_before:
      - retrofit_generator''');
  });

  // Delete the test project
  tearDown(() async {
    // if (tempProjectDir.existsSync()) {
    //   await tempProjectDir.delete(recursive: true);
    // }
    if (Directory(clientOutputPath).existsSync()) {
      await Directory(clientOutputPath).delete(recursive: true);
    }
  });

  for (final schemaFile in schemaFiles) {
    for (final jsonSerializer in JsonSerializer.values) {
      test('static___${p.basename(schemaFile.path)}___${jsonSerializer.name}',
          () async {
        await staticTestSchema(
          SWPConfig(
            outputDirectory: clientOutputPath,
            schemaPath: schemaFile.absolute.path,
            jsonSerializer: jsonSerializer,
            putClientsInFolder: true,
            enumsParentPrefix: false,
          ),
          testProjectPath,
        );
      });
    }
  }
}

Future<void> staticTestSchema(
  SWPConfig config,
  String testProjectPath,
) async {
  // Create the files
  final processor = GenProcessor(config);
  await processor.generateFiles();

  // Run code generation
  final buildResult = await Process.run(
    'dart',
    ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
    workingDirectory: testProjectPath,
  );
  expect(
    buildResult.exitCode,
    0,
    reason: formatFailedProcessResult(buildResult),
  );

  // Run the analyzer
  final analyzeResult = await Process.run(
    'dart',
    ['analyze', 'lib'],
    workingDirectory: testProjectPath,
  );

  expect(
    analyzeResult.exitCode,
    0,
    reason: formatFailedProcessResult(analyzeResult),
  );
}
