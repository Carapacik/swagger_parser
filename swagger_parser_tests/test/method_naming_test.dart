@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/method_naming_driver.dart';

void main() {
  test('builds and calls both method naming modes for each family and client', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_method_names_');
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
          for (final (enabled, rename) in [
            (false, false),
            (true, false),
            if (family == 'v3_2') (true, true),
          ]) {
            final folder =
                '${family}_${backend.name}_${mode.name}_${enabled}_$rename';
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              const loader = FileSchemaSourceLoader();
              final GenerationResult
              result = await const SwaggerParserRunner().generate(
                await loader.loadPath(
                  '../swagger_parser/test/fixtures/method_naming/$family.$ext',
                ),
                loader: loader,
                config: GenerationConfig(
                  httpClient: backend,
                  responseMode: mode,
                  usePathForMethodNames: enabled,
                  naming: NamingConfig(
                    replaceRules: [
                      if (rename)
                        const NameReplacementRule(
                          target: NamingTarget.methods,
                          pattern: '^get',
                          replacement: 'fetch',
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
              '${folder}_test.dart',
              methodNamingDriver(
                folder,
                backend,
                mode,
                enabled: enabled,
                rename: rename,
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
