import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/extraction_fixtures.dart';

const _renaming = NamingConfig(
  replaceRules: [
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'^Station$',
      replacement: 'Stop',
    ),
    NameReplacementRule(
      target: NamingTarget.models,
      pattern: r'^CaseModel$',
      replacement: 'CaseDto',
    ),
  ],
);

Future<Map<String, String>> _generate(
  SchemaSource source,
  GenerationConfig config, {
  _Mapper? mapper,
}) async {
  final GenerationResult result = await SwaggerParserRunner(
    mapper: mapper ?? const DartModelMapper(),
  ).generate(source, config: config);
  expect(result.diagnostics, isEmpty);
  final Map<String, String> files = {
    for (final file in result.files) file.relativePath: file.content,
  };
  expect(files, hasLength(result.files.length));
  for (final MapEntry<String, String> entry in files.entries) {
    for (final RegExpMatch match in RegExp(
      '''(?:import|export) ['"]([^'"]+)['"]''',
    ).allMatches(entry.value)) {
      final Uri uri = Uri.parse(match[1]!);
      if (uri.hasScheme) {
        continue;
      }
      final String path = Uri.parse(entry.key).resolveUri(uri).path;
      expect(
        files.containsKey(path),
        isTrue,
        reason: '${entry.key} references $path',
      );
    }
  }
  return files;
}

Map<String, Object?> _document(SchemaSource source) =>
    const OpenApiParser().parse(source).toJson();
Map<String, Object?> _schemas(Map<String, Object?> doc) =>
    (doc['definitions'] ?? (doc['components']! as Map)['schemas'])!
        as Map<String, Object?>;
Map<String, Object?> _paths(Map<String, Object?> doc) =>
    doc['paths']! as Map<String, Object?>;
