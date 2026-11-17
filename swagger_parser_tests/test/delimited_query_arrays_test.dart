@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';
import 'support/delimited_query_arrays_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('sends delimited arrays through each transport on VM and web', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_delimited_');
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
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      '../swagger_parser/test/fixtures/parameter_styles/styles.yaml',
    );
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final DelimitedQueryArrayExplodeMode mode in [
        DelimitedQueryArrayExplodeMode.join,
        DelimitedQueryArrayExplodeMode.repeat,
      ]) {
        final folder = '${backend.name}_${mode.name}';
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(
              source,
              config: GenerationConfig(
                httpClient: backend,
                delimitedQueryArrayExplode: mode,
              ),
            );
        expect(
          result.diagnostics.map((d) => d.code),
          unorderedEquals([
            'delimitedQueryArrayExplode',
            'delimitedQueryArrayExplode',
            'unsupportedClientOperation',
          ]),
        );
        for (final GeneratedFile file in result.files) {
          await write('$folder/${file.relativePath}', file.content);
        }
        await write(
          '${folder}_test.dart',
          delimitedQueryArraysDriver(folder, backend, mode),
        );
      }
    }
    final String checks = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', checks]);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '--concurrency=1', checks]);
    }
  });
}
