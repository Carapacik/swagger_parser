import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

void main() {
  const parser = OpenApiParser();
  late String fixtureJson;
  late String fixtureYaml;
  setUpAll(() async {
    fixtureJson = await readInput('parsing/swagger_v2.json');
    fixtureYaml = await readInput('parsing/swagger_v2.yaml');
  });

  for (final SchemaFormat format in [SchemaFormat.json, SchemaFormat.yaml]) {
    test('parses and round-trips ${format.name}', () {
      final text = format == SchemaFormat.json ? fixtureJson : fixtureYaml;
      final document =
          parser.parse(SchemaSource(text, format: format)) as SwaggerV2Document;
      expect(document.version.family, OpenApiFamily.swaggerV2);
      expect(document.version.value, '2.0');
      expect(document.info.contact!.email, 'help@example.com');
      expect(document.toJson(), jsonDecode(fixtureJson));
      expect(jsonDecode(jsonEncode(document)), jsonDecode(fixtureJson));

      final SwaggerV2Operation operation = document.paths['/pets/{id}']!.get!;
      expect(operation.consumes, isEmpty);
      expect(operation.security, isEmpty);
      final parameter =
          (operation.parameters!.single as SwaggerV2Inline<SwaggerV2Parameter>)
                  .value
              as SwaggerV2ValueParameter;
      expect(parameter.collectionFormat, SwaggerV2CollectionFormat.multi);
      expect(parameter.items!.type, SwaggerV2Type.string);
      expect(
        operation.responses['default'],
        isA<SwaggerV2Reference<SwaggerV2Response>>(),
      );
      expect(
        document.definitions!['x-schema']!.type,
        isA<SwaggerV2SingleType>(),
      );
      expect(
        document.securityDefinitions!['oauth'],
        isA<SwaggerV2OAuth2SecurityScheme>(),
      );
      final SwaggerV2Schema pet = document.definitions!['Pet']!;
      expect(pet.properties!['name']!.type, isA<SwaggerV2TypeSet>());
      expect(pet.properties!['tuple']!.items, isA<SwaggerV2TupleItems>());
      expect(
        (pet.additionalProperties! as SwaggerV2AdditionalPropertiesAllowed)
            .allowed,
        isFalse,
      );
      expect(pet.example!.value, isNull);
      expect(pet.properties!['name']!.defaultValue!.value, isNull);
      expect(pet.properties!['id']!.defaultValue, isNull);
      final children =
          pet.properties!['children']!.items! as SwaggerV2SingleItems;
      expect(children.schema.ref, '#/definitions/Pet');
      expect(document.paths['/external']!.ref, './paths.yaml#/pets');
      expect(document.paths['/events']!.get!.produces, ['text/event-stream']);
    });
  }

  test('keeps nested collections immutable and returns detached JSON', () {
    final document =
        parser.parse(SchemaSource(fixtureJson)) as SwaggerV2Document;
    expect(document.paths.entries.clear, throwsUnsupportedError);
    expect(
      document.definitions!['Pet']!.properties!.clear,
      throwsUnsupportedError,
    );
    expect(
      document.security!.first.schemes['apiKey']!.clear,
      throwsUnsupportedError,
    );
    final extension =
        document.extensions['x-config']!.value! as Map<String, Object?>;
    expect(
      (extension['values']! as List<Object?>).clear,
      throwsUnsupportedError,
    );
    final Map<String, Object?> json = document.toJson();
    (json['info']! as Map<String, Object?>)['title'] = 'Changed';
    expect(document.info.title, 'Pets');
  });

  test('preserves unknown fields and applies a complete config override', () {
    const strict = OpenApiParser(
      config: ParseConfig(unknownFields: UnknownFieldPolicy.reject),
    );
    final Map<String, Object?> data = minimal()..['custom'] = {'value': null};
    final source = SchemaSource(jsonEncode(data));
    expect(() => strict.parse(source), throwsA(isA<SchemaParseException>()));
    final document =
        strict.parse(source, config: const ParseConfig()) as SwaggerV2Document;
    expect(document.extraFields['custom']!.toJson(), {'value': null});
    expect(document.toJson(), data);
    expect(() => strict.parse(source), throwsA(isA<SchemaParseException>()));
  });

  test('strict mode accepts extension and dictionary keys', () {
    expect(
      () => parser.parse(
        SchemaSource(fixtureJson),
        config: const ParseConfig(unknownFields: UnknownFieldPolicy.reject),
      ),
      returnsNormally,
    );
  });

  test('reports source URI, pointer and YAML coordinates', () {
    const source =
        "swagger: '2.0'\ninfo:\n  title: 42\n  version: '1'\npaths: {}\n";
    expect(
      () =>
          parser.parse(SchemaSource(source, uri: Uri.parse('memory:api.yaml'))),
      throwsA(
        isA<SchemaParseException>()
            .having((e) => e.sourceUri, 'URI', Uri.parse('memory:api.yaml'))
            .having((e) => e.documentPath, 'pointer', '/info/title')
            .having((e) => e.location?.line, 'line', 3)
            .having((e) => e.location?.column, 'column', 10),
      ),
    );
    expect(
      () => parser.parse(
        const SchemaSource(source),
        config: const ParseConfig(captureSourceLocations: false),
      ),
      throwsA(
        isA<SchemaParseException>().having(
          (e) => e.location,
          'location',
          isNull,
        ),
      ),
    );
  });

  test(
    'escapes JSON Pointer tokens and locates missing fields at the parent',
    () {
      final Map<String, Object?> data = minimal()
        ..['paths'] = {
          '/a~b/c': {
            'get': {
              'responses': {'200': <String, Object?>{}},
            },
          },
        };
      expect(
        () => parser.parse(SchemaSource(jsonEncode(data))),
        throwsA(
          isA<SchemaParseException>()
              .having(
                (e) => e.documentPath,
                'pointer',
                '/paths/~1a~0b~1c/get/responses/200/description',
              )
              .having((e) => e.location, 'location', isNotNull),
        ),
      );
    },
  );

  test('rejects OpenAPI 4.0', () {
    expect(
      () => parser.parse(const SchemaSource.json('{"openapi":"4.0.0"}')),
      throwsA(isA<UnsupportedOpenApiVersionException>()),
    );
  });

  final invalid = <String, Map<String, Object?>>{
    'missing version': {
      'info': {'title': 'API', 'version': '1'},
      'paths': <String, Object?>{},
    },
    'numeric version': minimal()..['swagger'] = 2.0,
    'ambiguous version': minimal()..['openapi'] = '3.0.4',
    'missing info': {'swagger': '2.0', 'paths': <String, Object?>{}},
    'missing title': minimal()..['info'] = {'version': '1'},
    'null optional field': minimal()..['host'] = null,
    'missing paths': {
      'swagger': '2.0',
      'info': {'title': 'API', 'version': '1'},
    },
    'invalid path': minimal()..['paths'] = {'pets': <String, Object?>{}},
    'missing responses': minimal()
      ..['paths'] = {
        '/pets': {'get': <String, Object?>{}},
      },
    'empty responses': minimal()
      ..['paths'] = {
        '/pets': {
          'get': {'responses': <String, Object?>{}},
        },
      },
    'response range': minimal()
      ..['paths'] = {
        '/pets': {
          'get': {
            'responses': {
              '2XX': {'description': 'OK'},
            },
          },
        },
      },
    'boolean schema': minimal()..['definitions'] = {'Pet': true},
    'file definition': minimal()
      ..['definitions'] = {
        'Pet': {'type': 'file'},
      },
    'empty type array': minimal()
      ..['definitions'] = {
        'Pet': {'type': <Object?>[]},
      },
    'empty tuple': minimal()
      ..['definitions'] = {
        'Pet': {'items': <Object?>[]},
      },
    'invalid constraint': minimal()
      ..['definitions'] = {
        'Pet': {'minLength': -1},
      },
    'invalid additionalProperties': minimal()
      ..['definitions'] = {
        'Pet': {'additionalProperties': 1},
      },
    'non-required path parameter': minimal()
      ..['parameters'] = {
        'Id': {'name': 'id', 'in': 'path', 'type': 'string'},
      },
    'missing body schema': minimal()
      ..['parameters'] = {
        'Pet': {'name': 'pet', 'in': 'body'},
      },
    'missing array items': minimal()
      ..['parameters'] = {
        'Ids': {'name': 'ids', 'in': 'query', 'type': 'array'},
      },
    'file query parameter': minimal()
      ..['parameters'] = {
        'File': {'name': 'file', 'in': 'query', 'type': 'file'},
      },
    'missing OAuth URL': minimal()
      ..['securityDefinitions'] = {
        'Auth': {
          'type': 'oauth2',
          'flow': 'implicit',
          'scopes': <String, Object?>{},
        },
      },
    'invalid security scopes': minimal()
      ..['security'] = [
        {'Auth': 'read'},
      ],
  };
  for (final MapEntry<String, Map<String, Object?>> entry in invalid.entries) {
    test('rejects ${entry.key}', () {
      expect(
        () => parser.parse(SchemaSource(jsonEncode(entry.value))),
        throwsA(isA<SchemaParseException>()),
      );
    });
  }

  for (final source in [
    '{',
    '{"swagger":"2.0",}',
    '[]',
    '',
    "swagger: '2.0'\nswagger: '2.0'",
    "swagger: '2.0'\ninfo: [",
    'a: .inf',
    'a: &a [*a]',
    '200: value',
    '---\na: b\n---\nc: d',
  ]) {
    test('rejects invalid input ${jsonEncode(source)}', () {
      expect(
        () => parser.parse(SchemaSource(source)),
        throwsA(isA<SchemaParseException>()),
      );
    });
  }

  test('accepts YAML aliases without expanding ref cycles', () {
    final document = parser.parse(
      const SchemaSource('''
swagger: '2.0'
info: {title: API, version: '1'}
paths: {}
definitions:
  First: &type {type: string}
  Second: *type
'''),
    ) as SwaggerV2Document;
    expect(
      document.definitions!['First']!.toJson(),
      document.definitions!['Second']!.toJson(),
    );
  });

  test('limits nesting', () {
    expect(
      () => parser.parse(
        SchemaSource(fixtureJson),
        config: const ParseConfig(maxDepth: 2),
      ),
      throwsA(isA<SchemaParseException>()),
    );
  });
}

Map<String, Object?> minimal() => {
  'swagger': '2.0',
  'info': {'title': 'API', 'version': '1'},
  'paths': <String, Object?>{},
};
