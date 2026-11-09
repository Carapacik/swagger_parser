import 'package:swagger_parser/swagger_parser.dart';

/// Checks payloads and transport metadata without network requests.
String untypedResponseDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode, {
  required bool original,
  required bool streamBinary,
}) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  final bool wrapped = original && !all;
  String value(String method, String type) => all
      ? '(await root.api.$method() as api.${type}200).value'
      : wrapped
      ? '(await root.api.$method()).data'
      : 'await root.api.$method()';
  return '''
import 'dart:async';
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  late Probe probe;
  late api.Api root;
  setUp(() {
    probe = Probe();
    ${http ? "root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); root = api.Api(dio);"}
  });
  test('reads every JSON value without a DTO', () async {
    for (final Object? input in [<String, Object?>{'name': 'North'}, [1, 'two', null], 'North', 42, 1.5, true, null]) {
      probe.body = jsonEncode(input);
      expect(${value('json', 'Json')}, input);
      expect(${value('emptySchema', 'EmptySchema')}, input);
      expect(${value('jsonSuffix', 'JsonSuffix')}, input);
    }
  });
  test('uses declared media and preserves typed DTOs', () async {
    probe.body = 'North';
    probe.media = 'text/plain';
    expect(${value('text', 'Text')}, 'North');
    probe.media = 'application/octet-stream';
    final bytes = ${value('bytes', 'Bytes')};
    expect(${streamBinary ? "await bytes${wrapped && backend == HttpClientBackend.dio ? '!' : ''}.expand((chunk) => chunk).toList()" : 'bytes'}, utf8.encode('North'));
    probe.media = 'application/json';
    probe.body = '{"name":"North"}';
    final station = ${value('station', 'Station')};
    expect(station${wrapped && backend == HttpClientBackend.dio ? '!' : ''}.name, 'North');
  });
  test('keeps responses without content bodyless', () async {
    probe.body = '{"success":true}';
    ${all ? 'expect(await root.api.absent(), isA<api.Absent200>());' : 'await root.api.absent();'}
    probe.body = '';
    probe.status = 204;
    ${all ? 'expect(await root.api.noContent(), isA<api.NoContent204>());' : 'await root.api.noContent();'}
    probe.status = ${all ? '400' : '200'};
    ${all ? 'expect(await root.api.onlyError(), isA<api.OnlyError400>());' : 'await root.api.onlyError();'}
  });
  test('reads streams before the source closes', () async {
    for (final method in ['events', 'records'${streamBinary ? ", 'bytes'" : ''}]) {
      final source = StreamController<List<int>>();
      probe.chunks = source.stream;
      probe.media = method == 'events' ? 'text/event-stream' : method == 'records' ? 'application/jsonl' : 'application/octet-stream';
      final Stream<Object?> stream;
      if (method == 'events') {
        stream = ${value('events', 'Events')}${wrapped && backend == HttpClientBackend.dio ? '!' : ''};
      } ${streamBinary ? "else if (method == 'bytes') { stream = ${value('bytes', 'Bytes')}${wrapped && backend == HttpClientBackend.dio ? '!' : ''}; }" : ''} else {
        stream = ${value('records', 'Records')}${wrapped && backend == HttpClientBackend.dio ? '!' : ''};
      }
      final first = stream.first;
      source.add(utf8.encode(method == 'events' ? 'data: North\\n\\n' : method == 'records' ? '"North"\\n' : 'North'));
      final item = await first.timeout(const Duration(seconds: 2));
      expect(item, method == 'events' ? {'data': 'North', 'event': 'message'} : method == 'records' ? 'North' : utf8.encode('North'));
      await source.close();
    }
  });
  ${wrapped ? '''
  test('exposes status, headers, and the original body', () async {
    probe.body = '{"success":true}';
    final api.${backend == HttpClientBackend.dio ? 'Response' : 'HttpResponse'}<Object?> result = await root.api.json();
    final response = ${backend == HttpClientBackend.dio ? 'result' : 'result.response'};
    expect(result.data, {'success': true});
    expect(response.statusCode, 200);
    expect(response.${http ? "headers['x-trace']" : "headers.value('x-trace')"}, 'trace');
    ${http ? "expect(response, isA<http.Response>()); expect((response as http.Response).body, probe.body);" : "expect(response.requestOptions.uri.path, '/json');"}
    ${backend == HttpClientBackend.dio ? "expect(response.statusMessage, 'OK'); expect(response.extra['adapter'], true);" : ''}
    probe.body = '{"name":"North"}';
    final station = await root.api.station(options: ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"});
    expect(station.data${backend == HttpClientBackend.dio ? '!' : ''}.name, 'North');
    expect(${backend == HttpClientBackend.dio ? 'station' : 'station.response'}.statusCode, 200);
    probe.body = '{"success":true}';
    final empty = await root.api.absent();
    ${backend == HttpClientBackend.dio
            ? "expect(empty.statusCode, 200); final Response<dynamic> raw = empty; expect(raw.data, {'success': true});"
            : http
            ? "expect((empty.response as http.Response).body, probe.body);"
            : "expect(empty.response.data, {'success': true});"}
  });
  ''' : ''}
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  Stream<List<int>>? chunks;
  String body = 'null';
  String media = 'application/json';
  int status = 200;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    return http.StreamedResponse(chunks ?? Stream.value(utf8.encode(body)), status,
      headers: {'content-type': media, 'x-trace': 'trace'}, request: request, reasonPhrase: 'OK');
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    await stream?.drain<void>();
    return ResponseBody((chunks ?? Stream.value(utf8.encode(body))).map(Uint8List.fromList), status, headers: {'content-type': [media], 'x-trace': ['trace']}, statusMessage: 'OK')..extra['adapter'] = true;
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}

/// Exercises Retrofit's native Object decoder.
const nativeObjectClient = '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'native.g.dart';
@RestApi()
abstract class NativeClient {
  factory NativeClient(Dio dio) = _NativeClient;
  @GET('/json')
  Future<Object?> json();
  @GET('/wrapped')
  Future<HttpResponse<Object?>> wrapped();
}
''';

/// Checks native Retrofit output with all JSON value kinds.
const nativeObjectDriver = '''
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'native.dart';

void main() {
  test('decodes Object? with native Retrofit', () async {
    final probe = Probe();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe;
    addTearDown(dio.close);
    final client = NativeClient(dio);
    for (final Object? value in [<String, Object?>{'name': 'North'}, [1, null], 'North', 42, 1.5, true, null]) {
      probe.body = jsonEncode(value);
      expect(await client.json(), value);
      final wrapped = await client.wrapped();
      expect(wrapped.data, value);
      expect(wrapped.response.statusCode, 200);
    }
    probe.body = '';
    expect(await client.json(), isNull);
  });
}
class Probe implements HttpClientAdapter {
  String body = 'null';
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async =>
      ResponseBody.fromString(body, 200, headers: {'content-type': ['application/json']});
  @override
  void close({bool force = false}) {}
}
''';
