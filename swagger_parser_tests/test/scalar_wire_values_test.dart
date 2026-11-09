@TestOn('vm')
@Timeout(Duration(minutes: 8))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';
import 'support/scalar_wire_values_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('preserves dates, integers, and discriminator keys on VM and web', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_scalars_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String text) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(text);
    }

    Future<void> dart(List<String> args) async {
      final watch = Stopwatch()..start();
      stdout.writeln('Start: ${args.join(' ')}');
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')} (${watch.elapsed.inSeconds}s): '
        '${(result.stdout as String).trim().split('\n').last}',
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
    for (final (scenario, fixture) in [
      ('dates', 'scalar_formats/dates'),
      ('int64', 'scalar_formats/int64'),
      ('discriminator_keys', 'fixed_discriminators/wire_keys'),
    ]) {
      final String wire = await File(
        '../swagger_parser/test/fixtures/$fixture/values.json',
      ).readAsString();
      for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          final folder = '${scenario}_${version}_${serializer.name}';
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult
            result = await const SwaggerParserRunner().generate(
              await const FileSchemaSourceLoader().loadPath(
                '../swagger_parser/test/fixtures/$fixture/$version.$ext',
              ),
              config: GenerationConfig(
                serializer: serializer,
                typeMappings: [
                  if (scenario == 'int64')
                    TypeMapping(
                      schema:
                          '${version == 'v2' ? '#/definitions/' : '#/components/schemas/'}DecimalId',
                      dartType: 'BigInt',
                      importUrl: 'dart:core',
                      codec: const TypeMappingCodec(
                        importUrl:
                            'package:swagger_parser_tests/int64_codec.dart',
                        fromJson: 'readInt64',
                        toJson: 'writeInt64',
                      ),
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
            if (scenario == 'dates') {
              expect(files.values.join(), isNot(contains('DateTime')));
              expect(files.values.join(), isNot(contains('package:intl')));
            }
            if (scenario == 'int64') {
              expect(files.values.join(), contains('int value'));
            }
          }
          for (final MapEntry<String, String> f in expected!.entries) {
            await write('$folder/${f.key}', f.value);
          }
          await write(
            '${folder}_test.dart',
            scalarWireValuesDriver(scenario, folder, wire),
          );
        }
      }
    }
    final String checks = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', checks]);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '--concurrency=1', checks]);
    }
  });
}
