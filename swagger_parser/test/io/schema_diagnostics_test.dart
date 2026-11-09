@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test('$version reports malformed schema fields at their source', () async {
      final bool modern = version == 'v3_1' || version == 'v3_2';
      final cases = {
        'property': '/properties/bad',
        'required': '/properties/name/required',
        if (modern) 'null_type': '/type/1' else 'items': '/items',
      };
      for (final MapEntry<String, String> entry in cases.entries) {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource
          source = await const FileSchemaSourceLoader().loadPath(
            'test/fixtures/diagnostics/contracts/${version}_${entry.key}.$ext',
          );
          expect(
            () => const OpenApiParser().parse(source),
            throwsA(
              isA<SchemaParseException>()
                  .having((e) => e.sourceUri, 'URI', source.uri)
                  .having(
                    (e) => e.documentPath,
                    'pointer',
                    '/${version == 'v2' ? 'definitions' : 'components/schemas'}/Invalid${entry.value}',
                  )
                  .having((e) => e.location?.line, 'line', isPositive),
            ),
          );
        }
      }
    });
  }
  test('diagnoses non-object form bodies without emitting empty requests', () async {
    for (final family in ['v3_0', 'v3_1', 'v3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/http_media/${family}_unsupported.$ext');
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(source, config: GenerationConfig(httpClient: backend));
          expect(result.diagnostics, hasLength(2));
          for (final (i, diagnostic) in result.diagnostics.indexed) {
            expect(
              diagnostic.message,
              'Skipped POST /${i == 0 ? 'array' : 'scalar'}. Unsupported request media type or form encoding.',
            );
            expect(diagnostic.sourceUri, source.uri);
            expect(
              diagnostic.documentPath,
              '/paths/~1${i == 0 ? 'array' : 'scalar'}/post/requestBody',
            );
          }
          expect(
            result.files.where((f) => f.relativePath.endsWith('_client.dart')),
            isEmpty,
          );
        }
      }
    }
  });

  for (final version in ['v3_0', 'v3_1', 'v3_2']) {
    test('$version rejects missing discriminator mapping targets', () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource
        source = await const FileSchemaSourceLoader().loadPath(
          'test/fixtures/composition/unions/${version}_invalid_mapping.$ext',
        );
        await expectLater(
          const SwaggerParserRunner().generate(source),
          throwsA(
            isA<ReferenceResolutionException>()
                .having((e) => e.sourceUri, 'URI', source.uri)
                .having(
                  (e) => e.documentPath,
                  'pointer',
                  contains('/discriminator/mapping/typo'),
                ),
          ),
        );
      }
    });
  }
  for (final version in ['v3_1', 'v3_2']) {
    test('$version retains conflicting type and const constraints', () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/diagnostics/contracts/${version}_const.$ext',
            );
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(source);
        expect(result.diagnostics, isEmpty);
        final String code = result.files.map((f) => f.content).join();
        expect(code, contains('value is num'));
        expect(code, contains('value == "0"'));
        expect(code, contains('value == "1"'));
      }
    });
  }
}
