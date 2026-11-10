import 'package:swagger_parser/swagger_parser.dart';

/// Checks bodyless responses before payload decoding and transport wrapping.
String bodylessSuccessDriver(
  String folder,
  HttpClientBackend backend,
  String kind, {
  required bool original,
}) {
  final http = backend == HttpClientBackend.http;
  final stream = kind == 'stream';
  final String payload = switch (kind) {
    'json' => 'api.Reply?',
    'text' => 'String?',
    'bytes' => 'List<int>?',
    _ => 'Stream<List<int>>',
  };
  final type = original
      ? 'Future<api.${backend == HttpClientBackend.dio ? 'Response' : 'HttpResponse'}<$payload>>'
      : stream
      ? payload
      : 'Future<$payload>';
  final data = original ? 'result.data' : 'result';
  final body = kind == 'json' ? '{"text":"reply"}' : 'reply';
  final media = kind == 'json'
      ? 'application/json'
      : kind == 'text'
      ? 'text/plain'
      : 'application/octet-stream';
  final String value = switch (kind) {
    'json' => '$data!.text',
    'text' => data,
    'bytes' => 'utf8.decode($data!)',
    _ =>
      'utf8.decode(await $data${original && backend == HttpClientBackend.dio ? '!' : ''}.expand((chunk) => chunk).toList())',
  };
  return '''
${http || kind == 'bytes' || stream ? "import 'dart:convert';" : ''}
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  for (final withOptions in [false, true]) {
    test('handles declared empty success with options=\$withOptions', () async {
      final probe = Probe();
      ${http ? "addTearDown(probe.close); final client = api.Api(probe, baseUrl: Uri.parse('https://example.test')).api;" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final client = api.Api(dio).api;"}
      final options = withOptions ? ${http ? 'api.HttpRequestOptions()' : 'Options()'} : null;
      for (final status in [200, 204]) {
        probe.status = status;
        probe.body = status == 204 ? '' : '$body';
        final $type pending = client.sendMessage(options: options);
        final result = ${stream && !original ? '' : 'await '}pending;
        if (status == 204) {
          ${stream ? 'expect(await $data${original && backend == HttpClientBackend.dio ? '!' : ''}.toList(), isEmpty);' : 'expect($data, isNull);'}
        } else {
          expect($value, 'reply');
        }
        ${original ? "expect(${backend == HttpClientBackend.dio ? 'result' : 'result.response'}.statusCode, status);" : ''}
      }
      ${kind == 'json' ? '''
      probe.status = 200;
      for (final body in ['', 'null', '{}', '{']) {
        probe.body = body;
        await expectLater(client.sendMessage(options: options), throwsA(anything));
      }
      ''' : ''}
      for (final status in [203, 500]) {
        probe.status = status;
        probe.body = '';
        await expectLater(client.sendMessage(options: options)${stream && !original ? '.toList()' : ''}, throwsA(anything));
      }
    });
  }
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  int status = 200;
  String body = '';
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    return http.StreamedResponse(Stream.value(utf8.encode(body)), status, headers: {'content-type': '$media'}, request: request);
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    await requestStream?.drain<void>();
    return ResponseBody.fromString(body, status, headers: {'content-type': ['$media']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
