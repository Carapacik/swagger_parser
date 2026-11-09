import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

extension<T extends OpenApiV30JsonSerializable> on OpenApiV30RefOr<T> {
  T get inline => (this as OpenApiV30Inline<T>).value;
  String get ref => (this as OpenApiV30Reference<T>).ref;
}

Map<String, Object?> minimal({String version = '3.0.4'}) => {
  'openapi': version,
  'info': {'title': 'API', 'version': '1'},
  'paths': <String, Object?>{},
};

void main() {
  const parser = OpenApiParser();
  const strict = ParseConfig(unknownFields: UnknownFieldPolicy.reject);
  late String json;
  late String yaml;
  setUpAll(() async {
    json = await readInput('parsing/open_api_v3_0.json');
    yaml = await readInput('parsing/open_api_v3_0.yaml');
  });
  for (final SchemaFormat format in [SchemaFormat.json, SchemaFormat.yaml]) {
    test('round-trips typed ${format.name} input', () {
      final source = SchemaSource(
        format == SchemaFormat.json ? json : yaml,
        format: format,
      );
      final document =
          parser.parse(source, config: strict) as OpenApiV30Document;
      expect(document.toJson(), jsonDecode(json));
      expect(document.version.family, OpenApiFamily.v30);
      expect(document.servers!.single.variables!['region']!.defaultValue, 'eu');
      final OpenApiV30PathItem item = document.paths['/events/{id}']!;
      expect(item.ref, './paths.yaml#/events');
      expect(item.trace!.responses['default']!.inline.description, 'Trace');
      final OpenApiV30Parameter parameter = item.parameters!.single.inline;
      expect(parameter.isRequired, isTrue);
      expect(parameter.location, OpenApiV30ParameterLocation.path);
      final OpenApiV30Operation operation = item.post!;
      expect(operation.security, isEmpty);
      expect(operation.responses['4XX']!.ref, '#/components/responses/Error');
      expect(
        operation
            .responses['200']!
            .inline
            .content!['text/event-stream']!
            .schema!
            .ref,
        '#/components/schemas/Event',
      );
      final OpenApiV30Components components = document.components!;
      final OpenApiV30Schema event = components.schemas!['Event']!.inline;
      expect(event.properties!['kind']!.inline.defaultValue!.value, isNull);
      expect(
        event.properties!['peers']!.inline.items!.ref,
        './peers.yaml#/Peer',
      );
      final parent =
          event.properties!['parent']! as OpenApiV30Reference<OpenApiV30Schema>;
      expect(parent.ignoredFields['description']!.value, 'ignored');
      final additional =
          event.additionalProperties! as OpenApiV30AdditionalPropertiesSchema;
      expect(
        additional.schema.inline.oneOf!.last.inline.type,
        OpenApiV30Type.integer,
      );
      expect(
        (components.schemas!['x-closed']!.inline.additionalProperties!
                as OpenApiV30AdditionalPropertiesAllowed)
            .allowed,
        isFalse,
      );
      final OpenApiV30Callback callback =
          components.callbacks!['notify']!.inline;
      expect(
        callback[r'{$request.body#/url}']!
            .post!
            .responses['204']!
            .inline
            .description,
        'Delivered',
      );
      expect(callback.extensions['x-owner']!.value, 'events');
      final OpenApiV30MediaType upload = components
          .requestBodies!['Upload']!
          .inline
          .content['multipart/form-data']!;
      expect(
        upload.encoding!['file']!.headers!['X-File']!.ref,
        '#/components/headers/RequestId',
      );
      expect(components.examples!['File']!.inline.value!.value, isNull);
      expect(
        components.links!['next']!.inline.parameters!['id']!.value,
        r'$response.header.X-Request-Id',
      );
      expect(components.parameters!['cursor']!.inline.content!.keys, [
        'application/json',
      ]);
      final Map<String, OpenApiV30RefOr<OpenApiV30SecurityScheme>> schemes =
          components.securitySchemes!;
      expect(schemes['cookie']!.inline, isA<OpenApiV30ApiKeySecurityScheme>());
      expect(schemes['http']!.inline, isA<OpenApiV30HttpSecurityScheme>());
      expect(
        schemes['discovery']!.inline,
        isA<OpenApiV30OpenIdConnectSecurityScheme>(),
      );
      expect(
        (schemes['oauth']!.inline as OpenApiV30OAuth2SecurityScheme)
            .flows
            .authorizationCode!
            .refreshUrl,
        '/refresh',
      );
    });
  }

  for (final patch in [0, 1, 2, 3, 4]) {
    test('preserves the declared 3.0.$patch version', () {
      final version = '3.0.$patch';
      final OpenApiDocument document = parser.parse(
        SchemaSource.json(jsonEncode(minimal(version: version))),
      );
      expect(document, isA<OpenApiV30Document>());
      expect(document.version.value, version);
      expect(document.toJson()['openapi'], version);
    });
  }
  for (final version in ['3.0', '3.0.x', '3.0.04', '3.0.4.1', '3.0.-1']) {
    test('rejects malformed version $version', () {
      expect(
        () => parser.parse(
          SchemaSource.json(jsonEncode(minimal(version: version))),
        ),
        throwsA(isA<UnsupportedOpenApiVersionException>()),
      );
    });
  }

  test('isolates nested collections and exported JSON', () {
    final document =
        parser.parse(SchemaSource.json(json)) as OpenApiV30Document;
    final OpenApiV30Schema schema =
        document.components!.schemas!['Event']!.inline;
    expect(
      document.security!.first.schemes['oauth']!.clear,
      throwsUnsupportedError,
    );
    expect(schema.properties!.clear, throwsUnsupportedError);
    final Map<String, Object?> exported = document.toJson();
    (exported['paths']! as Map<String, Object?>).clear();
    ((schema.toJson()['x-data']! as Map<String, Object?>)['flags']!
            as List<Object?>)
        .clear();
    expect(document.toJson(), jsonDecode(json));
  });

  test(
    'preserves unknown fields and reports their location in strict mode',
    () {
      final Uri uri = Uri.parse('memory:doc.yaml');
      final source = SchemaSource.yaml(
        'openapi: 3.0.4\ninfo: {title: API, version: v1}\npaths: {}\ncomponents:\n  schemas:\n    Pet:\n      custom: [null]\n',
        uri: uri,
      );
      final document = parser.parse(source) as OpenApiV30Document;
      expect(
        document.components!.schemas!['Pet']!.inline.extraFields['custom']!
            .toJson(),
        [null],
      );
      expect(
        () => parser.parse(source, config: strict),
        throwsA(
          isA<SchemaParseException>()
              .having(
                (e) => e.documentPath,
                'pointer',
                '/components/schemas/Pet/custom',
              )
              .having((e) => e.sourceUri, 'source', uri)
              .having((e) => e.location?.line, 'line', 7),
        ),
      );
    },
  );

  const invalid = <(String, Object?, String)>[
    ('schemas', true, ''),
    ('schemas', {'type': 'null'}, '/type'),
    ('schemas', {'type': 'integer', 'default': '1'}, '/default'),
    ('schemas', {'type': 'string', 'default': null}, '/default'),
    (
      'schemas',
      {
        'type': ['string', 'null'],
      },
      '/type',
    ),
    ('schemas', {'type': 'array'}, '/items'),
    ('schemas', {'items': <Object?>[]}, '/items'),
    ('schemas', {'allOf': <Object?>[]}, '/allOf'),
    ('schemas', {'additionalProperties': 42}, '/additionalProperties'),
    ('schemas', {'readOnly': true, 'writeOnly': true}, '/writeOnly'),
    ('schemas', {'maxProperties': -1}, '/maxProperties'),
    ('schemas', {'multipleOf': 0}, '/multipleOf'),
    ('schemas', {'exclusiveMinimum': 5}, '/exclusiveMinimum'),
    (
      'schemas',
      {
        'required': ['id', 'id'],
      },
      '/required',
    ),
    ('schemas', {r'$ref': false}, r'/$ref'),
    (
      'parameters',
      {'name': 'id', 'in': 'path', 'schema': <String, Object?>{}},
      '/required',
    ),
    ('parameters', {'name': 'id', 'in': 'query'}, '/schema'),
    (
      'parameters',
      {
        'name': 'id',
        'in': 'query',
        'schema': <String, Object?>{},
        'content': <String, Object?>{},
      },
      '/content',
    ),
    (
      'parameters',
      {
        'name': 'id',
        'in': 'query',
        'content': {'a': <String, Object?>{}, 'b': <String, Object?>{}},
      },
      '/content',
    ),
    (
      'parameters',
      {
        'name': 'id',
        'in': 'cookie',
        'style': 'simple',
        'schema': <String, Object?>{},
      },
      '/style',
    ),
    ('headers', {'in': 'header', 'schema': <String, Object?>{}}, '/in'),
    (
      'headers',
      {'allowReserved': false, 'schema': <String, Object?>{}},
      '/allowReserved',
    ),
    (
      'headers',
      {
        'content': {'text/plain': <String, Object?>{}},
        'example': null,
      },
      '/example',
    ),
    ('requestBodies', <String, Object?>{}, '/content'),
    (
      'requestBodies',
      {
        'content': {
          'text/plain': {'example': null, 'examples': <String, Object?>{}},
        },
      },
      '/content/text~1plain/examples',
    ),
    ('responses', <String, Object?>{}, '/description'),
    ('examples', {'value': null, 'externalValue': './a'}, '/externalValue'),
    ('links', {'operationId': 'a', 'operationRef': './a'}, '/operationRef'),
    (
      'securitySchemes',
      {
        'type': 'oauth2',
        'flows': {
          'authorizationCode': {
            'scopes': <String, Object?>{},
            'authorizationUrl': '/auth',
          },
        },
      },
      '/flows/authorizationCode/tokenUrl',
    ),
    ('securitySchemes', {'type': 'apiKey', 'name': 'key', 'in': 'path'}, '/in'),
  ];
  for (final (kind, value, pointer) in invalid) {
    test('reports $kind input ${jsonEncode(value)} at $pointer', () {
      final Map<String, Object?> data = minimal()
        ..['components'] = {
          kind: {'Field': value},
        };
      expect(
        () => parser.parse(SchemaSource.json(jsonEncode(data))),
        throwsA(
          isA<SchemaParseException>()
              .having(
                (e) => e.documentPath,
                'pointer',
                '/components/$kind/Field$pointer',
              )
              .having((e) => e.location, 'location', isNotNull),
        ),
      );
    });
  }
  for (final code in ['20X', '2xx', '600', 'x-only']) {
    test('rejects invalid or missing response code $code', () {
      final Map<String, Object?> data = minimal()
        ..['paths'] = {
          '/p~q': {
            'get': {
              'responses': {
                code: {'description': 'test'},
              },
            },
          },
        };
      expect(
        () => parser.parse(SchemaSource.json(jsonEncode(data))),
        throwsA(
          isA<SchemaParseException>().having(
            (e) => e.documentPath,
            'pointer',
            startsWith('/paths/~1p~0q/get/responses'),
          ),
        ),
      );
    });
  }

  test(
    'checks component names and retains the parent location for missing fields',
    () {
      for (final (root, pointer) in <(Map<String, Object?>, String)>[
        (minimal()..remove('info'), '/info'),
        (minimal()..remove('paths'), '/paths'),
        (
          minimal()
            ..['components'] = {
              'schemas': {'Bad/name': <String, Object?>{}},
            },
          '/components/schemas/Bad~1name',
        ),
      ]) {
        expect(
          () => parser.parse(SchemaSource.json(jsonEncode(root))),
          throwsA(
            isA<SchemaParseException>()
                .having((e) => e.documentPath, 'pointer', pointer)
                .having((e) => e.location, 'location', isNotNull),
          ),
        );
      }
    },
  );
}
