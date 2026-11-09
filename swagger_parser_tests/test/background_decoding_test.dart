@TestOn('vm')
@Timeout(Duration(minutes: 15))
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/background_decoding_driver.dart';
import 'support/consumer_matrix.dart';
import 'support/test_platforms.dart';

void main() {
  test('decodes responses with every serializer and transport on VM and web', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_decoding_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String content) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> dart(List<String> args) async {
      final watch = Stopwatch()..start();
      stdout.writeln('Start: ${args.join(' ')}');
      final ProcessResult result = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')} (${watch.elapsed.inSeconds}s): '
        '${(result.stdout as String).trim().split('\n').last}',
      );
      expect(
        result.exitCode,
        0,
        reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
      );
    }

    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final HttpResponse response = request.response;
      response.headers
        ..set('Access-Control-Allow-Origin', '*')
        ..set('Access-Control-Allow-Headers', '*')
        ..contentType = ContentType.json;
      if (request.method == 'OPTIONS') {
        await response.close();
        return;
      }
      final String scenario = request.uri.path.split('/').last;
      if (scenario == 'wait') {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (scenario == 'chunks') {
        response
          ..bufferOutput = false
          ..write('{"name":');
        await response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        response.write('"North","state":"paused"}');
      } else if (scenario == 'empty') {
        response.statusCode = 204;
      } else if (scenario == 'badJson') {
        response.write('{');
      } else if (scenario == 'badDto') {
        response.write('{"name":{},"state":"paused"}');
      } else if (scenario == 'badEnum') {
        response.write('{"name":"North","state":"missing"}');
      } else if (scenario == 'error') {
        response
          ..statusCode = 400
          ..write('{"message":"Missing station"}');
      } else if (scenario == 'errorText') {
        response.statusCode = 400;
        response.headers.contentType = ContentType.text;
        response.write('Missing station');
      } else if (scenario == 'states') {
        response.write('["active","paused"]');
      } else if (scenario == 'state') {
        response.write('"paused"');
      } else if (scenario == 'nullable' || scenario == 'nullableStates') {
        response.write('null');
      } else {
        response.write(jsonEncode({'name': 'Север', 'state': 'paused'}));
      }
      await response.close();
    });
    final baseUrl = 'http://127.0.0.1:${server.port}';
    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          for (final background in [false, true]) {
            for (final wrapped
                in mode == ResponseMode.firstSuccess ? [false, true] : [true]) {
              final folder =
                  '${serializer.name}_${backend.name}_${mode.name}_$background${wrapped ? '' : '_raw'}';
              Map<String, String>? expected;
              for (final ext in ['json', 'yaml']) {
                final GenerationResult
                result = await const SwaggerParserRunner().generate(
                  await const FileSchemaSourceLoader().loadPath(
                    '../swagger_parser/test/fixtures/extraction/background_decoding/v3_2.$ext',
                  ),
                  config: GenerationConfig(
                    serializer: serializer,
                    httpClient: backend,
                    responseMode: mode,
                    decodeResponsesInBackground: background,
                    originalHttpResponse: wrapped,
                  ),
                );
                expect(result.diagnostics, isEmpty);
                final Map<String, String> files = {
                  for (final f in result.files) f.relativePath: f.content,
                };
                expected ??= files;
                expect(files, expected);
              }
              for (final MapEntry<String, String> file in expected!.entries) {
                await write('$folder/${file.key}', file.value);
              }
              await write(
                '${folder}_test.dart',
                backgroundDecodingDriver(
                  folder,
                  backend,
                  mode,
                  baseUrl,
                  wrapped: wrapped,
                ),
              );
            }
          }
        }
      }
    }
    await write(
      'decoder_test.dart',
      decoderDriver('plain_dio_firstSuccess_true'),
    );
    final String checks = await groupConsumerTests(dir);
    // Keep the isolate library outside the browser entry point.
    await write(
      'worker_test.dart',
      workerDriver('plain_dio_firstSuccess_true'),
    );
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart([
      'test',
      '--concurrency=1',
      checks,
      '${dir.path}/worker_test.dart',
    ]);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', '--concurrency=1', checks]);
    }
  });
}
