import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/extraction_fixtures.dart';

void main() {
  test('keeps background decoding disabled by default', () {
    expect(const GenerationConfig().decodeResponsesInBackground, false);
  });
  test('keeps streaming and binary response code unchanged', () async {
    for (final ext in ['json', 'yaml']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        Map<String, String>? expected;
        for (final enabled in [false, true]) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await fixtureSource('untyped_response.$ext'),
                config: GenerationConfig(
                  httpClient: backend,
                  streamBinaryResponses: true,
                  decodeResponsesInBackground: enabled,
                  operationFilters: const OperationFilterConfig(
                    includePaths: ['/text', '/bytes', '/events', '/records'],
                  ),
                ),
              );
          final Map<String, String> files = {
            for (final file in result.files)
              if (!file.relativePath.startsWith('_response_decoder'))
                file.relativePath: file.content,
          };
          expected ??= files;
          expect(files, expected);
        }
      }
    }
  });
  test(
    'plans conditional decoders for each schema family and backend',
    () async {
      for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await fixtureSource('background_decoding/$version.$ext'),
                  config: GenerationConfig(
                    httpClient: backend,
                    decodeResponsesInBackground: true,
                    fileSuffix: '.generated',
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            expected ??= files;
            expect(files, expected);
            expect(
              files['_response_decoder.generated.dart'],
              contains('if (dart.library.io)'),
            );
            expect(
              files['_response_decoder_native.generated.dart'],
              contains('Isolate.spawn'),
            );
            expect(
              files['_response_decoder_web.generated.dart'],
              isNot(contains('dart:isolate')),
            );
            expect(files['exports.dart'], isNot(contains('_response_decoder')));
            final String client = files.values.singleWhere(
              (s) => s.contains('class ApiClient'),
            );
            expect(client, contains('_decoding.decodeResponse('));
            expect(client, contains('_decodegetStation'));
            if (backend != HttpClientBackend.http) {
              expect(client, contains('ResponseType.stream'));
            }
          }
        }
      }
    },
  );
}
