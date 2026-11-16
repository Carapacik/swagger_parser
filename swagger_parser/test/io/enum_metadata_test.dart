@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> _generate(
  Map<String, Object?> schema, {
  DtoSerializer serializer = DtoSerializer.freezed,
  UnknownValueMode unknown = UnknownValueMode.reject,
  List<TypeMapping> typeMappings = const [],
}) async {
  final document = <String, Object?>{
    'openapi': '3.0.3',
    'info': {'title': 'Metadata', 'version': '1'},
    'paths': <String, Object?>{},
    'components': {
      'schemas': {'Status': schema},
    },
  };
  return const SwaggerParserRunner().generate(
    SchemaSource.json(jsonEncode(document)),
    config: GenerationConfig(
      serializer: serializer,
      unknownEnumValues: unknown,
      typeMappings: typeMappings,
    ),
  );
}

Map<String, Object?> _valid({String label = 'READY'}) => {
  'type': 'string',
  'enum': ['READY', 'OLD'],
  'x-enumNames': [label, 'OLD'],
  'x-enum-metadata': {
    'version': 1,
    'fields': {
      'description': {'type': 'string'},
      'rank': {'type': 'integer'},
    },
    'values': {
      'READY': {'description': 'sample "quoted" \\ next\nline', 'rank': 7},
      'OLD': {'description': 'old', 'rank': 0},
    },
  },
};

Future<GenerationResult> _generateDocument(
  Map<String, Object?> document, {
  DtoSerializer serializer = DtoSerializer.freezed,
}) => const SwaggerParserRunner().generate(
  SchemaSource.json(jsonEncode(document)),
  config: GenerationConfig(
    serializer: serializer,
    unknownEnumValues: UnknownValueMode.reject,
  ),
);

