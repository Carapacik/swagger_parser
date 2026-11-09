@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';
import 'support/tag_grouping_driver.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds and calls merged clients with distinct parameters', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_tag_groups_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String source) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(source);
    }

    Future<void> dart(List<String> args) async {
      final watch = Stopwatch()..start();
      stdout.writeln('Start: ${args.join(' ')}');
      final ProcessResult run = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')} (${watch.elapsed.inSeconds}s): '
        '${(run.stdout as String).trim().split('\n').last}',
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
    final folders = <String>[];
    for (final family in ['v2', 'v3_2', 'collisions']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final DtoSerializer serializer in DtoSerializer.values) {
            if (!isFocusedConsumer(serializer, backend)) {
              continue;
            }
            final folder =
                '${family}_${backend.name}_${mode.name}_${serializer.name}';
            folders.add(folder);
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await const FileSchemaSourceLoader().loadPath(
                  '../swagger_parser/test/fixtures/tag_grouping/$family.$ext',
                ),
                config: GenerationConfig(
                  httpClient: backend,
                  serializer: serializer,
                  responseMode: mode,
                  naming: const NamingConfig(
                    replaceRules: [
                      NameReplacementRule(
                        target: NamingTarget.clients,
                        pattern: '^(Internal|Public)',
                        replacement: '',
                      ),
                      NameReplacementRule(
                        target: NamingTarget.clients,
                        pattern: '^Erase.*',
                        replacement: '',
                      ),
                    ],
                  ),
                ),
              );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              expected ??= files;
              expect(files, expected);
            }
            for (final MapEntry<String, String> f in expected!.entries) {
              await write('$folder/${f.key}', f.value);
            }
            await write(
              '${folder}_checks.dart',
              tagGroupingDriver(
                folder,
                backend,
                mode,
                collision: family == 'collisions',
              ),
            );
          }
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
    await dart(['test', '--concurrency=1', '${dir.path}/checks_test.dart']);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '${dir.path}/checks_test.dart']);
    }
  });
}
