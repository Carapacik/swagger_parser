@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/parameter_defaults_driver.dart';

void main() {
  test('builds parameter defaults for each family and transport', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_parameter_defaults_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String source) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult run = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      expect(
        run.exitCode,
        0,
        reason: '${args.join(' ')}\n${run.stdout}\n${run.stderr}',
      );
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final enabled in [false, true]) {
            final folder = '${family}_${backend.name}_${mode.name}_$enabled';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await const FileSchemaSourceLoader().loadPath(
                  '../swagger_parser/test/fixtures/parameter_defaults/$family.$ext',
                ),
                config: GenerationConfig(
                  httpClient: backend,
                  responseMode: mode,
                  applyParameterDefaults: enabled,
                  typeMappings: const [
                    TypeMapping(
                      type: 'string',
                      format: 'station-id',
                      dartType: 'StationId',
                      importUrl:
                          'package:swagger_parser_tests/object_types.dart',
                      codec: TypeMappingCodec(
                        importUrl:
                            'package:swagger_parser_tests/object_codecs.dart',
                        fromJson: 'stationIdFromJson',
                        toJson: 'stationIdToJson',
                      ),
                      defaults: [
                        TypeMappingDefault(
                          value: 'unknown',
                          importUrl: 'package:swagger_parser_tests/object_defaults.dart',
                          constant: 'unknownStationId',
                        ),
                      ],
                    ),
                  ],
                ),
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              expected ??= files;
              expect(files, expected);
            }
            for (final MapEntry<String, String> file in expected!.entries) {
              await write('$folder/${file.key}', file.value);
            }
            await write(
              '${folder}_test.dart',
              parameterDefaultsDriver(
                folder,
                backend,
                enabled: enabled,
                cookie: family != 'v2',
              ),
            );
          }
        }
      }
    }
    for (final family in ['v3_0', 'v3_1', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final enabled in [false, true]) {
          final folder = 'object_${family}_${backend.name}_$enabled';
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult
            result = await const SwaggerParserRunner().generate(
              await const FileSchemaSourceLoader().loadPath(
                '../swagger_parser/test/fixtures/parameter_defaults/object_$family.$ext',
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
          }
          for (final MapEntry<String, String> file in expected!.entries) {
            await write('$folder/${file.key}', file.value);
          }
          await write(
            '${folder}_test.dart',
            objectParameterDefaultsDriver(folder, backend, enabled: enabled),
          );
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', dir.path]);
  });
}
