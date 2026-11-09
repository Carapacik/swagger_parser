@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/method_naming';

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
    await loader.loadPath('$_base/$family.$ext'),
    loader: loader,
    config: config,
  );
}

void main() {
  test('selects method names across versions and clients without changing routes', () async {
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final enabled in [false, true]) {
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final mapper = _Mapper();
              final GenerationResult result = await _generate(
                family,
                ext,
                GenerationConfig(
                  httpClient: backend,
                  responseMode: mode,
                  usePathForMethodNames: enabled,
                ),
                mapper,
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              expected ??= files;
              expect(files, expected);
              final List<DartClientOperation> operations = mapper
                  .model
                  .libraries
                  .expand((l) => l.operations)
                  .toList();
              expect(operations, hasLength(8));
              final Map<String, DartClientOperation> byPath = {
                for (final op in operations) op.path: op,
              };
              final DartClientOperation station = byPath['/stations/{id}']!;
              expect(
                station.name,
                enabled ? 'getStationsById' : 'lookupStation',
              );
              expect(station.method, 'GET');
              expect(station.parameters.single.wireName, 'id');
              expect(
                byPath['/a/{b}/c/{d}/{e}']!.name,
                enabled ? 'getAByBCByDAndE' : 'lookupNested',
              );
              expect(byPath['/health']!.name, 'getHealth');
              expect(
                byPath['/station-list']!.name,
                enabled ? 'getStationList' : 'lookupList',
              );
              expect(
                byPath['/station_list']!.name,
                enabled ? 'getStationList2' : 'lookupList2',
              );
              expect(
                byPath['/mounted/{id}']!.name,
                enabled ? 'getMountedById' : 'externalLookup',
              );
              if (enabled) {
                expect(byPath['/unicode']!.name, 'getUnicode');
              }
              final String source = files.values.join();
              expect(source, contains('class Station'));
              expect(
                source,
                contains(
                  'class ${enabled ? 'PostInline' : 'CreateInline'}Request',
                ),
              );
              expect(
                source,
                contains(
                  'class ${enabled ? 'PostInline' : 'CreateInline'}Response200',
                ),
              );
              if (mode == ResponseMode.allStatuses) {
                final stem = enabled ? 'GetStationsById' : 'LookupStation';
                expect(station.response.symbol, '${stem}Result');
                expect(station.variants['200']!.name, '${stem}200');
                expect(station.variants['200']!.type!.symbol, 'Station');
                expect(station.variants['404']!.name, '${stem}404');
                expect(
                  operations.map((op) => op.response.symbol).toSet(),
                  hasLength(8),
                );
              } else {
                expect(station.response.symbol, 'Station');
              }
              final ApiOperation input = mapper.api.operations.first;
              expect(input.operationId, 'lookupStation');
              expect(input.dartMethodNameCandidate, 'lookupStation');
              expect(input.dartPathMethodNameCandidate, 'getStationsById');
            }
          }
        }
      }
    }
  });

  test(
    'replaces selected names before result allocation and collision checks',
    () async {
      for (final enabled in [false, true]) {
        for (final ext in ['json', 'yaml']) {
          final mapper = _Mapper();
          await _generate(
            'v3_2',
            ext,
            GenerationConfig(
              usePathForMethodNames: enabled,
              responseMode: ResponseMode.allStatuses,
              naming: const NamingConfig(
                replaceRules: [
                  NameReplacementRule(
                    target: NamingTarget.methods,
                    pattern: '^(lookup|get)',
                    replacement: 'fetch',
                  ),
                ],
              ),
            ),
            mapper,
          );
          final Iterable<DartClientOperation> operations = mapper
              .model
              .libraries
              .expand((l) => l.operations);
          final DartClientOperation station = operations.firstWhere(
            (op) => op.path == '/stations/{id}',
          );
          expect(station.name, enabled ? 'fetchStationsById' : 'fetchStation');
          expect(
            station.response.symbol,
            enabled ? 'FetchStationsByIdResult' : 'FetchStationResult',
          );
          expect(
            operations.map((op) => op.name),
            containsAll(
              ['fetchList', 'fetchList2'].map(
                (name) =>
                    enabled ? name.replaceFirst('List', 'StationList') : name,
              ),
            ),
          );
        }
      }
    },
  );

  test(
    'reads the default and per-input overrides and rejects non-booleans',
    () async {
      for (final ext in ['json', 'yaml']) {
        for (final name in ['default', 'disabled', 'enabled']) {
          final CliConfig config = await CliConfig.load(
            configPath: '$_base/$name.$ext',
          );
          expect(config.generation.usePathForMethodNames, name == 'enabled');
        }
        final List<CliConfig> inputs = await CliConfig.loadAll(
          configPath: '$_base/inputs.$ext',
        );
        expect(inputs.first.generation.usePathForMethodNames, isTrue);
        expect(inputs.last.generation.usePathForMethodNames, isFalse);
        await expectLater(
          CliConfig.load(configPath: '$_base/invalid.$ext'),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );
}
