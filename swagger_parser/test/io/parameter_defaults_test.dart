@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/parameter_defaults';

void main() {
  test('reads parameter default settings and input overrides', () async {
    expect(const GenerationConfig().applyParameterDefaults, isFalse);
    for (final ext in ['json', 'yaml']) {
      expect(
        (await CliConfig.load(configPath: '$_base/default.$ext'))
            .generation
            .applyParameterDefaults,
        isFalse,
      );
      expect(
        (await CliConfig.load(configPath: '$_base/enabled.$ext'))
            .generation
            .applyParameterDefaults,
        isTrue,
      );
      final List<CliConfig> inputs = await CliConfig.loadAll(
        configPath: '$_base/inputs.$ext',
      );
      expect(inputs.map((c) => c.generation.applyParameterDefaults), [
        true,
        false,
      ]);
      await expectLater(
        CliConfig.load(configPath: '$_base/invalid_config.$ext'),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('and retain omission and requiredness', () async {
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final enabled in [false, true]) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await const FileSchemaSourceLoader().loadPath(
                    '$_base/$family.$ext',
                  ),
                  config: GenerationConfig(
                    httpClient: backend,
                    applyParameterDefaults: enabled,
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
              contains(enabled ? 'int? limit = 25' : 'int? limit,'),
            );
            expect(client, contains('required int requiredLimit,'));
            expect(client, isNot(contains('requiredLimit =')));
            expect(
              client,
              contains(enabled ? 'int? count = 3' : 'int? count,'),
            );
            expect(client, contains('required String token,'));
            expect(client, isNot(contains('token =')));
            expect(client, isNot(contains('CreateStation? body =')));
          }
        }
      }
    }
  });

  test('rejects invalid parameter defaults only when enabled', () async {
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('$_base/invalid_$family.$ext');
        final GenerationResult plain = await const SwaggerParserRunner()
            .generate(source);
        expect(plain.diagnostics, isEmpty);
        await expectLater(
          const SwaggerParserRunner().generate(
            source,
            config: const GenerationConfig(applyParameterDefaults: true),
          ),
          throwsA(
            isA<GenerationException>()
                .having((e) => e.message, 'message', contains('invalid/time'))
                .having(
                  (e) => e.diagnostics.single.code,
                  'code',
                  'invalidParameterDefault',
                )
                .having(
                  (e) => e.diagnostics.single.sourceUri,
                  'uri',
                  source.uri,
                ),
          ),
        );
      }
    }
  });
  test('requires a const mapping for custom parameter defaults', () async {
    const mappings = [
      TypeMapping(
        type: 'string',
        format: 'station-id',
        dartType: 'StationId',
        importUrl: 'package:domain/types.dart',
        codec: TypeMappingCodec(
          importUrl: 'package:domain/codecs.dart',
          fromJson: 'read',
          toJson: 'write',
        ),
      ),
    ];
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('$_base/$family.$ext');
        final GenerationResult plain = await const SwaggerParserRunner()
            .generate(
              source,
              config: const GenerationConfig(typeMappings: mappings),
            );
        expect(plain.diagnostics, isEmpty);
        await expectLater(
          const SwaggerParserRunner().generate(
            source,
            config: const GenerationConfig(
              typeMappings: mappings,
              applyParameterDefaults: true,
            ),
          ),
          throwsA(
            isA<GenerationException>()
                .having(
                  (e) => e.message,
                  'message',
                  contains('getStations/stationId'),
                )
                .having(
                  (e) => e.diagnostics.single.code,
                  'code',
                  'invalidParameterDefault',
                ),
          ),
        );
      }
    }
  });
}
