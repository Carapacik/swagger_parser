@TestOn('vm')
@Timeout(Duration(minutes: 8))
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/collection_composition_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test(
    'builds collection and allOf regressions with all serializers',
    () async {
      final Directory dir = await Directory('test')
          .createTemp('generated_collections_');
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
      const loader = FileSchemaSourceLoader();
      final Object? values = jsonDecode(
        await File('../swagger_parser/test/fixtures/collections/values.json')
            .readAsString(),
      );
      final folders = <String>[];
      for (final group in ['collections', 'composition/all_of']) {
        for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
          for (final DtoSerializer serializer in DtoSerializer.values) {
            final folder =
                '${group.replaceAll('/', '_')}_${version}_${serializer.name}';
            folders.add(folder);
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult result = await const SwaggerParserRunner()
                  .generate(
                    await loader.loadPath(
                      '../swagger_parser/test/fixtures/$group/$version.$ext',
                    ),
                    loader: loader,
                    config: GenerationConfig(
                      serializer: serializer,
                      generateValidators: true,
                      httpClient: HttpClientBackend.dio,
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
              '${folder}_checks.dart',
              collectionCompositionDriver(
                folder,
                group,
                version,
                jsonEncode(values),
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
        await dart([
          'test',
          '--platform=chrome',
          '${dir.path}/checks_test.dart',
        ]);
      }
    },
  );
}
