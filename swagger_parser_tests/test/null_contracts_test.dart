@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/null_contracts_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds nullable unions and consistent null parameters', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_null_contracts_');
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
      stdout.writeln(
        '${args.join(' ')}: ${(run.stdout as String).trim().split('\n').last}',
      );
      expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    final folders = <String>[];
    Future<void> generate(
      String folder,
      String fixture,
      GenerationConfig config,
      String driver,
    ) async {
      folders.add(folder);
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            await const FileSchemaSourceLoader().loadPath(
              '../swagger_parser/test/fixtures/$fixture',
            ),
            config: config,
          );
      expect(result.diagnostics, isEmpty);
      for (final GeneratedFile file in result.files) {
        await write('$folder/${file.relativePath}', file.content);
      }
      await write('${folder}_checks.dart', driver);
    }

    for (final DtoSerializer serializer in DtoSerializer.values) {
      final folder = 'unions_${serializer.name}';
      await generate(
        folder,
        'nullable_unions/v3_1.yaml',
        GenerationConfig(serializer: serializer),
        nullableUnionDriver(folder),
      );
    }
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final include in [false, true]) {
        for (final defaults in [false, true]) {
          final folder = '${backend.name}_${include}_$defaults';
          await generate(
            folder,
            'null_parameters/v3_1.yaml',
            GenerationConfig(
              httpClient: backend,
              includeNullParameters: include,
              applyParameterDefaults: defaults,
            ),
            nullParametersDriver(
              folder,
              backend,
              include: include,
              defaults: defaults,
            ),
          );
        }
      }
    }
    await write(
      'checks_test.dart',
      [
        "import 'package:test/test.dart';",
        for (final (i, folder) in folders.indexed)
          "import '${folder}_checks.dart' as check$i;",
        'void main() {',
        for (final (i, folder) in folders.indexed)
          "group('$folder', check$i.main);",
        '}',
      ].join('\n'),
    );
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '${dir.path}/checks_test.dart']);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '${dir.path}/checks_test.dart']);
    }
  });
}
