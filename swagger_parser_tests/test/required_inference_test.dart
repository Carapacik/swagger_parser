@TestOn('vm')
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/required_inference_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds required inference and both nullable APIs across serializers', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_required_inference_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String content) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult run = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')}: ${(run.stdout as String).trim().split('\n').last}',
      );
      expect(
        run.exitCode,
        0,
        reason: '${args.join(' ')}\n${run.stdout}\n${run.stderr}',
      );
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    final folders = <String>[];
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final infer in [false, true]) {
          for (final records in [false, true]) {
            final folder = '${version}_${serializer.name}_${infer}_$records';
            folders.add(folder);
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              const loader = FileSchemaSourceLoader();
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await loader.loadPath(
                  '../swagger_parser/test/fixtures/required_inference/$version.$ext',
                ),
                loader: loader,
                config: GenerationConfig(
                  serializer: serializer,
                  inferMissingRequired: infer,
                  usePresenceRecords: records,
                ),
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              baseline ??= files;
              expect(files, baseline);
            }
            for (final MapEntry<String, String> file in baseline!.entries) {
              await write('$folder/${file.key}', file.value);
            }
            await write(
              '${folder}_checks.dart',
              requiredInferenceDriver(
                folder,
                version,
                infer: infer,
                records: records,
              ),
            );
          }
        }
      }
    }
    await write(
      'checks_test.dart',
      [
        "import 'package:test/test.dart';",
        for (final (index, folder) in folders.indexed)
          "import '${folder}_checks.dart' as check$index;",
        'void main() {',
        for (final (index, folder) in folders.indexed)
          "group('$folder', check$index.main);",
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
