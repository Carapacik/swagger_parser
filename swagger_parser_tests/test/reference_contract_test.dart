@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/reference_contract_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds reference and alias contracts with every serializer', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_references_');
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
      stdout.writeln(
        '${args.join(' ')}: ${(result.stdout as String).trim().split('\n').last}',
      );
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
    }

    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    const loader = FileSchemaSourceLoader();
    final folders = <String>[];
    for (final version in [
      'v2',
      'v3_0',
      'v3_1',
      'v3_2',
      'dynamic_v3_1',
      'dynamic_v3_2',
    ]) {
      final bool dynamicRefs = version.startsWith('dynamic');
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final ResponseMode mode
            in dynamicRefs
                ? [ResponseMode.firstSuccess]
                : ResponseMode.values) {
          final folder = '${version}_${serializer.name}_${mode.name}';
          folders.add(folder);
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final fixture = dynamicRefs
                ? 'extraction/dynamic_references/$version.$ext'
                : 'references/$version.$ext';
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await loader.loadPath(
                    '../swagger_parser/test/fixtures/$fixture',
                  ),
                  loader: loader,
                  config: GenerationConfig(
                    serializer: serializer,
                    responseMode: mode,
                    generateValidators: true,
                    applyParameterDefaults: true,
                    inferMissingRequired: false,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            expected ??= files;
            expect(files, expected);
          }
          for (final MapEntry<String, String> file in expected!.entries) {
            await write('$folder/${file.key}', file.value);
          }
          await write(
            '${folder}_checks.dart',
            dynamicRefs
                ? dynamicReferenceDriver(folder)
                : referenceContractDriver(folder, version, mode),
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
