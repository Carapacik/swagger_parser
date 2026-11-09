@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  const loader = FileSchemaSourceLoader();
  test('buffers binary responses by default', () {
    expect(const GenerationConfig().streamBinaryResponses, false);
    expect(const GenerationConfig().originalHttpResponse, false);
  });
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test(
      'maps binary media independently from string schemas in $version',
      () async {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          for (final HttpClientBackend backend in HttpClientBackend.values) {
            for (final ResponseMode mode in ResponseMode.values) {
              for (final stream in [false, true]) {
                Map<String, String>? baseline;
                for (final ext in ['json', 'yaml']) {
                  final mapper = _Mapper();
                  final GenerationResult result =
                      await SwaggerParserRunner(mapper: mapper).generate(
                        await loader.loadPath(
                          'test/fixtures/responses/binary/$version.$ext',
                        ),
                        config: GenerationConfig(
                          serializer: serializer,
                          httpClient: backend,
                          responseMode: mode,
                          streamBinaryResponses: stream,
                        ),
                      );
                  expect(result.diagnostics, isEmpty);
                  final Map<String, String> files = {
                    for (final f in result.files) f.relativePath: f.content,
                  };
                  baseline ??= files;
                  expect(files, baseline);
                  final String source = files.values.join('\n');
                  expect(source, isNot(contains('dart:io')));
                  expect(source, isNot(contains('File.fromJson')));
                  expect(source, isNot(contains('Future<File>')));
                  for (final DartClientOperation op
                      in mapper.model.libraries
                          .expand((l) => l.operations)
                          .where((o) => o.name != 'metadata')) {
                    final DartTypeReference type =
                        mode == ResponseMode.firstSuccess
                        ? op.response
                        : op.variants['200']!.type!;
                    expect(type.symbol, stream ? 'Stream' : 'List');
                    final DartTypeReference list = stream
                        ? type.typeArguments.single
                        : type;
                    expect(list.symbol, 'List');
                    expect(list.typeArguments.single.symbol, 'int');
                    if (mode == ResponseMode.allStatuses) {
                      expect(op.variants['204']!.type, isNull);
                    }
                  }
                }
              }
            }
          }
        }
      },
    );
  }
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;
  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
