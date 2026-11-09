@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

void main() {
  for (final version in ['2_0', '3_0', '3_1', '3_2']) {
    test('maps response status and body contracts in $version', () async {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          for (final ResponseMode mode in ResponseMode.values) {
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              final mapper = _Mapper();
              final GenerationResult result =
                  await SwaggerParserRunner(mapper: mapper).generate(
                    await _loader.loadPath(
                      'test/fixtures/responses/status_v$version.$ext',
                    ),
                    config: GenerationConfig(
                      serializer: serializer,
                      httpClient: backend,
                      responseMode: mode,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              baseline ??= files;
              expect(files, baseline);
              expect(files.values.join('\n'), isNot(contains('Future<>')));
              final Map<String, DartClientOperation> ops = {
                for (final op in mapper.model.libraries.expand(
                  (l) => l.operations,
                ))
                  op.name: op,
              };
              final Set<String> models = mapper.model.libraries
                  .expand((l) => l.dtos)
                  .map((d) => d.name)
                  .toSet();
              expect(
                models,
                containsAll([
                  'Station',
                  'CreatedStation',
                  'Ticket',
                  'Problem',
                  'ValidationError',
                  'ServerError',
                ]),
              );
              if (mode == ResponseMode.firstSuccess) {
                expect(
                  files.values.join('\n'),
                  contains('Future<Object?> unconstrained('),
                );
                expect(
                  (
                    ops['lookupStation']!.status,
                    ops['lookupStation']!.response.symbol,
                  ),
                  (200, 'Station'),
                );
                expect(
                  (ops['created']!.status, ops['created']!.response.symbol),
                  (201, 'CreatedStation'),
                );
                expect(
                  (
                    ops['lateSuccess']!.status,
                    ops['lateSuccess']!.response.symbol,
                  ),
                  (226, 'Ticket'),
                );
                expect(ops['multiStatus']!.status, 207);
                expect(ops['listed']!.response.symbol, 'List');
                expect(
                  ops['listed']!.response.typeArguments.single.symbol,
                  'Station',
                );
                for (final name in ['empty', 'noContent', 'invalid']) {
                  expect(ops[name]!.response.symbol, 'void');
                }
                expect(ops['invalid']!.status, isNull);
                expect(
                  (
                    ops['unconstrained']!.response.symbol,
                    ops['unconstrained']!.response.isNullable,
                  ),
                  ('Object', true),
                );
              } else {
                expect(ops['lookupStation']!.variants.keys, [
                  '200',
                  '201',
                  '202',
                  '204',
                  '400',
                  '404',
                  '500',
                ]);
                expect(ops['listed']!.variants.keys, ['200', '204']);
                expect(ops['listed']!.variants['204']!.type, isNull);
                expect(ops['invalid']!.variants.keys, ['400']);
                expect(ops['created']!.variants.keys, ['201']);
                expect(ops['empty']!.variants['204']!.type, isNull);
                expect(ops['noContent']!.variants['200']!.type, isNull);
                expect(
                  ops['unconstrained']!.variants['200']!.type!.symbol,
                  'Object',
                );
                expect(
                  files,
                  contains('default_client/api_client_results.dart'),
                );
              }
              expect(
                mapper.model.libraries
                    .expand((l) => l.enums)
                    .any(
                      (e) => e.values.values.join(',') == 'accepted,partial',
                    ),
                true,
              );
            }
          }
        }
      }
    });
    test('rejects an empty response type at its source in $version', () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await _loader.loadPath(
          'test/fixtures/responses/status_v${version}_empty_type.$ext',
        );
        final pointer =
            '/paths/~1invalid/get/responses/200/${version == '2_0' ? 'schema' : 'content/application~1json/schema'}/type';
        await expectLater(
          const SwaggerParserRunner().generate(source),
          throwsA(
            isA<OpenApiException>()
                .having((e) => e.sourceUri, 'URI', source.uri)
                .having((e) => e.documentPath, 'pointer', pointer)
                .having((e) => e.location, 'coordinates', isNotNull),
          ),
        );
      }
    });
  }
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;
  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
