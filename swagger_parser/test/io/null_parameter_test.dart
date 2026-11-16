@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/null_parameters';

void main() {
  test(
    'keeps diagnostics for nullable paths, cookies, and list items',
    () async {
      for (final include in [false, true]) {
        for (final ext in ['json', 'yaml']) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await const FileSchemaSourceLoader().loadPath(
                  '$_base/unsupported.$ext',
                ),
                config: GenerationConfig(includeNullParameters: include),
              );
          expect(result.diagnostics, hasLength(4));
          expect(
            result.diagnostics.map((d) => d.message),
            containsAll([
              contains('Unsupported path parameter: value'),
              contains('Unsupported cookie parameter: value'),
              contains('Unsupported query parameter: value'),
            ]),
          );
        }
      }
    },
  );
  test(
    'defaults to omitting null parameters and supports input overrides',
    () async {
      expect(const GenerationConfig().includeNullParameters, isFalse);
      for (final ext in ['json', 'yaml']) {
        expect(
          (await CliConfig.load(configPath: '$_base/default.$ext'))
              .generation
              .includeNullParameters,
          isFalse,
        );
        expect(
          (await CliConfig.load(configPath: '$_base/enabled.$ext'))
              .generation
              .includeNullParameters,
          isTrue,
        );
        final List<CliConfig> inputs = await CliConfig.loadAll(
          configPath: '$_base/inputs.$ext',
        );
        expect(inputs.map((c) => c.generation.includeNullParameters), [
          true,
          false,
        ]);
        await expectLater(
          CliConfig.load(configPath: '$_base/invalid_config.$ext'),
          throwsA(isA<FormatException>()),
        );
      }
    },
  );
  for (final version in ['v3_1', 'v3_2']) {
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final include in [false, true]) {
        test(
          '$version maps nullable query and header parameters for ${backend.name} with include=$include',
          () async {
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult result = await const SwaggerParserRunner()
                  .generate(
                    await const FileSchemaSourceLoader().loadPath(
                      '$_base/$version.$ext',
                    ),
                    config: GenerationConfig(
                      httpClient: backend,
                      includeNullParameters: include,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final String client = files['default_client/api_client.dart']!;
              expect(client, contains('required String? requiredQuery'));
              expect(client, contains('required String? xRequired'));
              for (final name in [
                'sendQuery',
                'sendHeaders',
                'sendObjects',
                'sendBody',
                'sendForm',
              ]) {
                expect(client, contains('$name('));
              }
              if (backend == HttpClientBackend.retrofit) {
                expect(client.contains('@PreventNullToAbsent()'), include);
              }
            }
          },
        );
      }
    }
  }
}
