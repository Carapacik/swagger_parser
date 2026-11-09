@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/type_mappings_driver.dart';

void main() {
  test('builds custom scalars with all serializers and transports', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_type_mappings_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String text) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      expect(
        result.exitCode,
        0,
        reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
      );
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    final drivers = <String>[];
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final version
            in backend == HttpClientBackend.dio
                ? ['2_0', '3_0', '3_1', '3_2']
                : ['3_2']) {
          final CliConfig config = await CliConfig.load(
            configPath:
                '../swagger_parser/test/fixtures/type_mappings/config_v$version.yaml',
          );
          for (final ResponseMode mode
              in version == '3_2'
                  ? ResponseMode.values
                  : [ResponseMode.firstSuccess]) {
            final folder =
                '${serializer.name}_${backend.name}_${version}_${mode.name}';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await const FileSchemaSourceLoader().loadPath(
                  '../swagger_parser/test/fixtures/type_mappings/mapped_v$version.$ext',
                ),
                config: GenerationConfig(
                  usePresenceRecords: true,
                  inferMissingRequired: false,
                  serializer: serializer,
                  httpClient: backend,
                  responseMode: mode,
                  typeMappings: config.generation.typeMappings,
                ),
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              expected ??= files;
              expect(files, expected);
            }
            for (final MapEntry<String, String> file in expected!.entries) {
              await write('$folder/${file.key}', file.value);
            }
            await write(
              '$folder.dart',
              typeMappingsDriver(
                folder,
                version,
                serializer,
                backend,
                allStatuses: mode == ResponseMode.allStatuses,
              ),
            );
            drivers.add('${dir.path}/$folder.dart');
          }
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    for (final driver in drivers) {
      await dart(['--enable-asserts', driver]);
    }
  });
}
