import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/extraction_fixtures.dart';

void main() {
  const runner = SwaggerParserRunner();
  test(
    'selects one response media type per status during generation',
    () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await fixtureSource('report_media.$ext');
        for (final ResponseMode mode in ResponseMode.values) {
          for (final HttpClientBackend backend in HttpClientBackend.values) {
            final GenerationResult result = await runner.generate(
              source,
              config: GenerationConfig(httpClient: backend, responseMode: mode),
            );
            final String client = result.files
                .singleWhere((f) => f.relativePath.endsWith('_client.dart'))
                .content;
            expect(client, contains('application/json'));
            expect(client, isNot(contains('application/pdf')));
            if (mode == ResponseMode.firstSuccess) {
              expect(client, contains('Future<int> getReport('));
            } else {
              expect(client, contains('text/plain'));
              final String types = result.files
                  .singleWhere((f) => f.relativePath.endsWith('_results.dart'))
                  .content;
              expect(types, contains('final int value;'));
              expect(types, contains('final String value;'));
            }
          }
        }
      }
    },
  );
}
