@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/api_metadata_driver.dart';
import 'support/consumer_matrix.dart';

void main() {
  test('builds public metadata and preserves extras across versions and clients', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_api_metadata_');
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
    for (final family in ['v2', 'v3_2', 'collisions', 'empty', 'filtered']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final ApiMetadataMode metadataMode in ApiMetadataMode.values) {
            final folder =
                '${family}_${backend.name}_${mode.name}_${metadataMode.name}';
            final bool special = [
              'collisions',
              'empty',
              'filtered',
            ].contains(family);
            final root = family == 'collisions' ? 'ApiMetadata' : 'TransitApi';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              const loader = FileSchemaSourceLoader();
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await loader.loadPath(
                  '../swagger_parser/test/fixtures/api_metadata/${family == 'empty' || family == 'filtered' ? 'v3_2' : family}.$ext',
                ),
                loader: loader,
                config: GenerationConfig(
                  rootApiClassName: root,
                  fileSuffix: special ? '' : '_generated',
                  apiMetadata: metadataMode,
                  generateDocs: false,
                  httpClient: backend,
                  responseMode: mode,
                  usePathForMethodNames: family == 'filtered',
                  operationFilters: OperationFilterConfig(
                    includePaths: switch (family) {
                      'empty' => [],
                      'filtered' => ['/stations/**'],
                      _ => null,
                    },
                  ),
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
              apiMetadataDriver(
                folder,
                family,
                backend,
                mode,
                metadataMode: metadataMode,
              ),
            );
          }
        }
      }
    }
    final String checks = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', checks]);
  });
}
