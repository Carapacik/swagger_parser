@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';
import 'support/enum_value_types_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('compiles scalar enum values and JSON results without casts', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_enum_types_');
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
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      '../swagger_parser/test/fixtures/enum_values/value_types.yaml',
    );
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final UnknownValueMode mode in UnknownValueMode.values) {
        final folder = '${serializer.name}_${mode.name}';
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(
              source,
              config: GenerationConfig(
                serializer: serializer,
                unknownEnumValues: mode,
              ),
            );
        expect(result.diagnostics, isEmpty);
        for (final GeneratedFile file in result.files) {
          await write('$folder/${file.relativePath}', file.content);
        }
        await write('${folder}_test.dart', enumValueTypesDriver(folder, mode));
      }
    }
    final String checks = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', checks]);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', checks]);
    }
  });
}
