import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/utils/file_utils.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<void> e2eTest(
  String testName,
  Generator Function(String schemaContent) getGenerator,
) async {
  final testFolder = p.join('test', 'e2e', 'tests', testName);
  final schemaPath = p.join(testFolder, 'openapi.json');
  final expectedFolderPath = p.join(testFolder, 'expected_files');
  final configFile = schemaFile(schemaPath);
  final schemaContent = configFile!.readAsStringSync();

  final generator = getGenerator.call(schemaContent);

  final generatedFiles = await generator.generateContent();

  // Получаем список всех файлов из expectedFolderPath
  final expectedFiles = Directory(expectedFolderPath)
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();

  for (final file in expectedFiles) {
    final relativePath =
        p.relative(file.path, from: expectedFolderPath).replaceAll(r'\', '/');

    final generatedFile = generatedFiles.firstWhere(
      (gFile) => gFile.name == relativePath,
      orElse: () => throw Exception(
        'File not found in generated content: $relativePath',
      ),
    );

    // Сравниваем содержимое файла
    final fileContent = file.readAsStringSync();
    expect(
      generatedFile.contents,
      fileContent,
      reason: 'Contents do not match for file: $relativePath',
    );
  }

  // Проверяем, что количество сгенерированных файлов совпадает с количеством ожидаемых файлов
  expect(
    generatedFiles.length,
    expectedFiles.length,
    reason: 'Number of files does not match',
  );
}
