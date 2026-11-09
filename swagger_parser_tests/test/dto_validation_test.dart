@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/dto_validation_driver.dart';

void main() {
  test('builds explicit DTO validators across versions and serializers', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_dto_validation_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String content) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
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
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final records in [false, true]) {
          final folder = '${version}_${serializer.name}_$records';
          Map<String, String>? baseline;
          for (final ext in ['json', 'yaml']) {
            const loader = FileSchemaSourceLoader();
            final GenerationResult
            result = await const SwaggerParserRunner().generate(
              await loader.loadPath(
                '../swagger_parser/test/fixtures/dto_validation/$version.$ext',
              ),
              loader: loader,
              config: GenerationConfig(
                serializer: serializer,
                generateValidators: true,
                usePresenceRecords: records,
              ),
            );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            baseline ??= files;
            expect(files, baseline);
          }
          for (final MapEntry<String, String> file in baseline!.entries) {
            await write('$folder/${file.key}', file.value);
          }
          await write(
            '${folder}_test.dart',
            dtoValidationDriver(folder, version, records: records),
          );
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', dir.path]);
  });
}
