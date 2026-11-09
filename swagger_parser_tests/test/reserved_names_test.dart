@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/reserved_names_driver.dart';

void main() {
  test('builds protected names and preserves request keys', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_reserved_names_');
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
    final String value = await File(
      '../swagger_parser/test/fixtures/naming/reserved/value.json',
    ).readAsString();
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          for (final renamed in version == 'v3_2' ? [false, true] : [false]) {
            final folder =
                '${version}_${serializer.name}_${backend.name}_$renamed';
            Map<String, String>? baseline;
            for (final extension in ['json', 'yaml']) {
              final SchemaSource
              source = await const FileSchemaSourceLoader().loadPath(
                '../swagger_parser/test/fixtures/naming/reserved/$version.$extension',
              );
              final GenerationResult result = await const SwaggerParserRunner()
                  .generate(
                    source,
                    config: GenerationConfig(
                      serializer: serializer,
                      httpClient: backend,
                      naming: NamingConfig(
                        preserveSchemaCasing: renamed,
                        replaceRules: renamed
                            ? const [
                                NameReplacementRule(
                                  target: NamingTarget.models,
                                  pattern: r'^Response$',
                                  replacement: 'Dio',
                                ),
                                NameReplacementRule(
                                  target: NamingTarget.methods,
                                  pattern: r'^fromJson$',
                                  replacement: 'toJson',
                                ),
                              ]
                            : const [],
                      ),
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              baseline ??= files;
              expect(files, baseline);
            }
            for (final MapEntry<String, String> file in baseline!.entries) {
              await write('$folder/${file.key}', file.value);
            }
            await write(
              '${folder}_test.dart',
              reservedNamesDriver(
                folder,
                serializer,
                backend,
                renamed: renamed,
                value: value,
              ),
            );
          }
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', '--concurrency=1', dir.path]);
  });
}