Map<String, Object?> _response(Map<String, Object?> doc, String path) {
  final response =
      ((_paths(doc)[path]! as Map)['post'] as Map)['responses'] as Map;
  final success = response['200'] as Map;
  return (success['schema'] ??
          ((success['content'] as Map)['application/json'] as Map)['schema'])
      as Map<String, Object?>;
}

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test(
      '$version preserves type identity, file ownership, and exact wire names',
      () async {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          for (final HttpClientBackend backend in HttpClientBackend.values) {
            for (final renamed in [false, true]) {
              final config = GenerationConfig(
                serializer: serializer,
                httpClient: backend,
                naming: renamed ? _renaming : const NamingConfig(),
                generateValidators: true,
              );
              Map<String, String>? baseline;
              for (final ext in ['json', 'yaml']) {
                final SchemaSource source = await fixtureSource(
                  'model_identity/$version.$ext',
                );
                final mapper = _Mapper();
                final Map<String, String> files = await _generate(
                  source,
                  config,
                  mapper: mapper,
                );
                baseline ??= files;
                expect(files, baseline);
                expect(await _generate(source, config), files);
                final station = renamed ? 'Stop' : 'Station';
                final caseName = renamed ? 'CaseDto' : 'CaseModel';
                expect(
                  files.keys,
                  unorderedEquals([
                    'api.dart',
                    'exports.dart',
                    'dto_validation_error.dart',
                    if (backend == HttpClientBackend.http)
                      'http_request_options.dart',
                    'auth/auth_client.dart',
                    'stations/stations_client.dart',
                    'trips/trips_client.dart',
                    'geo/geo_client.dart',
                    for (final name in [
                      'login_alt_request',
                      'login_alt_response200',
                      'login_alt_response200_data',
                      'login_request',
                      'login_response2002',
                      'login_response2002_data',
                      'post_a_by_bc_by_d_and_e_request',
                      'post_a_by_bc_by_d_and_e_response200',
                      'post_a_by_bc_by_d_and_e_response200_data',
                      'put_a_by_bc_by_d_and_e_request',
                    ])
                      'auth/models/$name.dart',
                    for (final name in [
                      'coordinates',
                      'nearby_response200',
                      'nearby_response200_locations_item',
                    ])
                      'geo/models/$name.dart',
                    'models/login_response200.dart',
                    for (final name in [
                      if (renamed) 'case_dto' else 'case_model',
                      if (renamed) 'case_dto_nested' else 'case_model_nested',
                      'depot',
                      'enum_use',
                      'merged',
                      'shared',
                      if (renamed) 'stop' else 'station',
                      'type2',
                      'type3',
                    ])
                      'trips/models/$name.dart',
                  ]),
                );
                final Map<String, DartDtoModel> dtos = {
                  for (final dto in mapper.model.libraries.expand(
                    (l) => l.dtos,
                  ))
                    dto.name: dto,
                };
                Map<String, DartFieldModel> fields(String name) => {
                  for (final field in dtos[name]!.fields)
                    field.wireName!: field,
                };
                expect(fields('Shared')['station']!.type.symbol, station);
                expect(fields('Shared')['again']!.type.symbol, station);
                expect(fields('Shared')['depot']!.type.symbol, 'Depot');
                expect(
                  fields(caseName).keys,
                  unorderedEquals([
                    'Station',
                    'station',
                    'Code',
                    'code',
                    'nested',
                  ]),
                );
                expect(
                  fields(caseName).values.every((f) => f.isRequired),
                  isTrue,
                );
                expect(
                  fields(caseName).values.map((f) => f.name).toSet(),
                  hasLength(5),
                );
                expect(
                  fields('LoginResponse2002').keys,
                  unorderedEquals(['token', 'data']),
                );
                expect(
                  fields('LoginResponse2002').values.every((f) => f.isRequired),
                  isTrue,
                );
                expect(fields('LoginResponse200').keys, ['reserved']);
                expect(
                  fields('Merged').keys,
                  unorderedEquals(['count', 'snake-key', 'snake_key']),
                );
                expect(
                  fields('Merged').values.map((f) => f.name).toSet(),
                  hasLength(3),
                );
                expect(
                  fields('EnumUse')['first']!.type.symbol,
                  fields('EnumUse')['again']!.type.symbol,
                );
                expect(
                  fields('EnumUse')['first']!.type.symbol,
                  isNot(fields('EnumUse')['second']!.type.symbol),
                );
                expect(
                  files['stations/stations_client.dart'],
                  contains('../trips/models/shared.dart'),
                );
                expect(
                  files['exports.dart'],
                  contains('trips/models/shared.dart'),
                );
                expect(files['api.dart'], contains("export 'exports.dart'"));
              }
            }
          }
        }
      },
      // Run 48 generation cases within this browser test.
      onPlatform: {'browser': const Timeout(Duration(minutes: 2))},
    );

    test(
      '$version changes one inline model without merging equal shapes',
      () async {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await fixtureSource(
            'model_identity/$version.$ext',
          );
          final Map<String, Object?> original = _document(source);
          final String snapshot = jsonEncode(original);
          for (final DtoSerializer serializer in DtoSerializer.values) {
            final config = GenerationConfig(serializer: serializer);
            final Map<String, String> before = await _generate(source, config);
            final Map<String, Object?> changed = _document(source);
            final data =
                (_response(changed, '/other-login')['properties']!
                        as Map)['data']
                    as Map;
            (data['properties'] as Map)['id'] = {'type': 'integer'};
            final Map<String, String> after = await _generate(
              SchemaSource.json(jsonEncode(changed), uri: source.uri),
              config,
            );
            expect(after.keys, unorderedEquals(before.keys));
            expect(
              after['auth/models/login_alt_response200_data.dart'],
              isNot(before['auth/models/login_alt_response200_data.dart']),
            );
            for (final String path in before.keys.where(
              (p) =>
                  p.startsWith('auth/models/login_response2002') ||
                  p.startsWith('trips/models/'),
            )) {
              expect(after[path], before[path]);
            }
            expect(jsonEncode(original), snapshot);
            final Map<String, Object?> reordered = _document(source);
            final Map<String, Object?> paths = _paths(reordered);
            final Object? second = paths.remove('/stations/shared');
            reordered['paths'] = {'/stations/shared': second, ...paths};
            final Map<String, String> moved = await _generate(
              SchemaSource.json(jsonEncode(reordered), uri: source.uri),
              config,
            );
            expect(moved.keys, contains('stations/models/shared.dart'));
            expect(moved.keys, isNot(contains('trips/models/shared.dart')));
            expect(
              moved.keys.where((p) => p.endsWith('/shared.dart')),
              hasLength(1),
            );
            expect(
              moved['trips/trips_client.dart'],
              contains('../stations/models/shared.dart'),
            );
          }
        }
      },
    );

    test(
      '$version generates only reachable inline files without named components',
      () async {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await fixtureSource(
            'model_identity/$version.$ext',
          );
          final Map<String, Object?> doc = _document(source);
          _schemas(doc).clear();
          _paths(doc).removeWhere(
            (path, _) =>
                !['/login', '/other-login', '/a/{b}/c/{d}/{e}'].contains(path),
          );
          for (final DtoSerializer serializer in DtoSerializer.values) {
            final Map<String, String> files = await _generate(
              SchemaSource.json(jsonEncode(doc), uri: source.uri),
              GenerationConfig(serializer: serializer),
            );
            expect(
              files.keys,
              unorderedEquals([
                'api.dart',
                'exports.dart',
                'auth/auth_client.dart',
                for (final name in [
                  'login_alt_request',
                  'login_alt_response200',
                  'login_alt_response200_data',
                  'login_request',
                  'login_response200',
                  'login_response200_data',
                  'post_a_by_bc_by_d_and_e_request',
                  'post_a_by_bc_by_d_and_e_response200',
                  'post_a_by_bc_by_d_and_e_response200_data',
                  'put_a_by_bc_by_d_and_e_request',
                ])
                  'auth/models/$name.dart',
              ]),
            );
            expect(
              files['auth/auth_client.dart'],
              contains('postAByBCByDAndE'),
            );
            expect(files['auth/auth_client.dart'], contains('putAByBCByDAndE'));
          }
        }
      },
    );
  }
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) {
    final Map<ReferenceLocation, String> before = {
      for (final entry in api.schemas.entries)
        entry.key: jsonEncode(entry.value.definition.value),
    };
    model = const DartModelMapper().map(api, config);
    expect({
      for (final entry in api.schemas.entries)
        entry.key: jsonEncode(entry.value.definition.value),
    }, before);
    return model;
  }
}
