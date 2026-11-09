@TestOn('vm')
library;

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

const _naming = NamingConfig(
  replaceRules: [
    NameReplacementRule(
      target: NamingTarget.clients,
      pattern: '^(Internal|Public)',
      replacement: '',
    ),
    NameReplacementRule(
      target: NamingTarget.clients,
      pattern: '^Erase.*',
      replacement: '',
    ),
  ],
);

Future<GenerationResult> _generate(
  String family,
  String ext,
  GenerationConfig config,
  _Mapper mapper,
) async => await SwaggerParserRunner(mapper: mapper).generate(
  await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/tag_grouping/$family.$ext',
  ),
  config: config,
);

List<DartLibraryModel> _clients(_Mapper mapper) => mapper.model.libraries
    .where((library) => library.operations.isNotEmpty)
    .toList();

void main() {
  test('merges normalized tags and retains each operation', () async {
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          Map<String, String>? baseline;
          for (final ext in ['json', 'yaml']) {
            final mapper = _Mapper();
            final GenerationResult result = await _generate(
              family,
              ext,
              GenerationConfig(
                httpClient: backend,
                responseMode: mode,
                naming: _naming,
              ),
              mapper,
            );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            baseline ??= files;
            expect(files, baseline);
            final List<DartLibraryModel> clients = _clients(mapper);
            expect(clients.map((c) => c.clientName).toSet(), {
              'StationClient',
              'StationInfoClient',
              'StationsClient',
              'TripsClient',
              'ApiClient',
              'ApiClient2',
            });
            expect(clients.expand((c) => c.operations), hasLength(9));
            final DartLibraryModel station = clients.singleWhere(
              (c) => c.clientName == 'StationClient',
            );
            expect(station.operations.map((o) => o.name), [
              'getStation',
              'getStation2',
            ]);
            final DartClientOperation first = station.operations.first;
            final DartClientOperation second = station.operations.last;
            expect(first.path, '/stations/{id}');
            expect(first.parameters.single.wireName, 'id');
            expect(second.path, '/codes/{code}');
            expect(second.parameters.single.wireName, 'code');
            if (mode == ResponseMode.allStatuses) {
              expect(first.response.symbol, 'GetStationResult');
              expect(second.response.symbol, 'GetStation2Result');
              expect(first.variants['200']!.name, 'GetStation200');
              expect(second.variants['200']!.name, 'GetStation2200');
              expect(first.variants['200']!.type!.symbol, 'Station');
              expect(second.variants['200']!.type!.symbol, 'Lookup');
            } else {
              expect(first.response.symbol, 'Station');
              expect(second.response.symbol, 'Lookup');
            }
            expect(files['station/models/station.dart'], isNotNull);
            expect(files['station/models/lookup.dart'], isNotNull);
            expect(files['trips/models/station.dart'], isNull);
            expect(
              clients
                  .singleWhere((c) => c.clientName == 'ApiClient')
                  .operations
                  .single
                  .path,
              '/health',
            );
            expect(
              clients
                  .singleWhere((c) => c.clientName == 'ApiClient2')
                  .operations
                  .single
                  .path,
              '/tagged-api',
            );
            expect(
              clients
                  .singleWhere((c) => c.clientName == 'StationsClient')
                  .operations
                  .map((o) => o.path),
              ['/internal', '/public'],
            );
            expect(mapper.api.operations.first.tags, ['station', 'Secondary']);
            expect(mapper.api.operations.first.operationId, 'get-station');
            expect(mapper.api.operations[2].operationId, 'get_station');
          }
        }
      }
    }
  });

  test(
    'applies method replacements before allocating merged result names',
    () async {
      for (final ext in ['json', 'yaml']) {
        final mapper = _Mapper();
        final GenerationResult result = await _generate(
          'v3_2',
          ext,
          const GenerationConfig(
            responseMode: ResponseMode.allStatuses,
            naming: NamingConfig(
              replaceRules: [
                NameReplacementRule(
                  target: NamingTarget.methods,
                  pattern: r'^get[-_]station$',
                  replacement: 'lookupStation',
                ),
              ],
            ),
          ),
          mapper,
        );
        expect(result.diagnostics, isEmpty);
        final List<DartClientOperation> operations = _clients(mapper)
            .singleWhere((c) => c.clientName == 'StationClient')
            .operations;
        expect(operations.map((o) => o.name), [
          'lookupStation',
          'lookupStation2',
        ]);
        expect(operations.map((o) => o.response.symbol), [
          'LookupStationResult',
          'LookupStation2Result',
        ]);
      }
    },
  );

  test('filters original tags before grouping and model ownership', () async {
    for (final ext in ['json', 'yaml']) {
      for (final (filter, paths, owner) in [
        (
          const OperationFilterConfig(includeTags: ['Station']),
          ['/codes/{code}'],
          'models',
        ),
        (
          const OperationFilterConfig(includeTags: ['Secondary']),
          ['/stations/{id}'],
          'station/models',
        ),
        (
          const OperationFilterConfig(excludeTags: ['station']),
          ['/codes/{code}'],
          'trips/models',
        ),
      ]) {
        final mapper = _Mapper();
        final GenerationResult result = await _generate(
          'v3_2',
          ext,
          GenerationConfig(operationFilters: filter),
          mapper,
        );
        expect(result.diagnostics, isEmpty);
        final DartLibraryModel station = _clients(mapper)
            .singleWhere((c) => c.clientName == 'StationClient');
        expect(station.operations.map((o) => o.path), paths);
        expect(station.operations.single.name, 'getStation');
        expect(
          result.files.any((f) => f.relativePath == '$owner/station.dart'),
          isTrue,
        );
        expect(
          _clients(mapper).any((c) => c.clientName == 'SecondaryClient'),
          isFalse,
        );
      }
    }
  });

  test(
    'keeps fallback, empty names, and protective collisions separate',
    () async {
      for (final ext in ['json', 'yaml']) {
        final mapper = _Mapper();
        final GenerationResult result = await _generate(
          'collisions',
          ext,
          const GenerationConfig(naming: _naming),
          mapper,
        );
        expect(result.diagnostics, isEmpty);
        final List<DartLibraryModel> clients = _clients(mapper);
        expect(clients, hasLength(12));
        expect(
          clients
              .singleWhere((c) => c.clientName == 'StationClient2')
              .operations,
          hasLength(2),
        );
        final Iterable<DartLibraryModel> edges = clients.where(
          (c) => c.operations.any((o) => o.path.startsWith('/edge')),
        );
        expect(edges, hasLength(6));
        expect(edges.map((c) => c.clientName).toSet(), hasLength(6));
        expect(edges.every((c) => c.operations.length == 1), isTrue);
        expect(
          result.files.map((f) => f.relativePath).toSet(),
          hasLength(result.files.length),
        );
      }
    },
  );

  test('rejects duplicate source operation IDs before grouping', () async {
    for (final ext in ['json', 'yaml']) {
      await expectLater(
        _generate('duplicate_ids', ext, const GenerationConfig(), _Mapper()),
        throwsA(isA<GenerationException>()),
      );
    }
  });
}
