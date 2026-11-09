@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/body_positional';

void main() {
  test('defaults to named bodies and inherits input overrides', () async {
    expect(const GenerationConfig().bodyPositional, isFalse);
    for (final ext in ['json', 'yaml']) {
      final CliConfig named = await CliConfig.load(
        configPath: '$_base/named.$ext',
      );
      final CliConfig positional = await CliConfig.load(
        configPath: '$_base/positional.$ext',
      );
      final List<CliConfig> inputs = await CliConfig.loadAll(
        configPath: '$_base/inputs.$ext',
      );
      expect(named.generation.bodyPositional, isFalse);
      expect(positional.generation.bodyPositional, isTrue);
      expect(inputs.map((c) => c.generation.bodyPositional), [true, false]);
      await expectLater(
        CliConfig.load(configPath: '$_base/invalid.$ext'),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('generates the same client from JSON and YAML CLI config', () async {
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final style in ['named', 'positional']) {
        Map<String, String>? expected;
        for (final ext in ['json', 'yaml']) {
          final CliConfig config = await CliConfig.load(
            configPath: '$_base/$style.$ext',
          );
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await const FileSchemaSourceLoader().loadPath(
                  '$_base/open_api_v3_2.$ext',
                ),
                config: GenerationConfig(
                  bodyPositional: config.generation.bodyPositional,
                  httpClient: backend,
                ),
              );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final f in result.files) f.relativePath: f.content,
          };
          expected ??= files;
          expect(files, expected);
          final String client = files['default_client/api_client.dart']!;
          expect(
            client,
            style == 'positional'
                ? matches(
                    r'updateStation\(\s*(?:@Body\(\)\s*)?(?:models\.)?Station body,\s*\{',
                  )
                : contains('updateStation({'),
          );
          expect(client, contains('optionalBody({'));
          expect(client, contains('submitForm({'));
          expect(client, contains('upload({'));
        }
      }
    }
  });
}
