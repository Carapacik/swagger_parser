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

  setUpAll(() async {
    // Delete the test project if it exists
    final tempProjectDir = Directory(testProjectPath);
    if (tempProjectDir.existsSync()) {
      await tempProjectDir.delete(recursive: true);
    }

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

  // Run the swagger_parser generation on every schema file
  // This will result in the package having many clients
  group('testSwaggerParserGeneration', () {
    for (final schemaFile in schemaFiles) {
      for (final jsonSerializer in JsonSerializer.values) {
        final schemaFileName = p.basename(schemaFile.path);
        // We will be using the name of the schema file as the folder name
        // To be compatible with how dart allows folders to be named
        // We will remove all non-alphabetical characters
        final folderName =
            schemaFileName.replaceAll(RegExp('[^a-zA-Z]'), '').toLowerCase();
        final clientOutputPath =
            p.join(testProjectPath, 'lib', 'api', folderName);
        test('$schemaFileName - ${jsonSerializer.name}', () async {
          await testSwaggerParserGeneration(
              schemaFile, clientOutputPath, jsonSerializer);
        });
      }
      break;
    }
  });

  // Run the build_runner on the test project
  test('testBuildRunner', () async {
    await testBuildRunner(testProjectPath);
  });
}

// This function will test the generation of the client for a given schema file
Future<void> testSwaggerParserGeneration(
  File schemaFile,
  String clientOutputPath,
  JsonSerializer jsonSerializer,
) async {
  final config = SWPConfig(
    outputDirectory: clientOutputPath,
    schemaPath: schemaFile.absolute.path,
    jsonSerializer: jsonSerializer,
    putClientsInFolder: true,
    enumsParentPrefix: false,
  );
  final processor = GenProcessor(config);
  await processor.generateFiles();
}

Future<void> testBuildRunner(
  String testProjectPath,
) async {
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
