@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test('preserves multipart types and references in $version', () async {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          Map<String, String>? baseline;
          for (final ext in ['json', 'yaml']) {
            final mapper = _Mapper();
            final GenerationResult result =
                await SwaggerParserRunner(mapper: mapper).generate(
                  await _loader.loadPath(
                    'test/fixtures/multipart/contracts/$version.$ext',
                  ),
                  loader: _loader,
                  config: GenerationConfig(
                    serializer: serializer,
                    httpClient: backend,
                    inferMissingRequired: false,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            baseline ??= files;
            expect(files, baseline);
            final String source = files.values.join('\n');
            expect(source, isNot(contains("import 'dart:io'")));
            expect(source, contains('/// Upload bytes.'));
            expect(source, contains('/// Required label.'));
            if (backend == HttpClientBackend.retrofit) {
              expect(source, contains('@MultiPart()'));
              expect(source, contains('@FormUrlEncoded()'));
            }
            final Map<String, DartClientOperation> operations = {
              for (final op in mapper.model.libraries.expand(
                (l) => l.operations,
              ))
                op.name: op,
            };
            List<Object> fields(String name) => operations[name]!.body!.fields
                .map(
                  (f) => (f.key, f.type.symbol, f.type.isNullable, f.required),
                )
                .toList();
            expect(fields('uploadReferenced'), fields('uploadInline'));
            final DartClientBody native = operations['uploadNative']!.body!;
            expect(native.isRequired, true);
            expect(
              native.fields.map((f) => (f.key, f.required, f.type.isNullable)),
              [
                ('photo', true, false),
                ('label', true, false),
                ('note', false, false),
              ],
            );
            final List<DartFormField> nulls =
                operations['nullableParts']!.body!.fields;
            expect(nulls.every((f) => f.type.isNullable), true);
            expect(nulls.where((f) => f.required).map((f) => f.key), [
              'requiredText',
              'requiredFile',
            ]);
            expect(
              nulls.where((f) => f.file).map((f) => f.type.symbol),
              everyElement('MultipartFile'),
            );
            if (version != 'v2') {
              expect(operations['rawOptional']!.body!.isRequired, false);
              expect(operations['optionalFields']!.body!.isRequired, false);
              expect(operations['noBody']!.body, isNull);
              final List<DartFormField> lists =
                  operations['nullableLists']!.body!.fields;
              expect(
                lists.every(
                  (f) =>
                      f.type.isNullable &&
                      f.type.typeArguments.single.isNullable,
                ),
                true,
              );
              expect(
                operations['uploadFiles']!.body!.fields.first.type.symbol,
                'List',
              );
              for (final name in [
                'rawEmpty',
                'rawClosed',
                'rawDynamic',
                'rawArray',
                'rawOptional',
                'rawExternalEmpty',
                'optionalFields',
              ]) {
                expect(operations[name]!.body!.fields, isEmpty);
              }
              expect(
                mapper.model.libraries.expand((l) => l.dtos).map((d) => d.name),
                contains('Upload'),
              );
              expect(
                operations['uploadObjects']!.body!.fields.map((f) => f.key),
                ['photo', 'metadata', 'nested', 'inlineObject', 'external'],
              );
            }
          }
        }
      }
    });
    test('reports malformed multipart properties in $version', () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await _loader.loadPath(
          'test/fixtures/multipart/contracts/${version}_invalid_properties.$ext',
        );
        await expectLater(
          const SwaggerParserRunner().generate(source),
          throwsA(
            isA<OpenApiException>()
                .having((e) => e.sourceUri, 'source', source.uri)
                .having(
                  (e) => e.documentPath,
                  'pointer',
                  '${version == 'v2' ? '/definitions' : '/components/schemas'}/Invalid/properties',
                ),
          ),
        );
      }
    });
  }
  test(
    'rejects file array items outside Swagger primitive item types',
    () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await _loader.loadPath(
          'test/fixtures/multipart/contracts/v2_file_array.$ext',
        );
        await expectLater(
          const SwaggerParserRunner().generate(source),
          throwsA(
            isA<OpenApiException>().having(
              (e) => e.documentPath,
              'pointer',
              '/paths/~1invalid/post/parameters/0/items/type',
            ),
          ),
        );
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
