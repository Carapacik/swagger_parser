@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/consumer_matrix.dart';
import 'support/optional_nullable_parameters_driver.dart';

void main() {
  test(
    'sends optional nullable parameters with every serializer and HTTP client',
    () async {
      final Directory dir = await Directory('test')
          .createTemp('generated_optional_nullable_parameters_');
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
        'analyzer:\n  language:\n    strict-casts: true\n'
            '    strict-inference: true\n    strict-raw-types: true\n',
      );
      const loader = FileSchemaSourceLoader();
      final folders = <String>[];
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          if (!isFocusedConsumer(serializer, backend)) {
            continue;
          }
          final folder = '${serializer.name}_${backend.name}';
          folders.add(folder);
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await loader.loadPath(
                    '../swagger_parser/test/fixtures/nullable_parameters/'
                    'v3_2.$ext',
                  ),
                  loader: loader,
                  config: GenerationConfig(
                    serializer: serializer,
                    httpClient: backend,
                  ),
                );
            // The required nullable query parameter skips one operation.
            expect(result.diagnostics, hasLength(1));
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
            optionalNullableParametersDriver(folder, backend),
          );
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
      await dart(['analyze', '--fatal-infos', dir.path]);
      await dart(['test', '${dir.path}/checks_test.dart']);
    },
  );
}
