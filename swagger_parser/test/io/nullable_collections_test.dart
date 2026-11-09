@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test(
      '$version keeps nullable query exclusion and optional flags',
      () async {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await const FileSchemaSourceLoader()
              .loadPath(
                'test/fixtures/collections/nullability/${version}_query.$ext',
              );
          for (final HttpClientBackend backend in HttpClientBackend.values) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  source,
                  config: GenerationConfig(httpClient: backend),
                );
            expect(result.diagnostics, hasLength(1));
            final Diagnostic diagnostic = result.diagnostics.single;
            expect(
              diagnostic.message,
              contains('Unsupported query parameter: value'),
            );
            expect(diagnostic.sourceUri, source.uri);
            expect(
              diagnostic.documentPath,
              contains('/paths/~1skipped/get/parameters/0'),
            );
            final String client = result.files
                .singleWhere(
                  (f) => f.relativePath == 'default_client/api_client.dart',
                )
                .content;
            expect(client, contains(' kept('));
            expect(client, isNot(contains(' skipped(')));
            expect(client, contains('String? absent'));
            expect(client, contains('String? optional'));
            expect(client, contains('required String required2'));
          }
        }
      },
    );
    test('$version keeps collection nullability and source schemas', () async {
      Map<String, String>? expected;
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/collections/nullability/$version.$ext');
        final OpenApiDocument document = const OpenApiParser().parse(source);
        final String before = jsonEncode(document.toJson());
        final ReferenceGraph graph = await const OpenApiReferenceResolver()
            .resolve(document, sourceUri: source.uri);
        final ApiDefinition api = const ApiDefinitionExtractor().extract(
          document,
          graph,
        );
        final DartGenerationModel model = const DartModelMapper().map(
          api,
          const GenerationConfig(),
        );
        expect(jsonEncode(document.toJson()), before);
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(source);
        expect(result.diagnostics, isEmpty);
        final Map<String, String> files = {
          for (final f in result.files) f.relativePath: f.content,
        };
        expected ??= files;
        expect(files, expected);
        final String dto =
            files['default_client/models/nullable_collections.dart']!;
        for (final type in [
          'List<String> listRequiredRequired',
          'List<String?> listRequiredNullable',
          'List<String>? listNullableRequired',
          'List<String?>? listNullableNullable',
          'Map<String, String?>? mapNullableNullable',
          'List<Map<String, List<String?>?>?>? nested',
        ]) {
          expect(dto, contains(type));
        }
        expect(dto, contains('/// Selected gender.'));
        expect(
          model.libraries.expand((l) => l.operations).map((o) => o.name),
          containsAll(['echoCollections', 'getGender', 'getCriteria']),
        );
      }
    });
  }
}
