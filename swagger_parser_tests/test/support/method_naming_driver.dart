import 'package:swagger_parser/swagger_parser.dart';

String methodNamingDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode, {
  required bool enabled,
  required bool rename,
}) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  String name(String path, String id) {
    final selected = enabled ? path : id;
    return rename ? selected.replaceFirst(RegExp('^get'), 'fetch') : selected;
  }

  String stem(String method) =>
      '${method[0].toUpperCase()}${method.substring(1)}';
  final String station = name('getStationsById', 'lookupStation');
  final String nested = name('getAByBCByDAndE', 'lookupNested');
  final String health = name('getHealth', 'getHealth');
  final String first = name('getStationList', 'lookupList');
  final String second = name('getStationList2', 'lookupList2');
  final String mounted = name('getMountedById', 'externalLookup');
  final String inline = name('postInline', 'createInline');
  final request = enabled ? 'PostInlineRequest' : 'CreateInlineRequest';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('calls selected names without changing wire paths', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    final result = await root.api.$station(id: 's1');
    final api.Station station = ${all ? '(result as api.${stem(station)}200).value' : 'result'};
    expect(station.name, 'North');
    expect(probe.uri.path, '/stations/s1');
    final nested = await root.api.$nested(b: 'b1', d: 'd1', e: 'e1');
    expect(${all ? '(nested as api.${stem(nested)}200).value' : 'nested'}, 'ok');
    expect(probe.uri.path, '/a/b1/c/d1/e1');
    await root.api.$health();
    expect(probe.uri.path, '/health');
    await root.api.$first();
    expect(probe.uri.path, '/station-list');
    await root.api.$second();
    expect(probe.uri.path, '/station_list');
    await root.api.$mounted(id: 'm1');
    expect(probe.uri.path, '/mounted/m1');
    final created = await root.api.$inline(body: api.$request.fromJson({'name': 'South'}));
    expect(${all ? '(created as api.${stem(inline)}200).value' : 'created'}.name, 'North');
    expect(probe.uri.path, '/inline');
    expect(probe.method, 'POST');
    expect(jsonDecode(probe.body), {'name': 'South'});
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late String method;
  late String body;
  String reply() => uri.path.startsWith('/stations/') || uri.path == '/inline' ? '{"name":"North"}' : '"ok"';
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    method = request.method;
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    return http.StreamedResponse(Stream.value(utf8.encode(reply())), 200, headers: {'content-type': 'application/json'});
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? request, Future<void>? cancel) async {
    uri = options.uri;
    method = options.method;
    body = switch (options.data) { String s => s, null => '', final data => jsonEncode(data) };
    return ResponseBody.fromString(reply(), 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
