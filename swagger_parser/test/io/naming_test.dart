@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _naming = NamingConfig(
  preserveSchemaCasing: true,
  replaceRules: [
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'Dto$',
      replacement: '',
    ),
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'^Aboba$',
      replacement: 'Station',
    ),
    NameReplacementRule(
      target: NamingTarget.clients,
      pattern: '^(Internal|Public)',
      replacement: '',
    ),
    NameReplacementRule(
      target: NamingTarget.methods,
      pattern: '^lookup',
      replacement: 'get',
    ),
    NameReplacementRule(
      target: NamingTarget.enumValues,
      pattern: '^status_',
      replacement: '',
    ),
  ],
);

Future<Map<String, String>> _generate(
  String version,
  String extension,
  GenerationConfig config,
) async {
  final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/naming/naming_v$version.$extension',
  );
  final GenerationResult result = await const SwaggerParserRunner().generate(
    source,
    config: config,
  );
  expect(result.diagnostics, isEmpty);
  return {for (final file in result.files) file.relativePath: file.content};
}

void main() {
  test('renames four categories in all versions and response modes', () async {
    for (final ResponseMode mode in ResponseMode.values) {
      final config = GenerationConfig(
        rootApiClassName: 'TransitApi',
        fallbackClientName: 'CommonClient',
        naming: _naming,
        responseMode: mode,
      );
      Map<String, String>? baseline;
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final extension in ['json', 'yaml']) {
          final Map<String, String> files = await _generate(
            version,
            extension,
            config,
          );
          final Map<String, String> comparable = {...files}
            ..remove('transit_api.dart');
          baseline ??= comparable;
          expect(comparable, baseline);
          final String client = files['stations/stations_client.dart']!;
          expect(client, contains('getStation('));
          expect(client, contains('required String stationId'));
          expect(files['stations2/stations_client2.dart'], isNull);
          expect(client, contains('getStationOther('));
          expect(
            files['stations/models/station.dart'],
            contains('class Station'),
          );
          expect(
            files['stations/models/station.dart'],
            contains('stationName'),
          );
          expect(
            files['stations/models/station.dart'],
            contains('"station_name"'),
          );
          expect(files['stations/models/status.dart'], contains('active'));
          expect(
            files['stations/models/status.dart'],
            contains('"status_active"'),
          );
          expect(files['stations/models/status.dart'], contains('values2'));
          expect(files['stations/models/status.dart'], contains('fromJson2'));
          expect(
            files['models/k_user_status.dart'],
            contains('enum kUserStatus'),
          );
          expect(
            files['models/xml_http_request.dart'],
            contains('class XMLHttpRequest'),
          );
          expect(
            files['models/xml_http_request2.dart'],
            contains('class XmlHttpRequest'),
          );
          expect(files['models/class2.dart'], contains('class class2'));
          expect(files['models/private.dart'], contains('class private'));
          expect(
            files['transit_api.dart'],
            contains('clients.CommonClient common'),
          );
          final String fallback = files['default_client/common_client.dart']!;
          expect(fallback, contains('getAByBCByDAndE('));
          expect(fallback, contains('health('));
          expect(
            files['exports.dart'],
            contains("'stations/models/station.dart'"),
          );
          if (mode == ResponseMode.allStatuses) {
            final String results =
                files['stations/stations_client_results.dart']!;
            expect(client, contains('Future<GetStationResult>'));
            expect(results, contains('sealed class GetStationResult'));
            expect(results, contains('class GetStation200'));
            expect(results, contains('class GetStation204'));
            expect(results, contains('class GetStation404'));
            expect(results, contains('models.Station value'));
            expect(results, isNot(contains('LookupStation')));
          } else {
            expect(client, contains('Uri.encodeComponent(stationId)'));
            expect(client, contains('"/stations/"'));
            expect(client, contains('Future<Station?> getStation('));
            expect(
              files.keys.where((p) => p.endsWith('_results.dart')),
              isEmpty,
            );
          }
        }
      }
    }
  });

  test('keeps default names and literal replacements', () async {
    final Map<String, String> defaults = await _generate(
      '3_2',
      'json',
      const GenerationConfig(),
    );
    expect(defaults['default_client/api_client.dart'], isNotNull);
    expect(defaults['internal_stations/models/aboba_dto.dart'], isNotNull);
    expect(defaults['models/k_user_status.dart'], contains('enum KUserStatus'));
    final Map<String, String> literal = await _generate(
      '3_2',
      'yaml',
      const GenerationConfig(
        naming: NamingConfig(
          replaceRules: [
            NameReplacementRule(
              target: NamingTarget.methods,
              pattern: '^(lookup)',
              replacement: r'$1_',
            ),
          ],
        ),
      ),
    );
    expect(
      literal['internal_stations/internal_stations_client.dart'],
      contains('field1Station('),
    );
  });

  test('keeps groups with empty replacement names separate', () async {
    const config = GenerationConfig(
      rootApiClassName: 'CommonClient',
      fallbackClientName: 'CommonClient',
      naming: NamingConfig(
        replaceRules: [
          NameReplacementRule(
            target: NamingTarget.models,
            pattern: '.+',
            replacement: 'String',
          ),
          NameReplacementRule(
            target: NamingTarget.methods,
            pattern: '.+',
            replacement: 'fromJson',
          ),
          NameReplacementRule(
            target: NamingTarget.clients,
            pattern: '.+',
            replacement: '',
          ),
          NameReplacementRule(
            target: NamingTarget.enumValues,
            pattern: '.+',
            replacement: '',
          ),
        ],
      ),
    );
    final Map<String, String> files = await _generate('3_2', 'json', config);
    expect(files, await _generate('3_2', 'yaml', config));
    expect(files['default_client/common_client2.dart'], contains('fromJson2('));
    expect(files['default_client/common_client2.dart'], contains('fromJson3('));
    expect(files['client/client.dart'], isNotNull);
    expect(files['client2/client2.dart'], isNotNull);
    expect(files.values.join(), contains('class String2'));
    expect(files.values.join(), contains('field2'));
  });

  test('loads the same naming config from JSON and YAML', () async {
    for (final extension in ['json', 'yaml']) {
      final CliConfig cli = await CliConfig.load(
        configPath: 'test/fixtures/naming/config.$extension',
      );
      expect(cli.generation.fallbackClientName, 'CommonClient');
      expect(cli.generation.rootApiClassName, 'TransitApi');
      expect(cli.generation.naming.preserveSchemaCasing, isTrue);
      final Map<String, String> actual = await _generate(
        '3_2',
        'json',
        cli.generation,
      );
      expect(
        actual,
        await _generate(
          '3_2',
          'json',
          const GenerationConfig(
            rootApiClassName: 'TransitApi',
            fallbackClientName: 'CommonClient',
            naming: _naming,
          ),
        ),
      );
    }
  });

  test('rejects invalid patterns and fallback names in the Dart API', () async {
    for (final config in [
      const GenerationConfig(fallbackClientName: 'invalid name'),
      const GenerationConfig(
        naming: NamingConfig(
          replaceRules: [
            NameReplacementRule(
              target: NamingTarget.models,
              pattern: '[',
              replacement: '',
            ),
          ],
        ),
      ),
    ]) {
      await expectLater(
        _generate('3_2', 'json', config),
        throwsA(isA<GenerationException>()),
      );
    }
  });

  test('rejects invalid naming config before generation', () async {
    for (final name in [
      'invalid_target_fields',
      'invalid_target_parameters',
      'invalid_pattern',
      'missing_replacement',
      'null_replacement',
      'invalid_fallback',
    ]) {
      await expectLater(
        CliConfig.load(configPath: 'test/fixtures/naming/$name.yaml'),
        throwsA(isA<FormatException>()),
        reason: name,
      );
    }
  });
}
