@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

Future<SchemaSource> _source(String group, String format) =>
    _loader.loadPath('test/fixtures/e2e/$group/inputs/openapi.$format');

Map<String, Object?> _object(Object? value) => value! as Map<String, Object?>;

void main() {
  for (final DtoSerializer serializer in DtoSerializer.values) {
    test('reuses annotated reference types with ${serializer.name}', () async {
      Map<String, String>? baseline;
      for (final format in ['json', 'yaml']) {
        final mapper = _Mapper();
        final GenerationResult result =
            await SwaggerParserRunner(mapper: mapper).generate(
              await _source('reference_annotations', format),
              config: GenerationConfig(serializer: serializer),
            );
        expect(result.diagnostics, isEmpty);
        final Map<String, String> files = {
          for (final f in result.files) f.relativePath: f.content,
        };
        baseline ??= files;
        expect(files, baseline);
        expect(files.keys, isNot(contains('models/foo_status.dart')));
        expect(files.keys, isNot(contains('models/foo_bar.dart')));
        final DartDtoModel foo = mapper.model.libraries
            .expand((l) => l.dtos)
            .singleWhere((d) => d.name == 'Foo');
        expect(foo.fields.map((f) => (f.name, f.type.symbol)), [
          ('status', 'Status'),
          ('bar', 'Bar'),
        ]);
        expect(files['models/foo.dart'], contains('/// Current status.'));
        expect(files['models/foo.dart'], contains('/// The bar.'));
        expect(mapper.snapshot(), mapper.before);
      }
    });

    test(
      'preserves enum signs and unique wire values with ${serializer.name}',
      () async {
        Map<String, String>? baseline;
        for (final format in ['json', 'yaml']) {
          final mapper = _Mapper();
          final GenerationResult result =
              await SwaggerParserRunner(mapper: mapper).generate(
                await _source('enum_members', format),
                config: GenerationConfig(serializer: serializer),
              );
          final Map<String, String> files = {
            for (final f in result.files) f.relativePath: f.content,
          };
          baseline ??= files;
          expect(files, baseline);
          final Map<String, DartEnumModel> enums = {
            for (final e in mapper.model.libraries.expand((l) => l.enums))
              e.name: e,
          };
          expect(enums['Doors']!.values, {
            'fieldMinus1': -1,
            'field0': 0,
            'field1': 1,
            'field2': 2,
          });
          expect(enums['Sound']!.values, {
            'squeak': 'SQUEAK',
            'noise': 'NOISE',
          });
          expect(mapper.snapshot(), mapper.before);
        }
      },
    );

    test(
      'keeps missing required optional by default with ${serializer.name}',
      () async {
        for (final infer in [false, true]) {
          Map<String, String>? baseline;
          for (final format in ['json', 'yaml']) {
            final mapper = _Mapper();
            final GenerationResult result =
                await SwaggerParserRunner(mapper: mapper).generate(
                  await _source('required_inference', format),
                  config: infer
                      ? GenerationConfig(
                          serializer: serializer,
                          inferMissingRequired: true,
                        )
                      : GenerationConfig(serializer: serializer),
                );
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            baseline ??= files;
            expect(files, baseline);
            final DartDtoModel foo = mapper.model.libraries
                .expand((l) => l.dtos)
                .singleWhere((d) => d.name == 'Foo');
            expect(foo.fields.map((f) => f.isRequired), [infer, infer]);
            expect(foo.fields.map((f) => f.type.isNullable), [!infer, !infer]);
          }
        }
      },
    );
  }

  test(
    'keeps local allOf constraints instead of reusing the reference type',
    () async {
      final document = jsonDecode(
        (await _source('reference_annotations', 'json')).content,
      ) as Map<String, Object?>;
      final Map<String, Object?> schemas = _object(
        _object(document['components'])['schemas'],
      );
      final Map<String, Object?> properties = _object(
        _object(schemas['Foo'])['properties'],
      );
      _object(properties['status'])['enum'] = ['OPEN'];
      _object(properties['bar'])['properties'] = {
        'extra': {'type': 'string'},
      };
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(SchemaSource.json(jsonEncode(document)));
      final Iterable<String> paths = result.files.map((f) => f.relativePath);
      expect(
        paths,
        containsAll(['models/foo_status.dart', 'models/foo_bar.dart']),
      );
      expect(
        result.files
            .singleWhere((f) => f.relativePath == 'models/foo_bar.dart')
            .content,
        contains('String? extra'),
      );
    },
  );

  test(
    'keeps enum labels aligned and distinguishes scalar wire types',
    () async {
      final document = jsonDecode(
        (await _source('enum_members', 'json')).content,
      ) as Map<String, Object?>;
      document['openapi'] = '3.1.2';
      final Map<String, Object?> schemas = _object(
        _object(document['components'])['schemas'],
      );
      _object(schemas['Sound'])['x-enumNames'] = [
        'first',
        'second',
        'duplicate',
      ];
      _object(schemas['Doors'])['x-enumNames'] = [
        'negative',
        'zero',
        'positive',
        'two',
      ];
      schemas['Mixed'] = {
        'enum': [1, 1.0, '1', true, true, null, null],
      };
      schemas['Collision'] = {
        'type': 'string',
        'enum': ['a-b', 'a_b'],
      };
      final mapper = _Mapper();
      await SwaggerParserRunner(mapper: mapper)
          .generate(SchemaSource.json(jsonEncode(document)));
      final Map<String, DartEnumModel> enums = {
        for (final e in mapper.model.libraries.expand((l) => l.enums))
          e.name: e,
      };
      expect(enums['Sound']!.values, {'first': 'SQUEAK', 'second': 'NOISE'});
      expect(enums['Doors']!.values, {
        'negative': -1,
        'zero': 0,
        'positive': 1,
        'two': 2,
      });
      expect(enums['Mixed']!.values.values, [1, '1', true]);
      expect(enums['Collision']!.values, {'aB': 'a-b', 'aB2': 'a_b'});
      expect(mapper.snapshot(), mapper.before);
    },
  );
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;
  late ApiDefinition api;
  late String before;

  String snapshot() => jsonEncode({
    for (final e in api.schemas.entries)
      e.key.toString(): e.value.definition.value,
  });

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) {
    this.api = api;
    before = snapshot();
    return model = const DartModelMapper().map(api, config);
  }
}
