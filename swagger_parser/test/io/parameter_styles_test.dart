@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/parameter_styles';

void main() {
  test('applies path allowReserved only from OpenAPI 3.2', () async {
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      '$_base/path_allow_reserved.yaml',
    );
    for (final version in ['3.0.0', '3.1.2', '3.2.1']) {
      final String yaml = source.content.replaceFirst('3.0.0', version);
      Future<String> client(String input) async {
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(
              SchemaSource.yaml(input),
              config: const GenerationConfig(
                httpClient: HttpClientBackend.http,
              ),
            );
        if (version == '3.1.2' && input.contains('allowReserved:')) {
          final Diagnostic warning = result.diagnostics.single;
          expect(warning.severity, DiagnosticSeverity.warning);
          expect(
            warning.documentPath,
            '/paths/~1items~1{id}/get/parameters/0/allowReserved',
          );
          expect(warning.location?.line, 13);
        } else {
          expect(result.diagnostics, isEmpty);
        }
        return result.files
            .singleWhere((f) => f.relativePath.endsWith('_client.dart'))
            .content;
      }

      final String withFlag = await client(yaml);
      final String withoutFlag = await client(
        yaml.replaceFirst('          allowReserved: true\n', ''),
      );
      expect(withFlag, contains('getItem('));
      expect(withFlag == withoutFlag, version != '3.2.1', reason: version);
    }
  });

  test(
    'defaults to rejection and supports per-input compatibility modes',
    () async {
      expect(
        const GenerationConfig().delimitedQueryArrayExplode,
        DelimitedQueryArrayExplodeMode.reject,
      );
      for (final ext in ['json', 'yaml']) {
        expect(
          (await CliConfig.load(configPath: '$_base/default.$ext'))
              .generation
              .delimitedQueryArrayExplode,
          DelimitedQueryArrayExplodeMode.reject,
        );
        final List<CliConfig> inputs = await CliConfig.loadAll(
          configPath: '$_base/inputs.$ext',
        );
        expect(inputs.map((c) => c.generation.delimitedQueryArrayExplode), [
          DelimitedQueryArrayExplodeMode.join,
          DelimitedQueryArrayExplodeMode.repeat,
          DelimitedQueryArrayExplodeMode.reject,
        ]);
        await expectLater(
          CliConfig.load(configPath: '$_base/invalid_config.$ext'),
          throwsFormatException,
        );
      }
      for (final Object invalid in [true, 1, 'ignore']) {
        expect(
          () => PipelineConfig.fromMap({
            'generation': {'delimited_query_array_explode': invalid},
          }),
          throwsFormatException,
        );
      }
    },
  );

  for (final version in ['3.0.3', '3.1.1', '3.2.0']) {
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final DelimitedQueryArrayExplodeMode mode
          in DelimitedQueryArrayExplodeMode.values) {
        test(
          '$version applies ${mode.name} to delimited arrays for ${backend.name}',
          () async {
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              final SchemaSource source = await const FileSchemaSourceLoader()
                  .loadPath('$_base/styles.$ext');
              final GenerationResult result = await const SwaggerParserRunner()
                  .generate(
                    SchemaSource(
                      source.content.replaceFirst('3.0.3', version),
                      format: source.format,
                      uri: source.uri,
                    ),
                    config: GenerationConfig(
                      httpClient: backend,
                      delimitedQueryArrayExplode: mode,
                    ),
                  );
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final String client = files['stations/stations_client.dart']!;
              final reject = mode == DelimitedQueryArrayExplodeMode.reject;
              expect(client.contains('getStations('), !reject);
              expect(client, contains('getControls('));
              expect(client, isNot(contains('getObjects(')));
              final Iterable<Diagnostic> skipped = result.diagnostics.where(
                (d) => d.code == 'unsupportedClientOperation',
              );
              expect(skipped, hasLength(reject ? 2 : 1));
              final Iterable<Diagnostic> warnings = result.diagnostics.where(
                (d) => d.code == 'delimitedQueryArrayExplode',
              );
              expect(warnings, hasLength(reject ? 0 : 2));
              for (final warning in warnings) {
                expect(warning.severity, DiagnosticSeverity.warning);
                expect(warning.message, contains('Applied ${mode.name}'));
                expect(warning.sourceUri, source.uri);
                expect(
                  warning.documentPath,
                  startsWith('/paths/~1stations/get/parameters/'),
                );
              }
            }
          },
        );
      }
    }
  }
}
