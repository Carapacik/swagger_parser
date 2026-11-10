@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('keeps contextual field, parameter, and method names', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        Map<String, String>? baseline;
        for (final format in ['json', 'yaml']) {
          final SchemaSource
          source = await const FileSchemaSourceLoader().loadPath(
            'test/fixtures/e2e/contextual_identifiers/inputs/openapi.$format',
          );
          final mapper = _Mapper();
          final GenerationResult result =
              await SwaggerParserRunner(mapper: mapper).generate(
                source,
                config: GenerationConfig(
                  serializer: serializer,
                  httpClient: backend,
                ),
              );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final file in result.files) file.relativePath: file.content,
          };
          baseline ??= files;
          expect(files, baseline);
          final List<DartLibraryModel> libraries = mapper.model.libraries;
          final DartDtoModel foo = libraries
              .expand((l) => l.dtos)
              .singleWhere((d) => d.name == 'Foo');
          expect(foo.fields.map((f) => (f.name, f.wireName)), [
            ('type', 'type'),
            ('part', 'part'),
          ]);
          final Iterable<DartClientOperation> operations = libraries.expand(
            (l) => l.operations,
          );
          expect(operations.map((o) => o.name), ['type', 'part']);
          expect(operations.first.parameters.map((p) => p.name), [
            'type',
            'part',
          ]);
        }
      }
    }
  });

  test(
    'keeps contextual type names reserved and resolves real member collisions',
    () async {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/e2e/contextual_identifiers/inputs/openapi.json',
      );
      final document = jsonDecode(source.content) as Map<String, Object?>;
      final schemas =
          (document['components']! as Map<String, Object?>)['schemas']!
              as Map<String, Object?>;
      for (final word in ['type', 'part']) {
        schemas[word] = {'type': 'string'};
      }
      schemas['Foo'] = {
        'type': 'object',
        'properties': {
          'type': {'type': 'string'},
          'Type': {'type': 'string'},
          'part': {'type': 'string'},
          'Part': {'type': 'string'},
          'class': {'type': 'string'},
          'toJson': {'type': 'string'},
        },
      };
      final mapper = _Mapper();
      await SwaggerParserRunner(mapper: mapper).generate(
        SchemaSource.json(jsonEncode(document)),
        config: const GenerationConfig(
          naming: NamingConfig(preserveSchemaCasing: true),
        ),
      );
      final List<DartLibraryModel> libraries = mapper.model.libraries;
      expect(
        libraries.expand((l) => l.values).map((v) => v.name),
        containsAll(['type2', 'part2']),
      );
      final Iterable<DartFieldModel> fields = libraries
          .expand((l) => l.dtos)
          .singleWhere((d) => d.name == 'Foo')
          .fields;
      expect(fields.map((f) => f.name), [
        'type',
        'type2',
        'part',
        'part2',
        'class2',
        'toJson2',
      ]);
    },
  );

  test('rejects contextual words as custom type names', () async {
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      'test/fixtures/e2e/contextual_identifiers/inputs/openapi.json',
    );
    for (final name in ['type', 'part']) {
      await expectLater(
        const SwaggerParserRunner().generate(
          source,
          config: GenerationConfig(
            typeMappings: [
              TypeMapping(
                schema: '#/components/schemas/Foo',
                dartType: name,
                importUrl: 'package:example/types.dart',
                codec: const TypeMappingCodec(
                  importUrl: 'package:example/types.dart',
                  fromJson: 'decode',
                  toJson: 'encode',
                ),
              ),
            ],
          ),
        ),
        throwsA(
          isA<GenerationException>().having(
            (e) => e.message,
            'message',
            contains('Invalid type mapping symbol'),
          ),
        ),
      );
    }
  });

  test(
    'protects names and preserves wire keys across versions and backends',
    () async {
      for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          for (final HttpClientBackend backend in HttpClientBackend.values) {
            for (final renamed in [false, true]) {
              final config = GenerationConfig(
                serializer: serializer,
                httpClient: backend,
                naming: NamingConfig(
                  preserveSchemaCasing: renamed,
                  replaceRules: renamed
                      ? const [
                          NameReplacementRule(
                            target: NamingTarget.models,
                            pattern: r'^Response$',
                            replacement: 'Dio',
                          ),
                          NameReplacementRule(
                            target: NamingTarget.methods,
                            pattern: r'^fromJson$',
                            replacement: 'toJson',
                          ),
                        ]
                      : const [],
                ),
              );
              Map<String, String>? baseline;
              for (final extension in ['json', 'yaml']) {
                final SchemaSource source = await const FileSchemaSourceLoader()
                    .loadPath(
                      'test/fixtures/naming/reserved/$version.$extension',
                    );
                final mapper = _Mapper();
                final GenerationResult result = await SwaggerParserRunner(
                  mapper: mapper,
                ).generate(source, config: config);
                expect(result.diagnostics, isEmpty);
                final Map<String, String> files = {
                  for (final file in result.files)
                    file.relativePath: file.content,
                };
                baseline ??= files;
                expect(files, baseline);
                final List<DartLibraryModel> libraries = mapper.model.libraries;
                final Iterable<DartDtoModel> dtos = libraries.expand(
                  (library) => library.dtos,
                );
                final Set<String> names = dtos.map((dto) => dto.name).toSet();
                expect(
                  names,
                  containsAll([
                    'Station',
                    'Response2',
                    'String2',
                    'String3',
                    'Dio2',
                    'Api2',
                    'StationClient',
                    if (renamed) 'Dio3' else 'Response3',
                    if (renamed)
                      'class2'
                    else if (serializer == DtoSerializer.dartMappable)
                      'Class2'
                    else
                      'Class',
                  ]),
                );
                expect(
                  names,
                  contains(
                    serializer == DtoSerializer.jsonSerializable ||
                            serializer == DtoSerializer.freezed
                        ? 'JsonKey2'
                        : 'JsonKey',
                  ),
                );
                final Map<String?, String> fields = {
                  for (final field
                      in dtos
                          .singleWhere((dto) => dto.name == 'Station')
                          .fields)
                    field.wireName: field.name,
                };
                expect(fields, containsPair('class', 'class3'));
                expect(fields, containsPair('fromJson', 'fromJson3'));
                expect(fields, containsPair('toJson', 'toJson2'));
                expect(fields, containsPair('hashCode', 'hashCode2'));
                expect(fields, containsPair('user-id', 'userId'));
                expect(fields, containsPair('user_id', 'userId2'));
                expect(
                  fields,
                  containsPair(
                    'copyWith',
                    serializer == DtoSerializer.freezed ||
                            serializer == DtoSerializer.dartMappable
                        ? 'copyWith3'
                        : 'copyWith',
                  ),
                );
                expect(
                  fields,
                  containsPair(
                    'toMap',
                    serializer == DtoSerializer.dartMappable
                        ? 'toMap3'
                        : 'toMap',
                  ),
                );
                final Map<String, Object> values = libraries
                    .expand((library) => library.enums)
                    .single
                    .values;
                expect(values, {
                  'values2': 'first',
                  'values3': 'second',
                  'class2': 'third',
                  'fromJson2': 'fourth',
                });
                final DartLibraryModel client = libraries.singleWhere(
                  (library) => library.operations.isNotEmpty,
                );
                expect(client.clientName, 'StationClient2');
                expect(client.operations.map((operation) => operation.name), [
                  'fromJson2',
                  if (renamed) 'toJson2' else 'fromJson3',
                  'fetchJson',
                  'fetchJson2',
                ]);
                final String code = files[client.relativePath]!;
                for (final argument in [
                  'options3',
                  'extra3',
                  'cancelToken2',
                  'class3',
                ]) {
                  expect(code, contains(argument));
                }
              }
            }
          }
        }
      }
    },
  );
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
