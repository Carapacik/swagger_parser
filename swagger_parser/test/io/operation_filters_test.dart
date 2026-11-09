@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/dart/operation_filter.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/operation_filters';

Future<GenerationResult> _generate(
  String version,
  String format,
  OperationFilterConfig filters, {
  HttpClientBackend backend = HttpClientBackend.retrofit,
  String input = 'routes',
}) async {
  const loader = FileSchemaSourceLoader();
  return await const SwaggerParserRunner().generate(
    await loader.loadPath('$_base/${input}_v$version.$format'),
    loader: loader,
    config: GenerationConfig(operationFilters: filters, httpClient: backend),
  );
}

void main() {
  test(
    'filters all versions and backends without pruning named models',
    () async {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final CliConfig config = await CliConfig.load(
              configPath: '$_base/config.$ext',
            );
            final GenerationResult result = await _generate(
              version,
              ext,
              config.generation.operationFilters,
              backend: backend,
            );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            expected ??= files;
            expect(files, expected);
            expect(
              files.keys,
              containsAll([
                'stations/stations_client.dart',
                'public/public_client.dart',
                'stations/models/station.dart',
                'stations/models/status.dart',
                'models/secret.dart',
                'models/unused.dart',
                'models/unused_detail.dart',
                'models/unused_enum.dart',
              ]),
            );
            final String source = files.values.join();
            for (final method in [
              'listStations',
              'getStation',
              'getHistory',
              'getEntry',
            ]) {
              expect(source, contains('$method('));
            }
            for (final method in [
              'getTrips',
              'createStation',
              'getPrivate',
              'getOther',
              'getUpper',
              'getHealth',
            ]) {
              expect(source, isNot(contains('$method(')));
            }
            expect(source, isNot(contains('CreateStation200')));
            expect(files['api.dart'], isNot(contains('InternalClient')));
            expect(files['api.dart'], isNot(contains('TripsClient')));
            expect(files['exports.dart'], contains('models/unused_enum.dart'));
          }
        }
      }
    },
  );

  test(
    'matches literal paths and segment globs with exclusion priority',
    () async {
      const loader = FileSchemaSourceLoader();
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await loader.loadPath(
            '$_base/routes_v$version.$ext',
          );
          final OpenApiDocument document = const OpenApiParser().parse(source);
          final ReferenceGraph graph = await const OpenApiReferenceResolver()
              .resolve(document);
          final ApiDefinition api = const ApiDefinitionExtractor().extract(
            document,
            graph,
          );
          Set<String> ids(OperationFilterConfig filters) => selectOperations(
            api.operations,
            filters,
          ).map((op) => op.operationId!).toSet();
          expect(ids(const OperationFilterConfig()), hasLength(14));
          expect(ids(const OperationFilterConfig(includePaths: [])), isEmpty);
          expect(ids(const OperationFilterConfig(includeTags: [])), isEmpty);
          expect(
            ids(const OperationFilterConfig(includePaths: ['/stations'])),
            {'listStations', 'createStation'},
          );
          expect(
            ids(const OperationFilterConfig(includePaths: ['/stations/{id}'])),
            {'getStation'},
          );
          expect(
            ids(
              const OperationFilterConfig(includePaths: ['/stations/{other}']),
            ),
            isEmpty,
          );
          expect(
            ids(const OperationFilterConfig(includePaths: ['/stations/*'])),
            {'getStation', 'getPrivate'},
          );
          expect(
            ids(const OperationFilterConfig(includePaths: ['/stations/**'])),
            {
              'listStations',
              'createStation',
              'getStation',
              'getPrivate',
              'getHistory',
              'getEntry',
            },
          );
          expect(
            ids(
              const OperationFilterConfig(
                includePaths: ['/stations/**/history'],
              ),
            ),
            {'getHistory'},
          );
          expect(
            ids(const OperationFilterConfig(includePaths: ['/**'])),
            hasLength(14),
          );
          expect(ids(const OperationFilterConfig(includePaths: ['/'])), {
            'getRoot',
          });
          expect(
            ids(
              const OperationFilterConfig(
                includePaths: ['/reports/v1.0+stats'],
              ),
            ),
            {'getLiteral'},
          );
          expect(
            ids(
              const OperationFilterConfig(
                includePaths: ['/health', '/metrics'],
              ),
            ),
            {'getHealth', 'getMetrics'},
          );
          expect(ids(const OperationFilterConfig(includeTags: ['public'])), {
            'getUpper',
          });
          expect(
            ids(
              const OperationFilterConfig(includeTags: ['Stations', 'Trips']),
            ),
            {'listStations', 'getStation', 'getTrips'},
          );
          expect(
            ids(
              const OperationFilterConfig(
                includePaths: ['/stations/**'],
                includeTags: ['Public'],
                excludeTags: ['Internal'],
                excludePaths: ['/stations/{id}/**'],
              ),
            ),
            {'listStations'},
          );
          expect(
            ids(
              const OperationFilterConfig(
                excludeTags: ['Public', 'public', 'Reports', 'Trips'],
              ),
            ),
            {'getHealth', 'getMetrics', 'getRoot'},
          );
          expect(
            ids(
              const OperationFilterConfig(
                includePaths: ['/**'],
                excludePaths: ['/**'],
              ),
            ),
            isEmpty,
          );
        }
      }
    },
  );

  test('retains DTOs and exports when all operations are excluded', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          final GenerationResult result = await _generate(
            version,
            ext,
            const OperationFilterConfig(includePaths: []),
            backend: backend,
          );
          final Map<String, String> files = {
            for (final f in result.files) f.relativePath: f.content,
          };
          expect(
            files.keys,
            containsAll([
              'api.dart',
              'exports.dart',
              'models/station.dart',
              'models/status.dart',
              'models/unused_detail.dart',
            ]),
          );
          expect(
            files.keys.where((path) => path.endsWith('_client.dart')),
            isEmpty,
          );
          expect(files.values.join(), isNot(contains('CreateStation200')));
        }
      }
    }
  });

  test(
    'keeps first-tag grouping and moves ownership after selection',
    () async {
      final GenerationResult all = await _generate(
        '3_2',
        'yaml',
        const OperationFilterConfig(),
      );
      expect(
        all.files.map((f) => f.relativePath),
        contains('trips/models/station.dart'),
      );
      final GenerationResult public = await _generate(
        '3_2',
        'yaml',
        const OperationFilterConfig(includeTags: ['Public']),
      );
      final Iterable<String> paths = public.files.map((f) => f.relativePath);
      expect(paths, contains('stations/models/station.dart'));
      expect(paths, contains('internal/internal_client.dart'));
      expect(paths, isNot(contains('trips/trips_client.dart')));
    },
  );

  test(
    'matches mounted external Path Items and validates excluded routes',
    () async {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final ext in ['json', 'yaml']) {
          final GenerationResult result = await _generate(
            version,
            ext,
            const OperationFilterConfig(
              includePaths: ['/mounted/*'],
              includeTags: ['Public'],
            ),
            input: 'mounted',
          );
          expect(
            result.files.map((f) => f.content).join(),
            contains('externalRoute('),
          );
          await expectLater(
            _generate(
              version,
              ext,
              const OperationFilterConfig(includePaths: []),
              input: 'invalid',
            ),
            throwsA(isA<GenerationException>()),
          );
        }
      }
    },
  );

  test(
    'reads null and empty includes and rejects invalid CLI filters',
    () async {
      for (final ext in ['json', 'yaml']) {
        final CliConfig all = await CliConfig.load(
          configPath: '$_base/all.$ext',
        );
        expect(all.generation.operationFilters.includePaths, isNull);
        expect(all.generation.operationFilters.includeTags, isNull);
        final CliConfig none = await CliConfig.load(
          configPath: '$_base/none.$ext',
        );
        expect(none.generation.operationFilters.includePaths, isEmpty);
        expect(none.generation.operationFilters.includeTags, isEmpty);
        for (final name in [
          'relative',
          'partial',
          'tag_number',
          'exclude_null',
          'scalar',
          'key',
        ]) {
          await expectLater(
            CliConfig.load(configPath: '$_base/bad_$name.$ext'),
            throwsA(isA<FormatException>()),
          );
        }
      }
      for (final pattern in ['stations', '/station*', '/***', '/**suffix']) {
        expect(
          () => selectOperations(
            [],
            OperationFilterConfig(excludePaths: [pattern]),
          ),
          throwsA(isA<GenerationException>()),
        );
      }
    },
  );
}
