import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/extraction_fixtures.dart';

void main() {
  test('keeps JSON content distinct from absent content', () async {
    expect(const GenerationConfig().originalHttpResponse, isFalse);
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final ResponseMode mode in ResponseMode.values) {
        Map<String, String>? plain;
        for (final wrapped in [false, true]) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await fixtureSource('untyped_response.$ext'),
                  config: GenerationConfig(
                    httpClient: backend,
                    responseMode: mode,
                    originalHttpResponse: wrapped,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            expected ??= files;
            expect(files, expected);
            final String client = files['default_client/api_client.dart']!;
            expect(client, isNot(contains('Object.fromJson')));
            if (mode == ResponseMode.allStatuses) {
              final String results =
                  files['default_client/api_client_results.dart']!;
              expect(results, contains('final Object? value;'));
              expect(client, contains('Future<JsonResult> json('));
            } else {
              final prefix = wrapped
                  ? (backend == HttpClientBackend.dio
                        ? 'Response<'
                        : 'HttpResponse<')
                  : '';
              final suffix = wrapped ? '>' : '';
              for (final method in ['json', 'emptySchema', 'jsonSuffix']) {
                expect(
                  client,
                  contains('Future<${prefix}Object?$suffix> $method('),
                );
              }
              expect(client, contains('Future<${prefix}String$suffix> text('));
              expect(
                client,
                contains('Future<${prefix}List<int>$suffix> bytes('),
              );
              for (final method in ['absent', 'noContent', 'onlyError']) {
                expect(
                  client,
                  contains('Future<${prefix}void$suffix> $method('),
                );
              }
              expect(
                files.containsKey('http_response.dart'),
                wrapped && backend == HttpClientBackend.http,
              );
            }
          }
          plain ??= expected;
          if (mode == ResponseMode.allStatuses) {
            expect(expected, plain);
          }
        }
      }
    }
  });
}
