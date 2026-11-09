@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/file_suffix_driver.dart';

void main() {
  test('builds suffixed files with each serializer and HTTP client', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_suffix_');
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
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final suffix in ['_generated', '.generated']) {
            final folder =
                '${serializer.name}_${backend.name}_${mode.name}_${suffix == '_generated' ? 'snake' : 'dot'}';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await const FileSchemaSourceLoader().loadPath(
                  '../swagger_parser/test/fixtures/file_suffix/open_api.$ext',
                ),
                config: GenerationConfig(
                  serializer: serializer,
                  httpClient: backend,
                  responseMode: mode,
                  fileSuffix: suffix,
                  rootApiClassName: 'TransitApi',
                  originalHttpResponse: true,
                ),
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              expected ??= files;
              expect(files, expected);
            }
            for (final MapEntry<String, String> f in expected!.entries) {
              await write('$folder/${f.key}', f.value);
            }
            await write(
              '${folder}_test.dart',
              fileSuffixDriver(folder, backend, mode),
            );
          }
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', dir.path]);
  });
}
