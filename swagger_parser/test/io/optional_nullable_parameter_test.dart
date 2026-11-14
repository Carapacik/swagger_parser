@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

void main() {
  for (final version in ['v3_1', 'v3_2']) {
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      test('$version keeps optional nullable query and header parameters '
          'with ${backend.name}', () async {
        Map<String, String>? baseline;
        for (final format in ['json', 'yaml']) {
          final SchemaSource source = await _loader.loadPath(
            'test/fixtures/nullable_parameters/$version.$format',
          );
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(source, config: GenerationConfig(httpClient: backend));
          // Only the required nullable query parameter is unsupported.
          expect(result.diagnostics, hasLength(1));
          final Diagnostic diagnostic = result.diagnostics.single;
          expect(
            diagnostic.message,
            contains('Unsupported query parameter: must'),
          );
          expect(diagnostic.documentPath, contains('/paths/~1strict/get'));

          final Map<String, String> files = {
            for (final file in result.files) file.relativePath: file.content,
          };
          baseline ??= files;
          expect(files, baseline);

          final String client = files['default_client/api_client.dart']!;
          expect(client, contains(' search('));
          expect(client, contains(' item('));
          expect(client, isNot(contains(' strict(')));
          // The null of the schema is the null of the optional argument.
          for (final argument in [
            'String? q',
            'int? limit',
            'List<String>? tags',
            'String? xTrace',
            'List<int>? xIds',
            'required int page',
          ]) {
            expect(client, contains(argument));
          }
          // A promoted argument must not use a null-aware call. It would
          // make the result nullable again.
          expect(client, isNot(contains('?.map(')));
          expect(client, isNot(contains('String??')));
        }
      });
    }
  }
}
