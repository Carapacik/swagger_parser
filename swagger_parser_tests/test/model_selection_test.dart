@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';
import 'support/model_selection_driver.dart';

void main() {
  test('builds and calls selected models and parameters for each client', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_selection_');
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
    for (final family in ['v2', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final DtoSerializer serializer in DtoSerializer.values) {
            if (!isFocusedConsumer(serializer, backend)) {
              continue;
            }
            final folder =
                '${family}_${backend.name}_${mode.name}_${serializer.name}';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              const loader = FileSchemaSourceLoader();
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await loader.loadPath(
                  '../swagger_parser/test/fixtures/model_selection/$family.$ext',
                ),
                loader: loader,
                config: GenerationConfig(
                  httpClient: backend,
                  responseMode: mode,
                  serializer: serializer,
                  pruneUnusedModels: true,
                  applyParameterDefaults: true,
                  keepModels: [
                    '#/${family == 'v2' ? 'definitions' : 'components/schemas'}/AuditRecord',
                  ],
                  excludeParameters: const [
                    ParameterExclusion(name: 'x-trace-id', location: 'header'),
                    ParameterExclusion(
                      name: 'debug',
                      location: 'query',
                      paths: ['/stations/**'],
                      methods: ['GET'],
                    ),
                    ParameterExclusion(name: 'session', location: 'cookie'),
                  ],
                ),
              );
              expect(result.diagnostics.map((d) => d.code), [
                'excludedRequiredParameter',
              ]);
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
              selectionDriver(folder, backend, mode, family),
            );
          }
        }
      }
    }
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final (name, input, roots) in [
        (
          'unions',
          'union_titles/titles_v3_2',
          ['State', 'NamedStop', 'Contact'],
        ),
        ('tuples', 'extraction/tuples/tuple_v3_2', ['Envelope', 'Pair']),
        (
          'dynamic',
          'extraction/dynamic_references/dynamic_v3_2',
          ['Names', 'NumberTree'],
        ),
        ('swagger', 'unknown_values/unknown_v2_0', ['Stop', 'Status']),
        ('mapped', 'directional_mappings/directional_v3_2', <String>[]),
      ]) {
        final folder = '${name}_${serializer.name}';
        final CliConfig mapping = await CliConfig.load(
          configPath: '../swagger_parser/test/fixtures/directional_mappings/config_v3_2.yaml',
        );
        Map<String, String>? expected;
        for (final ext in ['json', 'yaml']) {
          const loader = FileSchemaSourceLoader();
          final GenerationResult
          result = await const SwaggerParserRunner().generate(
            await loader.loadPath(
              '../swagger_parser/test/fixtures/$input.$ext',
            ),
            loader: loader,
            config: GenerationConfig(
              serializer: serializer,
              pruneUnusedModels: true,
              typeMappings: name == 'mapped'
                  ? mapping.generation.typeMappings
                  : const [],
              operationFilters: OperationFilterConfig(
                includePaths: name == 'mapped' ? null : const [],
              ),
              unknownEnumValues: UnknownValueMode.preserve,
              unknownDiscriminatorValues: UnknownValueMode.preserve,
              keepModels: [
                for (final root in roots)
                  '#/${name == 'swagger' ? 'definitions' : 'components/schemas'}/$root',
              ],
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
        await write('${folder}_test.dart', selectionModelsDriver(folder, name));
      }
    }
    final String checks = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', checks]);
  });
}