void main() {
  test(
    'generates an enhanced enum carrying metadata, not a sealed union',
    () async {
      final result = await _generate(_valid());
      expect(result.diagnostics, isEmpty);
      final source = result.files.map((file) => file.content).join('\n');
      expect(source, contains('enum Status'));
      expect(source, contains('ready("READY", description:'));
      expect(source, contains('final String description;'));
      expect(source, contains('final int rank;'));
      expect(source, contains('final String wireValue;'));
      expect(source, contains('factory Status.fromJson'));
      expect(source, contains('String toJson() => wireValue'));
      expect(source, contains(r'sample \"quoted\" \\ next\nline'));
      expect(source, isNot(contains('StatusUnknown')));
    },
  );

  test('metadata generation is available on every serializer', () async {
    for (final serializer in DtoSerializer.values) {
      final result = await _generate(_valid(), serializer: serializer);
      final source = result.files.map((file) => file.content).join('\n');
      expect(result.diagnostics, isEmpty, reason: '$serializer');
      expect(source, contains('enum Status'), reason: '$serializer');
      expect(
        source,
        contains('final String description;'),
        reason: '$serializer',
      );
      expect(source, isNot(contains('StatusUnknown')), reason: '$serializer');
    }
  });

  test(
    'metadata enums never gain an unknown sentinel when preserve is enabled',
    () async {
      final result = await _generate(
        _valid(),
        unknown: UnknownValueMode.preserve,
      );
      final source = result.files.map((file) => file.content).join('\\n');
      expect(result.diagnostics, isEmpty);
      expect(source, contains('enum Status'));
      expect(source, isNot(contains('StatusUnknown')));
    },
  );

  test('ordinary enums retain the legacy representation', () async {
    final result = await _generate({
      'type': 'string',
      'enum': ['READY', 'OLD'],
    });
    final source = result.files.map((file) => file.content).join('\n');
    expect(result.diagnostics, isEmpty);
    expect(source, contains('enum Status'));
    expect(source, isNot(contains('wireValue')));
    expect(source, isNot(contains('StatusUnknown')));
  });
  test(
    'ordinary enum names ignore metadata-only member reservations',
    () async {
      final result = await _generateDocument({
        'openapi': '3.0.3',
        'info': {'title': 'Metadata collision', 'version': '1'},
        'paths': <String, Object?>{},
        'components': {
          'schemas': {
            'Status': _valid(),
            'Ordinary': {
              'type': 'string',
              'enum': ['wireValue', 'tryFromJson'],
            },
          },
        },
      });
      final source = result.files.map((file) => file.content).join('\n');
      expect(result.diagnostics, isEmpty);
      expect(source, contains('wireValue('));
      expect(source, contains('tryFromJson('));
    },
  );

  test(
    'metadata scan terminates for cyclic allOf beside metadata enums',
    () async {
      await expectLater(
        _generateDocument({
          'openapi': '3.0.3',
          'info': {'title': 'Cyclic metadata scan', 'version': '1'},
          'paths': <String, Object?>{},
          'components': {
            'schemas': {
              'Status': _valid(),
              'Loop': {
                'allOf': [
                  {'\$ref': '#/components/schemas/Loop'},
                ],
              },
            },
          },
        }),
        throwsA(anything),
      );
    },
  );

  test('keeps metadata separate for same-named inline enums', () async {
    Map<String, Object?> inline(String description) => {
      'title': 'Status',
      'type': 'string',
      'enum': ['A', 'B'],
      'x-enum-metadata': {
        'version': 1,
        'fields': {
          'description': {'type': 'string'},
        },
        'values': {
          'A': {'description': description},
          'B': {'description': 'other-$description'},
        },
      },
    };
    final result = await _generateDocument({
      'openapi': '3.0.3',
      'info': {'title': 'Inline metadata', 'version': '1'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Container': {
            'type': 'object',
            'properties': {
              'first': inline('first-value'),
              'second': inline('second-value'),
            },
          },
        },
      },
    });
    final source = result.files.map((file) => file.content).join('\n');
    expect(result.diagnostics, isEmpty);
    expect(source, contains('first-value'));
    expect(source, contains('second-value'));
  });

  test('rejects reserved and generated enum member collisions', () async {
    for (final field in [
      'class',
      'final',
      'name',
      'index',
      'hashCode',
      'toString',
      'noSuchMethod',
      'fromJson',
      'tryFromJson',
      'toJson',
      'json',
      'values',
      'value',
      'wireValue',
      'rawValue',
      'copyWith',
    ]) {
      final schema = _valid()
        ..['x-enum-metadata'] = {
          'version': 1,
          'fields': {
            field: {'type': 'string'},
          },
          'values': {
            'READY': {field: 'a'},
            'OLD': {field: 'b'},
          },
        };
      await expectLater(_generate(schema), throwsA(anything), reason: field);
    }
    for (final (schema, field) in [
      (_valid(label: 'class'), 'valueClass'),
      (
        {
          'type': 'integer',
          'enum': [1, 2],
        },
        'value1',
      ),
      (
        {
          'type': 'string',
          'enum': ['', 'OLD'],
        },
        'empty',
      ),
    ]) {
      final wires = (schema['enum']! as List<Object?>).map((v) => v.toString());
      schema['x-enum-metadata'] = {
        'version': 1,
        'fields': {
          field: {'type': 'string'},
        },
        'values': {
          for (final wire in wires) wire: {field: 'x'},
        },
      };
      await expectLater(_generate(schema), throwsA(anything), reason: field);
    }
  });

  test(
    'enum values colliding with generated members are suffixed safely',
    () async {
      for (final reserved in ['wireValue', 'tryFromJson']) {
        for (final explicitNames in [false, true]) {
          final values = explicitNames
              ? ['RAW_A', 'RAW_B']
              : [reserved, 'other'];
          final names = explicitNames ? [reserved, 'other'] : null;
          final rows = {
            for (final value in values) value: {'category': 'sample'},
          };
          final schema = <String, Object?>{
            'type': 'string',
            'enum': values,
            if (names != null) 'x-enumNames': names,
            'x-enum-metadata': {
              'version': 1,
              'fields': {
                'category': {'type': 'string'},
              },
              'values': rows,
            },
          };
          final result = await _generate(schema);
          final source = result.files.map((file) => file.content).join('\n');
          final wire = explicitNames ? 'RAW_A' : reserved;
          expect(result.diagnostics, isEmpty);
          expect(source, contains('${reserved}2("$wire", category:'));
          expect(source, contains('String toJson() => wireValue'));
        }
      }
    },
  );

  test('rejects malformed extension structure and wrong wire keys', () async {
    final mutations = <void Function(Map<String, Object?>)>[
      (schema) =>
          (schema['x-enum-metadata']! as Map<String, Object?>)['version'] = 2,
      (schema) =>
          (schema['x-enum-metadata']! as Map<String, Object?>)['extra'] = true,
      (schema) =>
          ((schema['x-enum-metadata']! as Map<String, Object?>)['values']!
                  as Map<String, Object?>)
              .remove('OLD'),
      (schema) =>
          (((schema['x-enum-metadata']! as Map<String, Object?>)['values']!
                      as Map<String, Object?>)['READY']!
                  as Map<String, Object?>)['rank'] =
              1.5,
    ];
    for (final mutate in mutations) {
      final schema = _valid();
      mutate(schema);
      await expectLater(_generate(schema), throwsA(anything));
    }
    await expectLater(
      _generate({
        'type': 'string',
        'enum': ['001', '1'],
        'x-enum-metadata': {
          'version': 1,
          'fields': {
            'label': {'type': 'string'},
          },
          'values': {
            '0': {'label': 'wrong'},
            '1': {'label': 'one'},
          },
        },
      }),
      throwsA(anything),
    );
  });
  test('rejects lossy integer-to-double metadata and coercions', () async {
    for (final Object value in ['1.5', true, 9007199254740992]) {
      await expectLater(
        _generate({
          'type': 'boolean',
          'enum': [true, false],
          'x-enum-metadata': {
            'version': 1,
            'fields': {
              'weight': {'type': 'number'},
            },
            'values': {
              'true': {'weight': value},
              'false': {'weight': 1.5},
            },
          },
        }),
        throwsA(anything),
      );
    }
    await expectLater(
      _generate(
        _valid(),
        typeMappings: [
          TypeMapping(
            schema: '#/components/schemas/Status',
            dartType: 'CustomStatus',
            importUrl: 'package:app/status.dart',
            codec: TypeMappingCodec(
              importUrl: 'package:app/codec.dart',
              fromJson: 'readStatus',
              toJson: 'writeStatus',
            ),
          ),
        ],
      ),
      throwsA(anything),
    );
  });

  test('preserves inline boolean enum metadata', () async {
    final metadataEnum = {
      'type': 'boolean',
      'enum': [true, false],
      'x-enum-metadata': {
        'version': 1,
        'fields': {
          'label': {'type': 'string'},
        },
        'values': {
          'true': {'label': 'yes'},
          'false': {'label': 'no'},
        },
      },
    };
    final result = await _generateDocument({
      'openapi': '3.0.3',
      'info': {'title': 'Inline enum metadata', 'version': '1'},
      'paths': <String, Object?>{},
      'components': {
        'schemas': {
          'Holder': {
            'type': 'object',
            'properties': {
              'flag': metadataEnum,
              'flags': {'type': 'array', 'items': metadataEnum},
            },
          },
        },
      },
    });
    final source = result.files.map((file) => file.content).join('\n');
    expect(result.diagnostics, isEmpty);
    expect(source, contains('enum HolderFlag'));
    expect(source, contains('final String label;'));
    expect(source, contains('List<HolderFlagsItem>'));
  });

  test('supports boolean enum values and primitive metadata fields', () async {
    final result = await _generate({
      'type': 'boolean',
      'enum': [true, false],
      'x-enumNames': ['enabled', 'disabled'],
      'x-enum-metadata': {
        'version': 1,
        'fields': {
          'weight': {'type': 'number'},
          'active': {'type': 'boolean'},
        },
        'values': {
          'true': {'weight': 1, 'active': true},
          'false': {'weight': 1.5, 'active': false},
        },
      },
    });
    final source = result.files.map((file) => file.content).join('\n');
    expect(result.diagnostics, isEmpty);
    expect(source, contains('enabled(true, weight: 1.0, active: true)'));
    expect(source, contains('final double weight;'));
    expect(source, contains('final bool active;'));
    await expectLater(
      _generate({
        'type': 'number',
        'enum': [1, 2],
        'x-enum-metadata': _valid()['x-enum-metadata'],
      }),
      throwsA(anything),
    );
  });

  test('infers nullable untyped scalar from non-null enum cases', () async {
    final result = await _generate({
      'enum': [1, null, 2],
      'x-enum-metadata': {
        'version': 1,
        'fields': {
          'rank': {'type': 'integer'},
        },
        'values': {
          '1': {'rank': 1},
          '2': {'rank': 2},
        },
      },
    });
    expect(result.diagnostics, isEmpty);
    expect(
      result.files.map((file) => file.content).join('\n'),
      contains('final int rank;'),
    );
  });

  test('preserves Swagger 2 parameter and header metadata', () async {
    final result = await _generateDocument({
      'swagger': '2.0',
      'info': {'title': 'Swagger 2 metadata', 'version': '1'},
      'paths': {
        '/items': {
          'get': {
            'parameters': [
              {
                'name': 'status',
                'in': 'query',
                'type': 'integer',
                'enum': [1, 2],
                'x-enum-metadata': {
                  'version': 1,
                  'fields': {
                    'queryLabel': {'type': 'string'},
                  },
                  'values': {
                    '1': {'queryLabel': 'one'},
                    '2': {'queryLabel': 'two'},
                  },
                },
              },
            ],
            'responses': {
              '200': {
                'description': 'ok',
                'headers': {
                  'X-Status': {
                    'type': 'integer',
                    'enum': [3, 4],
                    'x-enum-metadata': {
                      'version': 1,
                      'fields': {
                        'headerLabel': {'type': 'string'},
                      },
                      'values': {
                        '3': {'headerLabel': 'three'},
                        '4': {'headerLabel': 'four'},
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });
    final source = result.files.map((file) => file.content).join('\n');
    expect(result.diagnostics, isEmpty);
    expect(source, contains('final String queryLabel;'));
    expect(source, contains('final String headerLabel;'));
  });

  test('rejects composed enum metadata rather than dropping it', () async {
    final validMetadata = _valid()['x-enum-metadata'];
    final malformedMetadata = {
      'version': 2,
      'fields': {
        'label': {'type': 'string'},
      },
      'values': {
        'READY': {'label': 'ready'},
        'OLD': {'label': 'old'},
      },
    };
    for (final composition in ['anyOf', 'oneOf', 'allOf']) {
      for (final metadata in [validMetadata, malformedMetadata]) {
        final schema = _valid()
          ..[composition] = [
            {'type': 'string'},
          ]
          ..['x-enum-metadata'] = metadata;
        await expectLater(_generate(schema), throwsA(anything));
      }
    }
  });
  test(
    'rejects non-integer numeric values for integer metadata enums',
    () async {
      await expectLater(
        _generate({
          'type': 'integer',
          'enum': [1.0],
          'x-enum-metadata': {
            'version': 1,
            'fields': {
              'rank': {'type': 'integer'},
            },
            'values': {
              '1.0': {'rank': 1},
            },
          },
        }),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('Integer enum values must be integers.'),
          ),
        ),
      );
    },
  );
}
