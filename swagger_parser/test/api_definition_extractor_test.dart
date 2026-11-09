import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/extraction_fixtures.dart';

Future<ApiDefinition> _extract(String name, {bool normalize = false}) async {
  final SchemaSource source = await fixtureSource(name);
  OpenApiDocument document = const OpenApiParser().parse(source);
  if (normalize) {
    document = const OpenApiNormalizer(
      config: NormalizeConfig(explicitParameterSerialization: true),
    ).normalize(document);
  }
  expect(const OpenApiValidator().validate(document).diagnostics, isEmpty);
  final ReferenceGraph graph = await const OpenApiReferenceResolver().resolve(
    document,
    sourceUri: source.uri,
    loader: fixtureLoader,
  );
  expect(
    const ResolvedOperationValidator().validate(document, graph).diagnostics,
    isEmpty,
  );
  return const ApiDefinitionExtractor().extract(document, graph);
}

void main() {
  for (final (name, version) in [
    ('swagger_v2', '2.0'),
    ('open_api_v3_0', '3.0.4'),
    ('open_api_v3_1', '3.1.2'),
    ('open_api_v3_2', '3.2.1'),
  ]) {
    for (final format in ['json', 'yaml']) {
      test('extracts the station contract from $version $format', () async {
        for (final normalize in [false, true]) {
          final ApiDefinition api = await _extract(
            '$name.$format',
            normalize: normalize,
          );
          expect(
            (api.title, api.apiVersion, api.specVersion.value),
            ('Stations', '1', version),
          );
          expect(
            api.namedSchemas.keys,
            unorderedEquals(['Station', 'Problem', 'Unused']),
          );
          expect(api.operations, hasLength(2));
          final ApiOperation post = api.operations.singleWhere(
            (op) => op.method == 'POST',
          );
          final ApiRequestBody body = post.requestBody!;
          expect(post.dartMethodNameCandidate, 'postStations');
          expect(post.servers.single.value, api.servers.single.value);
          expect(body.isRequired, isTrue);
          expect(post.parameters, isEmpty);
          expect(
            body.content['application/json']!.schema,
            api.namedSchemas['Station'],
          );
          expect(post.responses.keys, ['201', '400']);
          expect(
            post.responses['201']!.headers['Location']!.location,
            'header',
          );
          expect(
            post.responses['201']!.content['application/json']!.schema,
            api.namedSchemas['Station'],
          );
          expect(
            post.responses['400']!.content['application/json']!.schema,
            api.namedSchemas['Problem'],
          );
          final ApiOperation get = api.operations.singleWhere(
            (op) => op.method == 'GET',
          );
          expect(
            (
              get.method,
              get.path,
              get.operationId,
              get.dartMethodNameCandidate,
            ),
            ('GET', '/stations/{id}', null, 'getStationsById'),
          );
          final ApiParameter id = get.parameters.first;
          expect((id.name, id.location, id.isRequired), ('id', 'path', true));
          expect(api.schemas[id.schema]!.types, {'string'});
          final ApiParameter tag = get.parameters.last;
          expect(
            (tag.name, tag.location, tag.isRequired),
            ('tag', 'query', false),
          );
          expect(api.schemas[api.schemas[tag.schema]!.items]!.types, {
            'string',
          });
          expect(
            tag.serialization.toJson(),
            version == '2.0'
                ? {'collectionFormat': 'multi'}
                : {'style': 'form', 'explode': true},
          );
          expect(get.responses.keys, unorderedEquals(['200', '404']));
          expect(
            get.responses['200']!.content['application/json']!.schema,
            api.namedSchemas['Station'],
          );
          expect(
            get.responses['404']!.content['application/json']!.schema,
            api.namedSchemas['Problem'],
          );
          final ApiSchema station = api.schemas[api.namedSchemas['Station']]!;
          expect(station.types, {'object'});
          expect(station.requiredProperties, {'id'});
          expect(
            api.schemas[station.properties['parent']]!.reference,
            api.namedSchemas['Station'],
          );
          expect(api.schemas[station.properties['id']]!.types, {'string'});
          expect(api.namedSchemas.clear, throwsUnsupportedError);
        }
      });
    }
  }

  test(
    'uses the mounted path and includes only reachable external schemas',
    () async {
      final ApiDefinition api = await _extract('mounted.yaml');
      final ApiOperation nested = api.operations.first;
      expect(nested.dartMethodNameCandidate, 'getAByBCByDAndE');
      expect(nested.operationId, isNull);
      expect(nested.source.documentUri!.pathSegments.last, 'library.json');
      expect(api.operations.last.dartMethodNameCandidate, 'listStations');
      expect(api.operations.last.operationId, 'listStations');
      expect(nested.parameters.map((p) => p.name), ['b', 'd', 'e']);
      expect(api.schemas[nested.parameters[1].schema]!.types, {'integer'});
      final ReferenceLocation id =
          nested.responses['200']!.content['application/json']!.schema!;
      final ApiSchema station = api.schemas[id]!;
      expect(station.family, OpenApiFamily.v31);
      expect(api.schemas[station.properties['parent']]!.reference, id);
      final ApiSchema alias = api.schemas[api.namedSchemas['Archived']]!;
      expect(api.schemas[alias.reference]!.types, {'object', 'null'});
      expect(
        api.schemas.keys.any((id) => id.pointer.endsWith('/Unrelated')),
        isFalse,
      );
      expect(api.namedSchemas.keys, ['Archived']);
      expect(nested.responses['default']!.content, isEmpty);
    },
  );

  test('generates mounted GET and empty response methods', () async {
    final SchemaSource source = await fixtureSource('mounted.yaml');
    final GenerationResult result = await const SwaggerParserRunner().generate(
      source,
      loader: fixtureLoader,
    );
    final GeneratedFile client = result.files.singleWhere(
      (f) => f.relativePath == 'default_client/api_client.dart',
    );
    expect(client.content, contains("@GET('/a/{b}/c/{d}/{e}')"));
    expect(client.content, contains('getAByBCByDAndE('));
    expect(client.content, contains('Future<void> listStations('));
    expect(result.diagnostics, isEmpty);
  });

  test('indexes named DTOs without routes or operation references', () async {
    final ApiDefinition api = await _extract('models_only.yaml');
    expect(api.operations, isEmpty);
    expect(
      api.namedSchemas.keys,
      unorderedEquals(['Reading', 'ReadingAlias', 'Anything']),
    );
    final ApiSchema reading = api.schemas[api.namedSchemas['Reading']]!;
    expect(reading.requiredProperties, {'value'});
    expect(api.schemas[reading.properties['value']]!.types, {'number', 'null'});
    expect(api.schemas[reading.properties['unit']]!.types, {'string'});
    expect(api.schemas[api.namedSchemas['Anything']]!.definition.value, isTrue);
    expect(
      api.schemas[api.namedSchemas['ReadingAlias']]!.reference,
      api.namedSchemas['Reading'],
    );
  });

  test('passes the built-in extraction result to the runner mapper', () async {
    final mapper = _RecordingMapper();
    await SwaggerParserRunner(mapper: mapper).generate(
      await fixtureSource('open_api_v3_0.yaml'),
      loader: fixtureLoader,
    );
    expect(
      mapper.api.operations.last.dartMethodNameCandidate,
      'getStationsById',
    );
    await SwaggerParserRunner(
      mapper: mapper,
    ).generate(await fixtureSource('models_only.yaml'), loader: fixtureLoader);
    expect(mapper.api.operations, isEmpty);
    expect(mapper.api.namedSchemas.keys, contains('Reading'));
  });

  test(
    'extracts custom methods, security, multipart, SSE and callback cycles',
    () async {
      final ApiDefinition api = await _extract('transport.yaml');
      final ApiOperation report = api.operations.singleWhere(
        (op) => op.method == 'Report',
      );
      final ApiOperation query = api.operations.singleWhere(
        (op) => op.method == 'QUERY',
      );
      expect(report.servers.single.value, {'url': '/uploads'});
      expect(report.security, isEmpty);
      expect(query.servers.single.value, {'url': '/search'});
      expect(query.security.single.value, {'token': <String>[]});
      expect(api.securitySchemes.keys, ['token']);
      final ApiParameter filter = query.parameters.single;
      expect(filter.location, 'querystring');
      expect(filter.schema, isNull);
      expect(api.schemas[filter.content['application/json']!.schema]!.types, {
        'string',
      });
      final ApiEncoding part = report
          .requestBody!
          .content['multipart/form-data']!
          .encodings['/encoding/photo']!;
      expect(api.schemas[part.headers['X-Id']!.schema]!.types, {'integer'});
      final ApiMediaType events =
          report.responses['200']!.content['text/event-stream']!;
      expect(api.schemas[events.itemSchema]!.types, {'string'});
      expect(api.webhooks.single.path, 'changed');
      final ApiOperation callback =
          api.callbacks[report.callbacks['done']]!.single;
      expect(callback.path, r'{$request.body#/url}');
      expect(callback.callbacks['again'], report.callbacks['done']);
    },
  );

  test('collects Swagger form fields and operation media types', () async {
    final ApiDefinition api = await _extract('form.json');
    final ApiOperation op = api.operations.single;
    expect(op.parameters, isEmpty);
    final ApiRequestBody body = op.requestBody!;
    expect(body.isRequired, isTrue);
    expect(body.content.keys, ['multipart/form-data']);
    expect(body.formFields.map((p) => p.name), ['photo', 'tag']);
    expect(body.formFields.last.serialization.collectionFormat, 'multi');
  });

  for (final (fixture, pointer) in [
    (
      'unlisted_variant.yaml',
      '/components/schemas/Union/discriminator/mapping/bad~1~0',
    ),
    ('conflicting_all_of.json', '/components/schemas/Reading/allOf/1'),
    (
      'tuples/tuple_v3_0_unsupported.yaml',
      '/components/schemas/Reading/prefixItems',
    ),
    (
      'dynamic_references/dynamic_cycle.yaml',
      r'/components/schemas/Choice/anyOf/0/$dynamicRef',
    ),
    (
      'array_contains/contains_v3_0_unsupported.yaml',
      '/components/schemas/Batch/anyOf/0/contains',
    ),
    (
      'structural_unions/structural_unsupported.yaml',
      '/components/schemas/Filter/anyOf/1/contains/not',
    ),
  ]) {
    test('reports the source of $fixture', () async {
      final SchemaSource source = await fixtureSource(fixture);
      await expectLater(
        const SwaggerParserRunner().generate(source),
        throwsA(
          isA<GenerationException>()
              .having((e) => e.diagnostics.single.sourceUri, 'URI', source.uri)
              .having(
                (e) => e.diagnostics.single.documentPath,
                'pointer',
                pointer,
              ),
        ),
      );
    });
  }

  test('rejects structural recursion on the same JSON value', () async {
    final SchemaSource source = await fixtureSource(
      'structural_unions/structural_cycle.yaml',
    );
    await expectLater(
      const SwaggerParserRunner().generate(source),
      throwsA(
        isA<GenerationException>()
            .having((e) => e.message, 'message', contains('must descend'))
            .having(
              (e) => e.diagnostics.single.sourceUri,
              'source',
              source.uri,
            ),
      ),
    );
  });

  test('reports an invalid tuple position in the external schema', () async {
    final SchemaSource entry = await fixtureSource(
      'tuples/tuple_invalid_external.json',
    );
    await expectLater(
      const SwaggerParserRunner().generate(entry, loader: fixtureLoader),
      throwsA(
        isA<GenerationException>()
            .having(
              (e) => e.diagnostics.single.sourceUri,
              'URI',
              entry.uri!.resolve('tuple_invalid_positions.yaml'),
            )
            .having(
              (e) => e.diagnostics.single.documentPath,
              'pointer',
              '/prefixItems/1',
            ),
      ),
    );
  });

  test('indexes dynamic anchors outside a referenced component', () async {
    final ApiDefinition api = await _extract(
      'dynamic_references/dynamic_v3_2.yaml',
    );
    final ReferenceLocation root = api.namedSchemas['Imported']!;
    final Uri catalog = root.documentUri!.resolve('dynamic_catalog.yaml');
    final ReferenceLocation item = api.dynamicAnchors[(catalog, 'item')]!;
    expect(item, (
      documentUri: catalog,
      pointer: '/components/schemas/LabelItem',
    ));
    expect(api.schemas[item]!.types, {'string'});
    expect(api.schemas[item]!.resourceUri, catalog);
    expect(api.dynamicAnchors.clear, throwsUnsupportedError);
  });

  test('indexes contains and items as separate schemas', () async {
    final ApiDefinition api = await _extract(
      'array_contains/contains_v3_2.json',
    );
    final ApiSchema readings = api.schemas[api.namedSchemas['Readings']]!;
    expect(api.schemas[readings.items]!.types, {'number'});
    expect(api.schemas[readings.contains]!.definition.value, {'minimum': 0});
    expect(readings.contains!.pointer, '/components/schemas/Readings/contains');
  });

  test(
    'indexes tuple positions in wire order and keeps the tail schema',
    () async {
      final ApiDefinition api = await _extract('tuples/tuple_v3_2.yaml');
      final ApiSchema reading = api.schemas[api.namedSchemas['Reading']]!;
      expect(reading.prefixItems.map((id) => id.pointer), [
        '/components/schemas/Reading/prefixItems/0',
        '/components/schemas/Reading/prefixItems/1',
      ]);
      expect(api.schemas[reading.items]!.types, {'boolean'});
      expect(reading.prefixItems.clear, throwsUnsupportedError);
    },
  );

  test('extracts oneOf branches without a discriminator', () async {
    final ApiDefinition api = await _extract('union.yaml');
    final ApiSchema union = api.schemas[api.namedSchemas['Union']]!;
    expect(union.discriminator, isNull);
    expect(union.oneOf.map((id) => api.schemas[id]!.types.single), [
      'string',
      'integer',
    ]);
  });
}

final class _RecordingMapper() implements DartModelMapper {
  late ApiDefinition api;
  @override
  DartGenerationModel map(ApiDefinition definition, GenerationConfig config) {
    api = definition;
    return DartGenerationModel(libraries: []);
  }
}
