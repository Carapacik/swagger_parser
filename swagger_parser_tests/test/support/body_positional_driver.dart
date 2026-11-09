import 'package:swagger_parser/swagger_parser.dart';

/// Checks body styles and transport settings against captured requests.
String bodyPositionalDriver(
  String folder,
  HttpClientBackend backend, {
  required bool positional,
}) {
  final http = backend == HttpClientBackend.http;
  String body(String value) => '${positional ? '' : 'body: '}$value';
  final cancel = http ? 'abortTrigger: stop.future' : 'cancelToken: stop';
  final settings = "$cancel, extra: {'trace': 'call'}, options: options";
  return '''
import 'dart:async';
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  for (final withOptions in [false, true]) {
    test('sends each body with options=\$withOptions', () async {
      final probe = Probe();
      final stop = ${http ? 'Completer<void>()' : 'CancelToken()'};
      final options = withOptions ? ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"} : null;
      ${http ? '''
      final transport = probe;
      final root = api.Api(transport, baseUrl: Uri.parse('https://example.test'), prepareRequest: (request, extra) {
        expect(extra, {'trace': 'call'});
        expect((request as http.Abortable).abortTrigger, same(stop.future));
      });
      ''' : '''
      final transport = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe;
      transport.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
        expect(request.extra, {'trace': 'call'});
        expect(request.cancelToken, same(stop));
        handler.next(request);
      }));
      final root = api.Api(transport);
      '''}
      addTearDown(transport.close);
      const station = api.Station(name: 'North');
      await root.api.updateStation(${body('station')}, id: '42', locale: 'en', xRevision: 2, $settings);
      expect(probe.method, 'PUT');
      expect(probe.uri.path, '/stations/42');
      expect(probe.uri.queryParameters, {'locale': 'en'});
      expect(probe.header('x-revision').toString(), '2');
      expect(probe.header('x-call'), withOptions ? 'yes' : null);
      expect(jsonDecode(probe.body), {'name': 'North'});

      await root.api.requiredNullable(${body('null')}, $settings);
      expect(probe.body, 'null');
      await root.api.requiredNullable(${body("'North'")}, $settings);
      expect(jsonDecode(probe.body), 'North');
      await root.api.onlyNull(${body('null')}, $settings);
      expect(probe.body, 'null');

      await root.api.optionalBody($settings);
      expect(probe.body, isEmpty);
      await root.api.optionalBody(body: station, $settings);
      expect(jsonDecode(probe.body), {'name': 'North'});
      await root.api.optionalNullable($settings);
      expect(probe.body, isEmpty);
      await root.api.optionalNullable(body: null, $settings);
      expect(probe.body, isEmpty);
      await root.api.optionalNullable(sendNullBody: true, $settings);
      expect(probe.body, 'null');
      await root.api.optionalNullable(body: 'North', $settings);
      expect(jsonDecode(probe.body), 'North');

      await root.api.listBody(${body('const [station]')}, $settings);
      expect(jsonDecode(probe.body), [{'name': 'North'}]);
      await root.api.rawBody(${body('const [1, 2, 255]')}, $settings);
      expect(probe.bytes, [1, 2, 255]);
      await root.api.submitForm(station: 'North & West', body2: 'label', $settings);
      expect(Uri.splitQueryString(probe.body), {'station': 'North & West', 'body': 'label'});
      await root.api.upload(file: ${http ? "http.MultipartFile.fromString('file', 'payload', filename: 'file.txt')" : "MultipartFile.fromString('payload', filename: 'file.txt')"}, $settings);
      expect(probe.header('content-type').toString(), startsWith('multipart/form-data;'));
      expect(probe.body, contains('name="file"'));
      expect(probe.body, contains('payload'));
      await root.api.empty($settings);
      expect(probe.method, 'GET');
      expect(probe.body, isEmpty);
    });
  }
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late String method;
  late Uri uri;
  late Map<String, Object?> headers;
  late List<int> bytes;
  String get body => utf8.decode(bytes);
  Object? header(String name) => headers.entries.where((e) => e.key.toLowerCase() == name).firstOrNull?.value;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    method = request.method;
    uri = request.url;
    bytes = await request.finalize().expand((v) => v).toList();
    headers = Map.of(request.headers);
    return http.StreamedResponse(Stream.value(utf8.encode(uri.path == '/empty' ? '' : '{"name":"Reply"}')), uri.path == '/empty' ? 204 : 200, headers: {'content-type': 'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    method = options.method;
    uri = options.uri;
    headers = Map.of(options.headers);
    bytes = await stream?.expand((v) => v).toList() ?? [];
    return ResponseBody.fromString(uri.path == '/empty' ? '' : '{"name":"Reply"}', uri.path == '/empty' ? 204 : 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}
