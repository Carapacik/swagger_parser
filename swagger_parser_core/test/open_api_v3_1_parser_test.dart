import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

Map<String, Object?> document(
  Map<String, Object?> fields, {
  String version = '3.1.2',
}) => {
  'openapi': version,
  'info': {'title': 'API', 'version': '1'},
  ...fields,
};

void main() {
  const parser = OpenApiParser(
    config: ParseConfig(unknownFields: UnknownFieldPolicy.reject),
  );
  late String json;
  late String yaml;
  setUpAll(() async {
    json = await readInput('parsing/open_api_v3_1.json');
    yaml = await readInput('parsing/open_api_v3_1.yaml');
  });

  for (final SchemaFormat format in [SchemaFormat.json, SchemaFormat.yaml]) {
    test('parses and exports the ${format.name} webhook document', () {
      final source = SchemaSource(
        format == SchemaFormat.json ? json : yaml,
        format: format,
      );
      final doc = parser.parse(source) as OpenApiV31Document;
      expect(doc.toJson(), jsonDecode(json));
      expect(doc.version.family, OpenApiFamily.v31);
      expect(doc.info.title, 'Pet events 🐶');
      expect(doc.info.license!.identifier, 'Apache-2.0');
      expect(doc.paths, isNull);
      expect(doc.webhooks!['petEvent']!.ref, '#/components/pathItems/Event');
      final OpenApiV31Components components = doc.components!;
      final OpenApiV31PathItem item = components.pathItems!['Event']!;
      expect(item.trace!.responses, isNull);
      final response =
          item.post!.responses!['202']!
              as OpenApiV31Reference<OpenApiV31Response>;
      expect(response.summary, 'Accepted');
      expect(response.description, 'Queued event');
      final body =
          item.post!.requestBody! as OpenApiV31Inline<OpenApiV31RequestBody>;
      final schema =
          body.value.content['application/json']!.schema!
              as OpenApiV31ObjectSchema;
      expect(schema.ref, '#/components/schemas/Event');
      expect(schema.description, 'Delivered event');
      final cert =
          components.securitySchemes!['cert']!
              as OpenApiV31Inline<OpenApiV31SecurityScheme>;
      expect(cert.value, isA<OpenApiV31MutualTlsSecurityScheme>());
      final event = components.schemas!['Event']! as OpenApiV31ObjectSchema;
      expect((event.type! as OpenApiV31TypeSet).values, [
        OpenApiV31Type.object,
        OpenApiV31Type.nullValue,
      ]);
      expect(event.dynamicAnchor, 'event');
      expect(event.extraFields['customKeyword']!.toJson(), {
        'payload': [1, null],
      });
      expect(
        (event.properties!['nested']! as OpenApiV31ObjectSchema).dynamicRef,
        '#event',
      );
      final levels = event.properties!['levels']! as OpenApiV31ObjectSchema;
      expect((levels.items! as OpenApiV31BooleanSchema).value, isFalse);
      expect(
        (levels.prefixItems!.last as OpenApiV31ObjectSchema).exclusiveMinimum,
        0,
      );
      expect(
        (levels.contains! as OpenApiV31ObjectSchema).constValue!.value,
        isNull,
      );
      expect(
        (components.schemas!['Anything']! as OpenApiV31BooleanSchema).value,
        isTrue,
      );
      expect(
        (components.schemas!['Nothing']! as OpenApiV31BooleanSchema).value,
        isFalse,
      );
    });
  }

  test('keeps released patch versions for component-only documents', () {
    for (final version in ['3.1.0', '3.1.1', '3.1.2']) {
      final Map<String, Object?> data = document({
        'components': <String, Object?>{},
      }, version: version);
      final OpenApiDocument doc = parser.parse(
        SchemaSource.json(jsonEncode(data)),
      );
      expect(doc.version.value, version);
      expect(doc.toJson(), data);
    }
  });

  test('inherits the document dialect and honors a resource override', () {
    final doc = parser.parse(SchemaSource.json(json)) as OpenApiV31Document;
    final outer =
        doc.components!.schemas!['Envelope']! as OpenApiV31ObjectSchema;
    expect(outer.dialect, OpenApiV31Schema.draft202012);
    expect(outer.extraFields['xml']!.toJson(), false);
    final opaque = outer.properties!['opaque']! as OpenApiV31ForeignSchema;
    expect(opaque.dialect, 'https://example.org/custom');
    expect(opaque.keywords['items']!.value, [1, 2]);
    final nested = outer.defs!['Nested']! as OpenApiV31ObjectSchema;
    expect(nested.xml!.wrapped, isTrue);
    expect(nested.items!.dialect, OpenApiV31Schema.oasDialect);
    expect(doc.toJson(), jsonDecode(json));
  });

  test('freezes keyword containers and exports detached data', () {
    final doc = parser.parse(SchemaSource.json(json)) as OpenApiV31Document;
    final obj = doc.components!.schemas!['Event']! as OpenApiV31ObjectSchema;
    expect(obj.dependentRequired!['name']!.clear, throwsUnsupportedError);
    expect(obj.properties!.clear, throwsUnsupportedError);
    final exported = obj.toJson()['dependentRequired']! as Map<String, Object?>;
    (exported['name']! as List<String>).clear();
    expect(doc.toJson(), jsonDecode(json));
  });

  const invalidSchemas = <(Object?, String)>[
    (null, ''),
    ([], ''),
    ({'type': <Object?>[]}, '/type'),
    (
      {
        'type': ['null', 'null'],
      },
      '/type',
    ),
    ({'items': <Object?>[]}, '/items'),
    ({'exclusiveMinimum': true}, '/exclusiveMinimum'),
    ({'prefixItems': <Object?>[]}, '/prefixItems'),
    ({'minContains': -1}, '/minContains'),
    ({r'$schema': 10}, r'/$schema'),
    ({r'$dynamicRef': false}, r'/$dynamicRef'),
    (
      {
        'dependentRequired': {
          'a': ['x', 'x'],
        },
      },
      '/dependentRequired/a',
    ),
  ];
  for (final (value, suffix) in invalidSchemas) {
    test('locates schema error in ${jsonEncode(value)}', () {
      final Map<String, Object?> data = document({
        'components': {
          'schemas': {'Pet': value},
        },
      });
      final Uri uri = Uri.parse('memory:bad.json');
      expect(
        () => parser.parse(SchemaSource.json(jsonEncode(data), uri: uri)),
        throwsA(
          isA<SchemaParseException>()
              .having(
                (e) => e.documentPath,
                'pointer',
                '/components/schemas/Pet$suffix',
              )
              .having((e) => e.sourceUri, 'URI', uri)
              .having((e) => e.location?.line, 'line', 1),
        ),
      );
    });
  }

  test('checks structure outside schemas in strict mode', () {
    for (final (data, pointer) in <(Map<String, Object?>, String)>[
      (document({}), ''),
      (
        document({
          'webhooks': {
            'a': {
              'post': {'responses': <String, Object?>{}},
            },
          },
        }),
        '/webhooks/a/post/responses',
      ),
      (
        document({
          'paths': <String, Object?>{},
          'info': {'title': 'A', 'version': '1', 'typo': true},
        }),
        '/info/typo',
      ),
      (
        document({
          'paths': <String, Object?>{},
          'info': {
            'title': 'A',
            'version': '1',
            'license': {'name': 'MIT', 'url': '/terms', 'identifier': 'MIT'},
          },
        }),
        '/info/license/identifier',
      ),
      (
        document({
          'paths': <String, Object?>{},
          'servers': [
            {
              'url': '/{v}',
              'variables': {
                'v': {
                  'enum': ['a'],
                  'default': 'b',
                },
              },
            },
          ],
        }),
        '/servers/0/variables/v/default',
      ),
      (
        document({
          'components': {
            'responses': {
              'A': {r'$ref': '#/external', 'summary': true},
            },
          },
        }),
        '/components/responses/A/summary',
      ),
    ]) {
      expect(
        () => parser.parse(SchemaSource.json(jsonEncode(data))),
        throwsA(
          isA<SchemaParseException>().having(
            (e) => e.documentPath,
            'pointer',
            pointer,
          ),
        ),
      );
    }
  });
}
