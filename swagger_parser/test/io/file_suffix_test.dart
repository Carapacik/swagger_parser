@TestOn('vm')
library;

import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/cli/output_writer.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/file_suffix';

Future<GenerationResult> _generate(String ext, GenerationConfig config) async =>
    await const SwaggerParserRunner().generate(
      await const FileSchemaSourceLoader().loadPath('$_base/open_api.$ext'),
      config: config,
    );

void main() {
  test('suffixes internal files and preserves public names for each backend', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final suffix in ['', '_generated', '.generated']) {
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult result = await _generate(
                ext,
                GenerationConfig(
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
              expect(
                files.keys,
                containsAll([
                  'transit_api.dart',
                  'exports.dart',
                  'stations/stations_client$suffix.dart',
                  'trips/trips_client$suffix.dart',
                  'stations/models/station$suffix.dart',
                  'stations/models/station_address$suffix.dart',
                  'stations/models/station_status$suffix.dart',
                ]),
              );
              expect(files['transit_api.dart'], contains('class TransitApi'));
              expect(
                files['exports.dart'],
                contains('stations/stations_client$suffix.dart'),
              );
              expect(
                files['exports.dart'],
                contains('stations/models/station$suffix.dart'),
              );
              expect(
                files['stations/models/station$suffix.dart'],
                matches(RegExp(r'class (?:const )?Station\b')),
              );
              expect(
                files['stations/models/station_address$suffix.dart'],
                matches(RegExp(r'class (?:const )?StationAddress\b')),
              );
              expect(
                files['stations/models/station_status$suffix.dart'],
                contains('enum StationStatus'),
              );
              for (final String path in files.keys.where(
                (p) => p != 'transit_api.dart' && p != 'exports.dart',
              )) {
                expect(path, endsWith('$suffix.dart'));
              }
              if (mode == ResponseMode.allStatuses) {
                expect(
                  files.keys,
                  contains('stations/stations_client_results$suffix.dart'),
                );
                expect(
                  files['stations/stations_client_results$suffix.dart'],
                  contains('class GetStationResult'),
                );
              }
              if (backend == HttpClientBackend.http) {
                expect(
                  files.keys,
                  contains('http_request_options$suffix.dart'),
                );
                if (mode == ResponseMode.firstSuccess) {
                  expect(files.keys, contains('http_response$suffix.dart'));
                  expect(
                    files['stations/stations_client$suffix.dart'],
                    contains('../http_response$suffix.dart'),
                  );
                }
              } else if (backend == HttpClientBackend.retrofit &&
                  mode == ResponseMode.firstSuccess) {
                expect(
                  files['stations/stations_client$suffix.dart'],
                  contains("part 'stations_client$suffix.g.dart'"),
                );
              }
              final String station =
                  files['stations/models/station$suffix.dart']!;
              if (serializer == DtoSerializer.freezed) {
                expect(station, contains("part 'station$suffix.freezed.dart'"));
              }
              if (serializer != DtoSerializer.plain) {
                expect(
                  station,
                  contains(
                    "part 'station$suffix.${serializer == DtoSerializer.dartMappable ? 'mapper' : 'g'}.dart'",
                  ),
                );
              }
            }
          }
        }
      }
    }
  });

  test(
    'reads defaults and input overrides and rejects unsafe suffixes',
    () async {
      for (final ext in ['json', 'yaml']) {
        for (final name in ['default', 'empty', 'enabled']) {
          final CliConfig config = await CliConfig.load(
            configPath: '$_base/$name.$ext',
          );
          expect(
            config.generation.fileSuffix,
            name == 'enabled' ? '_generated' : '',
          );
        }
        final List<CliConfig> inputs = await CliConfig.loadAll(
          configPath: '$_base/inputs.$ext',
        );
        expect(inputs.map((c) => c.generation.fileSuffix), [
          '_generated',
          '.generated',
          '',
        ]);
        for (final name in [
          'slash',
          'backslash',
          'parent',
          'space',
          'quote',
          'part',
          'freezed',
          'mapper',
          'nested_part',
          'extension',
          'number',
          'null',
        ]) {
          await expectLater(
            CliConfig.load(configPath: '$_base/invalid_$name.$ext'),
            throwsA(isA<FormatException>()),
          );
        }
        for (final suffix in ['.g', '.FREEZED', '/x', '../x', r'\x']) {
          await expectLater(
            _generate(ext, GenerationConfig(fileSuffix: suffix)),
            throwsA(isA<GenerationException>()),
          );
        }
      }
    },
  );

  test('replaces CLI-owned files after a suffix change', () async {
    final Directory dir = await Directory.systemTemp.createTemp('file_suffix_');
    addTearDown(() => dir.delete(recursive: true));
    await writeOutput(
      dir,
      (await _generate('yaml', const GenerationConfig())).files,
    );
    final custom = File('${dir.path}/custom.dart');
    await custom.writeAsString('// Application file.\n');
    final GenerationResult result = await _generate(
      'json',
      const GenerationConfig(fileSuffix: '_generated'),
    );
    await writeOutput(dir, result.files);
    expect(
      File('${dir.path}/stations/models/station.dart').existsSync(),
      isFalse,
    );
    expect(
      File('${dir.path}/stations/models/station_generated.dart').existsSync(),
      isTrue,
    );
    expect(await custom.readAsString(), '// Application file.\n');
    expect(await checkOutput(dir, result.files), isEmpty);
  });

  test('rejects collisions with the public facade', () async {
    await expectLater(
      _generate(
        'yaml',
        const GenerationConfig(
          fileSuffix: '_generated',
          rootApiClassName: 'HttpResponseGenerated',
          httpClient: HttpClientBackend.http,
          originalHttpResponse: true,
        ),
      ),
      throwsA(
        isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Duplicate output path'),
        ),
      ),
    );
  });
}
