import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

/// Performs an end-to-end test for a given generator function by comparing generated content against expected files.
/// This method is crucial for validating the correctness and stability of code generation tools,
/// ensuring that changes in the generator do not break existing functionality or output.
/// It reads the OpenAPI schema from a specified path, uses the provided generator function to generate content,
/// and then compares each generated file against a corresponding expected file in a predefined directory.
///
/// By doing so, it verifies that the generated files are exactly as expected, both in content and quantity,
/// providing a reliable way to catch regressions or unintended changes in the code generation process.
Future<void> e2eTest(
  String testName,
  SWPConfig Function(String outputDirectory, String shemaPath) config, {
  String? schemaFileName,
  bool generateExpectedFiles = false,
}) async {
  final testFolder = p.join('test', 'e2e', 'tests', testName);
  final schemaPath = p.join(testFolder, schemaFileName ?? 'openapi.json');
  final expectedFolderPath = p.join(testFolder, 'expected_files');
  final generatedFolderPath = p.join(testFolder, 'generated_files');

  final processor = GenProcessor(
    config.call(
      generateExpectedFiles ? expectedFolderPath : generatedFolderPath,
      schemaPath,
    ),
  );

  if (generateExpectedFiles) {
    Directory(expectedFolderPath).deleteSync(recursive: true);
  }

  await processor.generateFiles();

  await Process.run('dart', ['format', testFolder]);

  // Getting a list of all files from expectedFolderPath
  final expectedFiles = Directory(expectedFolderPath)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();

  final generatedFiles = Directory(generatedFolderPath)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();

  for (final file in expectedFiles) {
    final relativePath =
        p.relative(file.path, from: expectedFolderPath).replaceAll(r'\', '/');

    generatedFiles.firstWhere(
      (gFile) {
        final relPath = p
            .relative(gFile.path, from: generatedFolderPath)
            .replaceAll(r'\', '/');
        return relPath == relativePath;
      },
      orElse: () => throw Exception(
        'File not found in generated content: $relativePath',
      ),
    );
  }

  for (final file in expectedFiles) {
    final relativePath =
        p.relative(file.path, from: expectedFolderPath).replaceAll(r'\', '/');

    final generatedFile = generatedFiles.firstWhere(
      (gFile) {
        final relPath = p
            .relative(gFile.path, from: generatedFolderPath)
            .replaceAll(r'\', '/');
        return relPath == relativePath;
      },
    );

    // Comparing the contents of the file
    expect(
      generatedFile.readAsStringSync(),
      file.readAsStringSync(),
      reason: 'Contents do not match for file: $relativePath',
    );
  }

  // Verifying that the number of generated files matches the number of expected files
  expect(
    generatedFiles.length,
    expectedFiles.length,
    reason: 'Number of files does not match',
  );

  // Deleting the generated files
  Directory(generatedFolderPath).deleteSync(recursive: true);
}
