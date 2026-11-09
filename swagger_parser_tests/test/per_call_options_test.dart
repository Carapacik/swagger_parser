@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/per_call_driver.dart';

void main() {
  test('builds and runs per-call options for each backend', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_calls_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String source) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
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
        final folder = '${backend.name}_${mode.name}';
        Map<String, String>? expected;
        for (final ext in ['json', 'yaml']) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await const FileSchemaSourceLoader().loadPath(
                  'test/fixtures/http/request_options/per_call_v3_2.$ext',
                ),
                config: GenerationConfig(
                  httpClient: backend,
                  responseMode: mode,
                  streamBinaryResponses: true,
                ),
              );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final f in result.files) f.relativePath: f.content,
          };
          expected ??= files;
          expect(files, expected);
        }
        for (final MapEntry<String, String> entry in expected!.entries) {
          await write('$folder/${entry.key}', entry.value);
        }
        await write(
          '${folder}_test.dart',
          perCallDriver(folder, backend, mode),
        );
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', '--timeout=10s', dir.path]);
  });
}
