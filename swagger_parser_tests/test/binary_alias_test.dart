@TestOn('vm')
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/binary_alias_driver.dart';
import 'support/consumer_matrix.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds binary aliases and File-named models on VM and web', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_binary_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String text) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      expect(
        result.exitCode,
        0,
        reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
      );
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    final folders = <String>[];
    for (final version in ['v2', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          if (!isFocusedConsumer(serializer, backend)) {
            continue;
          }
          final folder = '${version}_${serializer.name}_${backend.name}';
          folders.add(folder);
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult
            result = await const SwaggerParserRunner().generate(
              await const FileSchemaSourceLoader().loadPath(
                '../swagger_parser/test/fixtures/binary_types/$version.$ext',
              ),
              config: GenerationConfig(
                serializer: serializer,
                httpClient: backend,
              ),
            );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            expected ??= files;
            expect(files, expected);
            expect(files.values.join(), isNot(contains("'dart:io'")));
            expect(files.values.join(), contains('class FileInfo'));
            expect(
              files.values.join(),
              contains('Future<List<int>> download('),
            );
          }
          for (final MapEntry<String, String> file in expected!.entries) {
            await write('$folder/${file.key}', file.value);
          }
          await write(
            '${folder}_checks.dart',
            binaryAliasDriver(folder, backend),
          );
        }
      }
    }
    await write(
      'checks_test.dart',
      [
        "import 'package:test/test.dart';",
        for (final (i, folder) in folders.indexed)
          "import '${folder}_checks.dart' as check$i;",
        'void main() {',
        for (final (i, folder) in folders.indexed)
          "group('$folder', check$i.main);",
        '}',
      ].join('\n'),
    );
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '${dir.path}/checks_test.dart']);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '${dir.path}/checks_test.dart']);
    }
  });
}
