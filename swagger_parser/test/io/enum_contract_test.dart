@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test(
      'preserves enum types and constraints in $version JSON and YAML',
      () async {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          Map<String, String>? baseline;
          for (final ext in ['json', 'yaml']) {
            final SchemaSource source = await _loader.loadPath(
              'test/fixtures/enum_values/contracts/$version.$ext',
            );
            final mapper = _Mapper();
            final GenerationResult result =
                await SwaggerParserRunner(mapper: mapper).generate(
                  source,
                  loader: _loader,
                  config: GenerationConfig(
                    serializer: serializer,
                    generateValidators: true,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            baseline ??= files;
            expect(files, baseline);
            final Map<String, DartEnumModel> enums = {
              for (final e in mapper.model.libraries.expand((l) => l.enums))
                e.name: e,
            };
            expect(enums['Code']!.values.values, [0, 1, 2]);
            expect(enums['IntegralCode']!.values.values, [1000.0]);
            expect(enums['Text']!.values.values, [
              '',
              'empty',
              'null',
              '0',
              'line\n"\\\$',
            ]);
            expect(enums['InferredCode']!.values.values, [1, 2]);
            expect(enums['RemoteCode']!.values.values, [2, 7]);
            expect(enums['EnvelopeInlineCode']!.values.values, [0, 1, 2]);
            final ApiDefinition api = mapper.api;
            for (final name in ['CodeAlias', 'ExternalCode']) {
              expect(api.schemas[api.namedSchemas[name]]!.reference, isNotNull);
            }
            final ApiSchema narrow =
                api.schemas[api.namedSchemas['NarrowCode']]!;
            expect(narrow.allOf, hasLength(2));
            expect(
              (api.schemas[narrow.allOf.last]!.definition.value!
                  as Map)['enum'],
              [1, 2],
            );
            if (version == 'v3_1' || version == 'v3_2') {
              final Iterable<Object> values = enums['Mixed']!.values.values;
              expect(
                values,
                containsAll(['0', 0, 'null', false, true, 1000.0, 1.25, '']),
              );
              expect(values.whereType<String>(), contains('0'));
              expect(values.whereType<num>(), contains(0));
            }
          }
        }
      },
    );
    for (final invalid in ['missing', 'object_enum']) {
      test('reports $invalid enum input at its source in $version', () async {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await _loader.loadPath(
            'test/fixtures/enum_values/contracts/${version}_$invalid.$ext',
          );
          final prefix = version == 'v2'
              ? '/definitions'
              : '/components/schemas';
          for (final DtoSerializer serializer in DtoSerializer.values) {
            await expectLater(
              const SwaggerParserRunner().generate(
                source,
                loader: _loader,
                config: GenerationConfig(serializer: serializer),
              ),
              throwsA(
                invalid == 'missing'
                    ? isA<OpenApiException>()
                          .having((e) => e.sourceUri, 'URI', source.uri)
                          .having(
                            (e) => e.documentPath,
                            'pointer',
                            '$prefix/Invalid/\$ref',
                          )
                    : isA<GenerationException>()
                          .having(
                            (e) => e.diagnostics.single.sourceUri,
                            'URI',
                            source.uri,
                          )
                          .having(
                            (e) => e.diagnostics.single.documentPath,
                            'pointer',
                            '$prefix/Invalid/enum/0',
                          ),
              ),
            );
          }
        }
      });
    }
  }
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;
  late ApiDefinition api;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) {
    this.api = api;
    return model = const DartModelMapper().map(api, config);
  }
}
