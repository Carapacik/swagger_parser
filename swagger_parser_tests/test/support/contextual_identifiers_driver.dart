import 'package:swagger_parser/swagger_parser.dart';

/// Checks contextual names and their wire values in compiled clients.
String contextualIdentifiersDriver(String folder, HttpClientBackend backend) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('preserves contextual field names and JSON keys', () {
    final api.Foo value = api.Foo(type: 'message', part: 'body');
    expect(value.type, 'message');
    expect(value.part, 'body');
    final json = {'type': 'message', 'part': 'body'};
    expect(value.toJson(), json);
    expect(api.Foo.fromJson(json).toJson(), json);
  });
  for (final withOptions in [false, true]) {
    test('preserves contextual method and query names with options=\$withOptions', () async {
      final probe = Probe();
      ${http ? "addTearDown(probe.close); final client = api.Api(probe, baseUrl: Uri.parse('https://example.test')).api;" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final client = api.Api(dio).api;"}
      final options = withOptions ? ${http ? 'api.HttpRequestOptions()' : 'Options()'} : null;
      final api.Foo value = await client.type(type: 'a b', part: 'x/y', options: options);
      expect(probe.uri!.path, '/filter');
      expect(probe.uri!.queryParameters, {'type': 'a b', 'part': 'x/y'});
      expect(value.type, 'a b');
      expect(value.part, 'x/y');
      await client.part(options: options);
      expect(probe.uri!.path, '/part');
    });
  }
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  Uri? uri;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    await request.finalize().drain<void>();
    return http.StreamedResponse(Stream.value(utf8.encode(uri!.path == '/part' ? '' : jsonEncode(uri!.queryParameters))), uri!.path == '/part' ? 204 : 200, headers: {'content-type': 'application/json'}, request: request);
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    uri = options.uri;
    await requestStream?.drain<void>();
    return ResponseBody.fromString(uri!.path == '/part' ? '' : jsonEncode(uri!.queryParameters), uri!.path == '/part' ? 204 : 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
