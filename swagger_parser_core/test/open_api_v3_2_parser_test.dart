import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

T inline<T extends OpenApiV32JsonSerializable>(OpenApiV32RefOr<T>? value) =>
    (value! as OpenApiV32Inline<T>).value;

Map<String, Object?> withField(String json, String pointer, Object? value) {
  final root = jsonDecode(json) as Map<String, Object?>;
  final List<String> keys = pointer
      .split('/')
      .skip(1)
      .map((key) => key.replaceAll('~1', '/').replaceAll('~0', '~'))
      .toList();
  Object? node = root;
  for (final String key in keys.take(keys.length - 1)) {
    node = node is List<Object?>
        ? node[int.parse(key)]
        : (node! as Map<String, Object?>)[key];
  }
  if (node is List<Object?>) {
    node[int.parse(keys.last)] = value;
  } else {
    (node! as Map<String, Object?>)[keys.last] = value;
  }
  return root;
}

void main() {
  const parser = OpenApiParser(
    config: ParseConfig(unknownFields: UnknownFieldPolicy.reject),
  );
  late String json;
  late String yaml;
  setUpAll(() async {
    json = await readInput('parsing/open_api_v3_2.json');
    yaml = await readInput('parsing/open_api_v3_2.yaml');
  });

  for (final SchemaFormat format in [SchemaFormat.json, SchemaFormat.yaml]) {
    test('reads the station API from ${format.name}', () {
      final source = SchemaSource(
        format == SchemaFormat.json ? json : yaml,
        format: format,
      );
      final doc = parser.parse(source) as OpenApiV32Document;
      expect(doc.toJson(), jsonDecode(json));
      expect(doc.version.family, OpenApiFamily.v32);
      expect(doc.version.value, '3.2.1');
      expect(doc.self, './events.yaml');
      expect(doc.servers!.single.name, 'production');
      final OpenApiV32Tag tag = doc.tags!.last;
      expect(
        (tag.summary, tag.parent, tag.kind),
        ('Sensor readings', 'stations', 'nav'),
      );

      final OpenApiV32PathItem path = doc.paths!['/readings']!;
      final OpenApiV32Operation query = path.query!;
      expect(query.operationId, 'findReadings');
      final OpenApiV32Parameter filter = inline(query.parameters!.first);
      expect(filter.location, OpenApiV32ParameterLocation.querystring);
      expect(filter.example!.value, {'station': 'north'});
      expect(
        inline(filter.content!['application/json']).schema,
        isA<OpenApiV32ObjectSchema>(),
      );
      expect(inline(query.parameters!.last).style, OpenApiV32Style.cookie);
      final OpenApiV32Response response = inline(query.responses!['200']);
      expect(response.summary, 'Reading stream');
      expect(response.description, isNull);
      final ref =
          response.content!['text/event-stream']!
              as OpenApiV32Reference<OpenApiV32MediaType>;
      expect(ref.ref, '#/components/mediaTypes/EventStream');
      expect(ref.description, 'Live station readings');
      final OpenApiV32Header header = inline(response.headers!['X-Station']);
      expect(header.example!.value, 'north');
      expect(
        header.content!['text/plain'],
        isA<OpenApiV32Reference<OpenApiV32MediaType>>(),
      );

      final OpenApiV32Components components = doc.components!;
      final OpenApiV32MediaType media = inline(
        components.mediaTypes!['EventStream'],
      );
      final event = media.itemSchema! as OpenApiV32ObjectSchema;
      expect(event.ref, '#/components/schemas/Event');
      expect(event.dialect, OpenApiV32Schema.oasDialect);
      final OpenApiV32Operation report = path.additionalOperations!['REPORT']!;
      final OpenApiV32RequestBody body = inline(report.requestBody);
      final OpenApiV32MediaType multipart = inline(
        body.content['multipart/mixed'],
      );
      expect(multipart.prefixEncoding!.single.contentType, 'application/json');
      expect(
        multipart.itemEncoding!.encoding!['reading']!.contentType,
        'application/json',
      );
      expect(
        components.mediaTypes!['LiveReadings'],
        isA<OpenApiV32Reference<OpenApiV32MediaType>>(),
      );

      final schema = components.schemas!['Reading']! as OpenApiV32ObjectSchema;
      expect(
        schema.discriminator!.defaultMapping,
        '#/components/schemas/OtherReading',
      );
      final temperature =
          components.schemas!['Temperature']! as OpenApiV32ObjectSchema;
      final degrees =
          temperature.properties!['degrees']! as OpenApiV32ObjectSchema;
      expect(degrees.xml!.nodeType, OpenApiV32XmlNodeType.attribute);
      expect(
        components.schemas!['VendorReading'],
        isA<OpenApiV32ForeignSchema>(),
      );

      final OpenApiV32Example sample = inline(components.examples!['Reading']);
      expect(sample.dataValue!.value, containsPair('event', 'update'));
      expect(sample.serializedValue, startsWith('event: update\n'));
      final OpenApiV32Example empty = inline(components.examples!['Empty']);
      expect(empty.dataValue!.value, isNull);
      expect(empty.externalValue, './examples/empty.txt');
      final oauth = inline(
        components.securitySchemes!['device'],
      ) as OpenApiV32OAuth2SecurityScheme;
      expect(oauth.deprecated, isFalse);
      expect(oauth.oauth2MetadataUrl, endsWith('/oauth-authorization-server'));
      final OpenApiV32OAuthFlow flow = oauth.flows.deviceAuthorization!;
      expect(flow.deviceAuthorizationUrl, endsWith('/device'));
      expect(flow.tokenUrl, endsWith('/token'));
      expect(flow.scopes, {'read': 'Read station events'});
      expect(inline(components.securitySchemes!['oldKey']).deprecated, isTrue);
    });

    test('locates an invalid self URI in ${format.name}', () {
      final text = format == SchemaFormat.json ? json : yaml;
      final Uri uri = Uri.parse(
        'https://stations.example.org/events.${format.name}',
      );
      final source = SchemaSource(
        text.replaceFirst('./events.yaml', 'bad uri'),
        format: format,
        uri: uri,
      );
      expect(
        () => parser.parse(source),
        throwsA(
          isA<SchemaParseException>()
              .having((error) => error.sourceUri, 'source URI', uri)
              .having((error) => error.documentPath, 'pointer', r'/$self')
              .having(
                (error) => error.location?.line,
                'line',
                format == SchemaFormat.json ? 3 : 2,
              ),
        ),
      );
    });
  }

  test('detects both formats and preserves each released patch', () {
    for (final version in ['3.2.0', '3.2.1']) {
      for (final text in [json, yaml]) {
        final OpenApiDocument doc = parser.parse(
          SchemaSource(text.replaceFirst('3.2.1', version)),
        );
        expect(doc.version.value, version);
        expect(doc.toJson()['openapi'], version);
      }
    }
  });

  test('keeps immutable collections and exports detached JSON', () {
    final doc = parser.parse(SchemaSource.json(json)) as OpenApiV32Document;
    final Map<String, OpenApiV32Operation> operations =
        doc.paths!['/readings']!.additionalOperations!;
    expect(operations.clear, throwsUnsupportedError);
    final OpenApiV32RequestBody body = inline(
      operations['REPORT']!.requestBody,
    );
    expect(
      inline(body.content['multipart/mixed']).prefixEncoding!.clear,
      throwsUnsupportedError,
    );
    final Map<String, Object?> exported = doc.toJson();
    (exported['components']! as Map<String, Object?>).clear();
    expect(doc.toJson(), jsonDecode(json));
  });

  const path = '/paths/~1readings';
  const params = '$path/query/parameters';
  const multipart =
      '$path/additionalOperations/REPORT/requestBody/content/multipart~1mixed';
  const xml = '/components/schemas/Temperature/properties/degrees/xml';
  const deviceFlow =
      '/components/securitySchemes/device/flows/deviceAuthorization';
  const Map<String, Object> queryParameter = {
    'name': 'id',
    'in': 'query',
    'schema': {'type': 'string'},
  };
  const Map<String, Object> wholeQuery = {
    'name': 'q',
    'in': 'querystring',
    'content': {'text/plain': <String, Object?>{}},
  };
  final invalid = <(String, Object?, String)>[
    (
      '$path/additionalOperations/QUERY',
      {},
      '$path/additionalOperations/QUERY',
    ),
    (
      '$path/additionalOperations/BAD METHOD',
      {},
      '$path/additionalOperations/BAD METHOD',
    ),
    ('$path/parameters', [queryParameter], '$params/0/in'),
    ('$params/1', wholeQuery, '$params/1/in'),
    (
      '$params/0',
      {'name': 'q', 'in': 'querystring', 'schema': true},
      '$params/0/content',
    ),
    ('$params/0/style', 'form', '$params/0/style'),
    ('$params/0/content/text~1plain', {}, '$params/0/content'),
    ('$params/1/explode', false, '$params/1/explode'),
    ('$params/1/style', 'simple', '$params/1/style'),
    ('$multipart/encoding', {}, '$multipart/prefixEncoding'),
    (
      '$multipart/itemEncoding/prefixEncoding',
      [],
      '$multipart/itemEncoding/prefixEncoding',
    ),
    (
      '/components/examples/Reading/value',
      null,
      '/components/examples/Reading/dataValue',
    ),
    (
      '/components/examples/Reading/externalValue',
      'sample.txt',
      '/components/examples/Reading/serializedValue',
    ),
    ('$xml/wrapped', false, '$xml/wrapped'),
    ('$xml/nodeType', 'comment', '$xml/nodeType'),
    (
      deviceFlow,
      {'tokenUrl': '/token', 'scopes': <String, String>{}},
      '$deviceFlow/deviceAuthorizationUrl',
    ),
    (
      deviceFlow,
      {'deviceAuthorizationUrl': '/device', 'scopes': <String, String>{}},
      '$deviceFlow/tokenUrl',
    ),
    (
      '/components/mediaTypes/EventStream/itemSchema',
      [],
      '/components/mediaTypes/EventStream/itemSchema',
    ),
    (
      '/components/securitySchemes/device/deprecated',
      'true',
      '/components/securitySchemes/device/deprecated',
    ),
  ];
  for (final (pointer, value, errorPath) in invalid) {
    test('reports $errorPath when changing $pointer', () {
      final source = SchemaSource.json(
        jsonEncode(withField(json, pointer, value)),
      );
      expect(
        () => parser.parse(source),
        throwsA(
          isA<SchemaParseException>().having(
            (error) => error.documentPath,
            'pointer',
            errorPath,
          ),
        ),
      );
    });
  }

  test(
    'allows an operation to override an inherited querystring parameter',
    () {
      final Map<String, Object> filter = {...wholeQuery, 'name': 'filter'};
      final source = SchemaSource.json(
        jsonEncode(withField(json, '$path/parameters', [filter])),
      );
      expect(parser.parse(source), isA<OpenApiV32Document>());
    },
  );

  test('keeps 3.2 fields outside the 3.1 strict model', () {
    final source = SchemaSource.json(json.replaceFirst('3.2.1', '3.1.2'));
    expect(
      () => parser.parse(source),
      throwsA(
        isA<SchemaParseException>().having(
          (error) => error.documentPath,
          'pointer',
          r'/$self',
        ),
      ),
    );
  });

  test('inherits the declared dialect for stream items', () {
    const dialect = 'https://spec.openapis.org/oas/3.2/dialect/2025-09-17';
    final source = SchemaSource.json(
      jsonEncode(withField(json, '/jsonSchemaDialect', dialect)),
    );
    final doc = parser.parse(source) as OpenApiV32Document;
    final item =
        inline(doc.components!.mediaTypes!['EventStream']).itemSchema!
            as OpenApiV32ObjectSchema;
    expect(item.dialect, dialect);
    expect(item.ref, '#/components/schemas/Event');
    expect(
      doc.components!.schemas!['VendorReading'],
      isA<OpenApiV32ForeignSchema>(),
    );
  });

  test('keeps boolean item schemas and nested positional encodings', () {
    final Map<String, Object?> fields = withField(
      json,
      '/components/mediaTypes/Parts',
      {
        'itemSchema': false,
        'itemEncoding': {
          'contentType': 'multipart/mixed',
          'prefixEncoding': [
            {'contentType': 'text/plain'},
          ],
          'itemEncoding': {'contentType': 'image/png'},
        },
      },
    );
    final doc = parser.parse(
      SchemaSource.json(jsonEncode(fields)),
    ) as OpenApiV32Document;
    final OpenApiV32MediaType media = inline(
      doc.components!.mediaTypes!['Parts'],
    );
    expect((media.itemSchema! as OpenApiV32BooleanSchema).value, isFalse);
    expect(
      media.itemEncoding!.prefixEncoding!.single.contentType,
      'text/plain',
    );
    expect(media.itemEncoding!.itemEncoding!.contentType, 'image/png');
    expect(doc.toJson(), fields);
  });
}
