import 'package:swagger_parser/swagger_parser.dart';

/// Checks omitted, null, and explicit arguments at the transport boundary.
String parameterDefaultsDriver(
  String folder,
  HttpClientBackend backend, {
  required bool enabled,
  required bool cookie,
}) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  for (final withOptions in [false, true]) {
    test('sends defaults=$enabled with options=\$withOptions', () async {
      final probe = Probe();
      ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
      final options = withOptions ? ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"} : null;
      await root.api.getNative(id: '42', options: options);
      expect(probe.uri.path, '/native/42');
      expect(probe.uri.queryParameters['limit'], ${enabled ? "'25'" : 'isNull'});
      await root.api.getNative(id: '42', limit: null, options: options);
      expect(probe.uri.queryParameters, isEmpty);
      await root.api.getNative(id: '42', limit: 0, options: options);
      expect(probe.uri.queryParameters['limit'], '0');

      await root.api.getStations(requiredLimit: 7, options: options);
      expect(probe.uri.queryParameters['requiredLimit'], '7');
      expect(probe.uri.queryParameters['limit'], ${enabled ? "'25'" : 'isNull'});
      expect(probe.uri.queryParameters['archived'], ${enabled ? "'false'" : 'isNull'});
      expect(probe.uri.queryParameters['label'], ${enabled ? r"r'North $1'" : 'isNull'});
      expect(probe.uri.queryParameters['stationId'], ${enabled ? "'unknown'" : 'isNull'});
      expect(probe.uri.queryParameters['status'], ${enabled ? "'active'" : 'isNull'});
      expect(probe.uri.queryParametersAll['tags'], ${enabled ? "['north', 'west']" : 'isNull'});
      expect(probe.header('x-region'), ${enabled ? "'west'" : 'isNull'});
      ${cookie ? "expect(probe.header('cookie'), ${enabled ? "contains('session=guest')" : 'isNull'});" : ''}
      expect(probe.header('x-call'), withOptions ? 'yes' : null);
      await root.api.getStations(requiredLimit: 7, limit: null, archived: null, label: null, status: null, tags: null, stationId: null, xRegion: null, ${cookie ? 'session: null,' : ''} options: options);
      expect(probe.uri.queryParameters, {'requiredLimit': '7'});
      expect(probe.header('x-region'), isNull);
      expect(probe.header('cookie'), isNull);
      await root.api.getStations(requiredLimit: 7, limit: 10, archived: true, label: '', tags: ['east'], options: options);
      expect(probe.uri.queryParameters['limit'], '10');
      expect(probe.uri.queryParameters['archived'], 'true');
      expect(probe.uri.queryParameters['label'], '');
      expect(probe.uri.queryParametersAll['tags'], ['east']);

      await root.api.submitForm(token: 'caller', options: options);
      expect(Uri.splitQueryString(probe.body), ${enabled ? "{'token': 'caller', 'count': '3', 'enabled': 'false', 'label': 'default label'}" : "{'token': 'caller'}"});
      await root.api.submitForm(token: 'caller', count: null, enabled: null, label: null, options: options);
      expect(Uri.splitQueryString(probe.body), {'token': 'caller'});
      await root.api.submitForm(token: 'caller', count: 0, enabled: false, label: '', options: options);
      expect(Uri.splitQueryString(probe.body), {'token': 'caller', 'count': '0', 'enabled': 'false', 'label': ''});
      for (final nulls in [false, true]) {
        final file = ${http ? "http.MultipartFile.fromString('file', 'payload', filename: 'test.txt')" : "MultipartFile.fromString('payload', filename: 'test.txt')"};
        if (nulls) {
          await root.api.upload(token: 'caller', file: file, count: null, enabled: null, label: null, options: options);
        } else {
          await root.api.upload(token: 'caller', file: file, options: options);
        }
        expect(probe.body, contains('payload'));
        expect(probe.body.contains('name="count"'), ${enabled ? '!nulls' : 'false'});
        expect(probe.body.contains('name="enabled"'), ${enabled ? '!nulls' : 'false'});
        expect(probe.body.contains('name="label"'), ${enabled ? '!nulls' : 'false'});
      }
      await root.api.createStation(options: options);
      expect(probe.body, isEmpty);
      await root.api.createStation(body: const api.CreateStation(), options: options);
      expect(jsonDecode(probe.body), {'name': 'Unnamed'});
    });
  }
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late Map<String, Object?> headers;
  late String body;
  Object? header(String name) => headers.entries.where((e) => e.key.toLowerCase() == name).firstOrNull?.value;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    headers = Map.of(request.headers);
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    return http.StreamedResponse(Stream.value(utf8.encode('{"name":"North"}')), 200, headers: {'content-type': 'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    headers = Map.of(options.headers);
    body = utf8.decode(await stream?.expand((v) => v).toList() ?? []);
    return ResponseBody.fromString('{"name":"North"}', 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}

/// Checks constant object defaults and explicit null overrides.
String objectParameterDefaultsDriver(
  String folder,
  HttpClientBackend backend, {
  required bool enabled,
}) {
  final http = backend == HttpClientBackend.http;
  return '''
${http ? "import 'dart:convert';" : ''}
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('sends constant object defaults=$enabled', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    await root.batch.batches();
    expect(probe.uri.queryParameters, ${enabled ? "{'values': '[[]]'}" : 'isEmpty'});
    await root.api.filter();
    expect(probe.uri.queryParameters, ${enabled ? "{'filter[city]': 'North', 'filter[limit]': '5', 'items': '[]', 'byName': '{}'}" : 'isEmpty'});
    await root.api.filter(filter: null, items: null, byName: null);
    expect(probe.uri.queryParameters, isEmpty);
    await root.api.filter(filter: const api.Filter(city: 'East'), items: [const api.Item(code: '42')], byName: null);
    expect(probe.uri.queryParameters, {'filter[city]': 'East', 'items': '[{"code":"42"}]'});
  });
}
class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    await request.finalize().drain<void>();
    return http.StreamedResponse(Stream.value(utf8.encode('{"name":"North"}')), 200, headers: {'content-type': 'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    await stream?.drain<void>();
    return ResponseBody.fromString('{"name":"North"}', 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}
