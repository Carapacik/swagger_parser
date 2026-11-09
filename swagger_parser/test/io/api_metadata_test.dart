@TestOn('vm')
library;

import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/cli/output_writer.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

final class _Mapper() implements DartModelMapper {
  late ApiDefinition api;
  late DartGenerationModel model;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) {
    this.api = api;
    return model = const DartModelMapper().map(api, config);
  }
}

Future<GenerationResult> _generate(
  String family,
  String ext,
  GenerationConfig config,
  _Mapper mapper,
) async {
  const loader = FileSchemaSourceLoader();
  return await SwaggerParserRunner(mapper: mapper).generate(
    await loader.loadPath('test/fixtures/api_metadata/$family.$ext'),
    loader: loader,
    config: config,
  );
}

void main() {
  test('preserves public metadata across versions and clients', () async {
    for (final (family, version) in [
      ('v2', '2.0'),
      ('v3_0', '3.0.4'),
      ('v3_1', '3.1.2'),
      ('v3_2', '3.2.1'),
    ]) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final ApiMetadataMode metadataMode in ApiMetadataMode.values) {
            final enabled = metadataMode == ApiMetadataMode.generateAndAttach;
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              final mapper = _Mapper();
              final GenerationResult result = await _generate(
                family,
                ext,
                GenerationConfig(
                  httpClient: backend,
                  responseMode: mode,
                  apiMetadata: metadataMode,
                  generateDocs: false,
                ),
                mapper,
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final DartFacadeModel facade = mapper.model.libraries
                  .singleWhere((l) => l.facade != null)
                  .facade!;
              expect(facade.title, "Transit '\$api'\nAPI");
              expect(facade.version, r'2026.11+$build');
              expect(facade.specVersion, version);
              if (metadataMode == ApiMetadataMode.none) {
                expect(facade.metadataTypeName, isNull);
                expect(facade.operationConstants, isEmpty);
                expect(
                  mapper.model.libraries.any(
                    (l) =>
                        l.apiMetadata ||
                        l.metadataOperations.isNotEmpty ||
                        l.attachOperationMetadata,
                  ),
                  isFalse,
                );
                expect(files['api.dart'], isNot(contains(' operations =')));
                expect(
                  files.keys.any((path) => path.endsWith('_metadata.dart')),
                  isFalse,
                );
                expect(
                  files.values.join(),
                  isNot(contains("'openapi.operation':")),
                );
                continue;
              }
              expect(facade.operationConstants, hasLength(10));
              expect(facade.operationConstants.take(3), [
                'StationClientMetadata.getStation',
                'TripsClientMetadata.trips',
                'StationClientMetadata.getStation2',
              ]);
              final List<DartClientOperation> metadata = mapper.model.libraries
                  .expand((l) => l.metadataOperations)
                  .toList();
              final DartClientOperation first = metadata.singleWhere(
                (o) => o.path == '/stations/{id}',
              );
              expect(first.operationId, 'get-station');
              expect(first.tags, ['station', 'Secondary', r"Quoted '$tag'"]);
              expect(
                first.externalDocsUrl,
                r"https://example.test/docs?q=$id&name='station'",
              );
              expect(first.summary, isNull);
              expect(
                metadata.singleWhere((o) => o.path == '/health').operationId,
                isNull,
              );
              expect(
                metadata
                    .singleWhere((o) => o.path == '/mounted')
                    .externalDocsUrl,
                'https://example.test/mounted',
              );
              expect(mapper.api.operations.last.path, '/mounted');
              expect(
                metadata.singleWhere((o) => o.path == '/info-one').deprecated,
                isTrue,
              );
              final Iterable<DartLibraryModel> clients = mapper.model.libraries
                  .where((l) => l.operations.isNotEmpty);
              expect(
                clients.every((l) => l.attachOperationMetadata == enabled),
                isTrue,
              );
              expect(
                files['api_metadata.dart'],
                contains('final class OperationMetadata'),
              );
              expect(
                files['station/station_client_metadata.dart'],
                contains('static const getStation2'),
              );
              expect(
                files.values.join().contains("'openapi.operation':"),
                enabled,
              );
              expect(
                files['station/station_client.dart'],
                isNot(contains('Find a station')),
              );
            }
          }
        }
      }
    }
  });

  test(
    'keeps source IDs when names change and filters the operation list',
    () async {
      for (final ext in ['json', 'yaml']) {
        final mapper = _Mapper();
        await _generate(
          'v3_2',
          ext,
          const GenerationConfig(
            apiMetadata: ApiMetadataMode.generate,
            usePathForMethodNames: true,
            operationFilters: OperationFilterConfig(
              includePaths: ['/stations/**', '/mounted'],
            ),
            naming: NamingConfig(
              replaceRules: [
                NameReplacementRule(
                  target: NamingTarget.methods,
                  pattern: '^get',
                  replacement: 'fetch',
                ),
              ],
            ),
          ),
          mapper,
        );
        final DartFacadeModel facade = mapper.model.libraries
            .singleWhere((l) => l.facade != null)
            .facade!;
        expect(facade.operationConstants, [
          'StationClientMetadata.fetchStationsById',
          'StationClientMetadata.fetchMounted',
        ]);
        final DartClientOperation first = mapper.model.libraries
            .expand((l) => l.metadataOperations)
            .first;
        expect(first.operationId, 'get-station');
        expect(first.path, '/stations/{id}');
        final empty = _Mapper();
        await _generate(
          'v3_2',
          ext,
          const GenerationConfig(
            apiMetadata: ApiMetadataMode.generate,
            operationFilters: OperationFilterConfig(includePaths: []),
          ),
          empty,
        );
        expect(
          empty.model.libraries
              .singleWhere((l) => l.facade != null)
              .facade!
              .operationConstants,
          isEmpty,
        );
        expect(empty.model.libraries.where((l) => l.apiMetadata), hasLength(1));
      }
    },
  );

  test('allocates metadata type and file names around schema and facade collisions', () async {
    for (final ext in ['json', 'yaml']) {
      final mapper = _Mapper();
      final GenerationResult result = await _generate(
        'collisions',
        ext,
        const GenerationConfig(
          rootApiClassName: 'ApiMetadata',
          apiMetadata: ApiMetadataMode.generateAndAttach,
        ),
        mapper,
      );
      expect(result.diagnostics, isEmpty);
      final DartFacadeModel facade = mapper.model.libraries
          .singleWhere((l) => l.facade != null)
          .facade!;
      expect(facade.metadataTypeName, 'OperationMetadata2');
      final Iterable<DartLibraryModel> clients = mapper.model.libraries.where(
        (l) => l.operations.isNotEmpty,
      );
      expect(
        clients.map((l) => l.metadataTypeName),
        everyElement('OperationMetadata2'),
      );
      expect(
        clients.map((l) => l.metadataTypePath),
        everyElement('api_metadata2.dart'),
      );
      expect(facade.metadataNames, contains('StationClientMetadata2'));
      expect(
        result.files.map((f) => f.relativePath).toSet(),
        hasLength(result.files.length),
      );
      expect(
        result.files.any((f) => f.relativePath == 'api_metadata2.dart'),
        isTrue,
      );
    }
  });

  test(
    'omits skipped operations and protects facade metadata fields',
    () async {
      for (final ext in ['json', 'yaml']) {
        final mapper = _Mapper();
        final GenerationResult result = await _generate(
          'unsupported',
          ext,
          const GenerationConfig(
            apiMetadata: ApiMetadataMode.generate,
            naming: NamingConfig(
              replaceRules: [
                NameReplacementRule(
                  target: NamingTarget.clients,
                  pattern: '.+',
                  replacement: 'Operations',
                ),
              ],
            ),
          ),
          mapper,
        );
        expect(result.diagnostics.map((d) => d.code), [
          'unsupportedClientOperation',
        ]);
        expect(mapper.api.operations, hasLength(11));
        final DartFacadeModel facade = mapper.model.libraries
            .singleWhere((l) => l.facade != null)
            .facade!;
        expect(facade.operationConstants, hasLength(10));
        expect(facade.clients.keys, contains('operations2'));
        expect(
          mapper.model.libraries
              .expand((l) => l.metadataOperations)
              .any((o) => o.path == '/unsupported'),
          isFalse,
        );
      }
    },
  );

  test('removes generated metadata files when switching to none', () async {
    final Directory dir = await Directory.systemTemp.createTemp(
      'metadata_modes_',
    );
    addTearDown(() => dir.delete(recursive: true));
    final GenerationResult generated = await _generate(
      'v3_2',
      'json',
      const GenerationConfig(apiMetadata: ApiMetadataMode.generateAndAttach),
      _Mapper(),
    );
    await writeOutput(dir, generated.files);
    final appFile = File('${dir.path}/custom_metadata.dart');
    await appFile.writeAsString('// Application metadata.\n');
    expect(File('${dir.path}/api_metadata.dart').existsSync(), isTrue);
    final GenerationResult disabled = await _generate(
      'v3_2',
      'yaml',
      const GenerationConfig(),
      _Mapper(),
    );
    await writeOutput(dir, disabled.files);
    expect(File('${dir.path}/api_metadata.dart').existsSync(), isFalse);
    expect(
      File('${dir.path}/station/station_client_metadata.dart').existsSync(),
      isFalse,
    );
    expect(await appFile.readAsString(), '// Application metadata.\n');
    expect(await checkOutput(dir, disabled.files), isEmpty);
  });

  test(
    'reads metadata defaults and input overrides from JSON and YAML',
    () async {
      for (final ext in ['json', 'yaml']) {
        for (final name in [
          'default',
          'none',
          'generate',
          'generate_and_attach',
        ]) {
          final CliConfig config = await CliConfig.load(
            configPath: 'test/fixtures/api_metadata/$name.$ext',
          );
          expect(config.generation.apiMetadata, switch (name) {
            'generate' => ApiMetadataMode.generate,
            'generate_and_attach' => ApiMetadataMode.generateAndAttach,
            _ => ApiMetadataMode.none,
          });
        }
        final List<CliConfig> inputs = await CliConfig.loadAll(
          configPath: 'test/fixtures/api_metadata/inputs.$ext',
        );
        expect(inputs.map((c) => c.generation.apiMetadata), [
          ApiMetadataMode.generateAndAttach,
          ApiMetadataMode.generate,
          ApiMetadataMode.none,
        ]);
        for (final name in ['invalid', 'invalid_bool', 'old_key']) {
          await expectLater(
            CliConfig.load(configPath: 'test/fixtures/api_metadata/$name.$ext'),
            throwsA(isA<FormatException>()),
          );
        }
      }
    },
  );
}
