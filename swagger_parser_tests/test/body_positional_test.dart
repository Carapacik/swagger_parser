@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/body_positional_driver.dart';

void main() {
  test('builds and runs both body styles for each client', () async {
    final Directory dir = await Directory('test').createTemp('generated_body_');
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
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final ResponseMode mode in ResponseMode.values) {
        for (final positional in [false, true]) {
          final folder = '${backend.name}_${mode.name}_$positional';
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult
            result = await const SwaggerParserRunner().generate(
              await const FileSchemaSourceLoader().loadPath(
                '../swagger_parser/test/fixtures/body_positional/open_api_v3_2.$ext',
              ),
              config: GenerationConfig(
                httpClient: backend,
                responseMode: mode,
                bodyPositional: positional,
              ),
            );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            expected ??= files;
            expect(files, expected);
          }
          for (final MapEntry<String, String> file in expected!.entries) {
            await write('$folder/${file.key}', file.value);
          }
          await write(
            '${folder}_test.dart',
            bodyPositionalDriver(folder, backend, positional: positional),
          );
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', dir.path]);
  });
}
