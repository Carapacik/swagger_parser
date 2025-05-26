@Skip('currently failing - WIP')
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'static_utils.dart';

/// This test will generate clients for all the schemas in the test/schemas folder
/// and validate that the generated code can statically compile
/// To run just for a single schema file, use the following command:
///
/// `dart test --run-skipped --concurrency=1  --name "client_generation {filename without .yaml extention} { one of [JsonSerializer.values]}|build_and_validate_client"`
///
/// For example:
/// `dart test --run-skipped --concurrency=1 --name "client_generation openapi freezed|build_and_validate_client"`
///
/// To run all tests:
/// `dart test --run-skipped ".\test\static\static_test.dart"`
void main() {
  // Get all the schema files
  final schemaFiles = Directory(p.join('test', 'schemas'))
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();

  // Set the path to the temp test project
  final testProjectDir = Directory('test_project');

  setUpAll(() async {
    if (testProjectDir.existsSync()) {
      await testProjectDir.delete(recursive: true);
    }
    await setupBaseProject(projectPath: testProjectDir.path);
  });

  /// Test the generation of the clients for all the schemas
  group('client_generation', () {
    for (final schemaFile in schemaFiles) {
      for (final jsonSerializer in JsonSerializer.values) {
        final schemaFileName = p.basenameWithoutExtension(schemaFile.path);
        final folderName =
            schemaFileName.replaceAll(RegExp('[^a-zA-Z]'), '').toLowerCase();
        final clientOutputPath = p.join(
          testProjectDir.path,
          'lib',
          'api',
          folderName,
        );
        test('$schemaFileName ${jsonSerializer.name}', () async {
          await runSwaggerParserGeneration(
            schemaFile,
            clientOutputPath,
            jsonSerializer,
          );
        });
      }
    }
  });

  /// Test the build and validation of the generated clients
  test('build_and_validate_client', () async {
    await testBuildClient(testProjectDir.path);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

// This function will test the generation of the client for a given schema file
Future<void> runSwaggerParserGeneration(
  File schemaFile,
  String clientOutputPath,
  JsonSerializer jsonSerializer, {
  bool throwOnFailure = false,
}) async {
  final config = SWPConfig(
    outputDirectory: '${clientOutputPath}_${jsonSerializer.name}',
    schemaPath: schemaFile.absolute.path,
    jsonSerializer: jsonSerializer,
    putClientsInFolder: true,
    enumsParentPrefix: false,
  );
  dynamic error;
  StackTrace? stacktrace;
  try {
    final processor = GenProcessor(config);
    await processor.generateFiles();
  } catch (e, s) {
    if (throwOnFailure) {
      rethrow;
    }
    error = e;
    stacktrace = s;
  }
  expect(error, isNull, reason: formatErrorAndStacktrace(error, stacktrace));
}

// This function will test the build and validation of the generated clients
Future<void> testBuildClient(String testProjectPath) async {
  // Run code generation
  final buildResult = await Process.run(
      'dart',
      [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ],
      workingDirectory: testProjectPath);
  expect(buildResult.exitCode, 0, reason: formatProcessResult(buildResult));

  // Run the analyzer
  final analyzeResult = await Process.run(
      'dart',
      [
        'analyze',
        'lib',
      ],
      workingDirectory: testProjectPath);

  expect(analyzeResult.exitCode, 0, reason: formatProcessResult(analyzeResult));
}
