@TestOn('vm')
@Timeout(Duration(minutes: 12))
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/binary_network_driver.dart';
import 'support/binary_response_driver.dart';
import 'support/consumer_matrix.dart';
import 'support/test_platforms.dart';

void main() {
  test('builds binary responses with every serializer and HTTP client', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_binary_responses_');
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
    final payloads = <String, List<int>>{};
    for (final (name, file) in [
      ('pdf', 'report.pdf'),
      ('spreadsheet', 'sheet.xlsx'),
      ('bytes', 'arbitrary.bin'),
    ]) {
      payloads[name] = await File(
        '../swagger_parser/test/fixtures/responses/binary/$file',
      ).readAsBytes();
    }
    await write(
      'payloads.dart',
      'const payloads = <String, List<int>>${jsonEncode(payloads)};',
    );
    const loader = FileSchemaSourceLoader();
    final folders = <String>[];
    for (final version in ['v2', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          if (!isFocusedConsumer(serializer, backend)) {
            continue;
          }
          for (final ResponseMode mode in ResponseMode.values) {
            for (final stream in [false, true]) {
              for (final wrapped in [
                false,
                if (mode == ResponseMode.firstSuccess) true,
              ]) {
                final folder =
                    '${version}_${serializer.name}_${backend.name}_${mode.name}_${stream}_$wrapped';
                folders.add(folder);
                Map<String, String>? expected;
                for (final ext in ['json', 'yaml']) {
                  final fixture = 'responses/binary/$version.$ext';
                  final GenerationResult result =
                      await const SwaggerParserRunner().generate(
                        await loader.loadPath(
                          '../swagger_parser/test/fixtures/$fixture',
                        ),
                        loader: loader,
                        config: GenerationConfig(
                          serializer: serializer,
                          httpClient: backend,
                          responseMode: mode,
                          streamBinaryResponses: stream,
                          originalHttpResponse: wrapped,
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
                  binaryResponseDriver(
                    folder,
                    version,
                    backend,
                    mode,
                    stream: stream,
                    wrapped: wrapped,
                  ),
                );
              }
            }
          }
        }
      }
    }
    final HttpServer server = await binaryServer(payloads['pdf']!);
    addTearDown(() => server.close(force: true));
    await write('network_checks.dart', binaryNetworkDriver(server.port));
    await write(
      'checks_test.dart',
      [
        "import 'package:test/test.dart';",
        "import 'network_checks.dart' as network;",
        for (final (i, folder) in folders.indexed)
          "import '${folder}_checks.dart' as check$i;",
        'void main() {',
        "group('network', network.main);",
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
