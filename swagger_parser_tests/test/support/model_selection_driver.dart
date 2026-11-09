import 'package:swagger_parser/swagger_parser.dart';

String selectionDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode,
  String family,
) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('retains deep inline types, aliases, shared children, and cycles', () {
    final leaf = <String,Object?>{
      'nested': {'second': [{'third': {'state': 'paused', 'shared': {'value':'inner'}}}]},
      'left': {'value':'left'}, 'right': {'value':'right'},
    };
    final source = <String,Object?>{
      ...leaf, 'left': {'value':'next','next':leaf},
    };
    final graph = api.DeepGraph.fromJson(source);
    expect(graph.toJson(), source);
    expect(graph.nested.second.single.third.state.toJson(), 'paused');
    expect(graph.left.next!.value.right.value, 'right');
    ${family == 'v2' ? '' : "expect(api.ParameterOnly.one.toJson(), 'one'); expect(api.PathOnly.one.toJson(),'one'); expect(api.QueryOnly.one.toJson(),'one'); expect(api.CookieOnly.one.toJson(),'one'); expect(api.FlatOnly.fromJson({'value':'one'}).toJson(),{'value':'one'});"}
  });
  test('sends retained fields and decodes retained models', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    for (final override in [false, true]) {
      final options = override ? ${http ? "const api.HttpRequestOptions(headers: {'X-Trace-Id': 'external'})" : "Options(headers: {'X-Trace-Id': 'external'})"} : null;
      final result = await root.stations.getStation(id: 's1', debug: 'visible', options: options);
      final api.Station\$Response station = ${all ? '(result as api.GetStation200).value' : 'result'};
      expect(station.name, 'North');
      expect(station.id, 's1');
      expect(station.toJson()['details'], {'north': {'count': 2}});
      expect(probe.uri.queryParameters, {'limit': '25'});
      expect(probe.header('debug'), 'visible');
      expect(probe.header('x-trace-id'), override ? 'external' : null);
      expect(probe.header('cookie'), isNull);
    }
    ${family == 'v2' ? "await root.stations.onlyParameters(key:'one',query2:[api.OnlyParametersQueryItem.one,api.OnlyParametersQueryItem.two],header:[api.OnlyParametersHeaderItem.two,api.OnlyParametersHeaderItem.one]); expect(probe.uri.queryParametersAll['query'],['one','two']); expect(probe.header('header'),'two,one');" : "await root.stations.onlyParameters(key:[api.PathOnly.one,api.PathOnly.two],query2:[api.QueryOnly.one,api.QueryOnly.two],object:api.FlatOnly(value:api.QueryOnly.two),cookie:[api.CookieOnly.two,api.CookieOnly.one]); expect(probe.uri.path,'/only/one,two'); expect(probe.uri.queryParametersAll['query'],['one','two']); expect(probe.uri.queryParameters['object[value]'],'two'); expect(probe.header('cookie'),'cookie=two; cookie=one');"}
    final request = api.Station\$Request.fromJson({'name': 'South'});
    final created = await root.stations.postStation(body: request);
    expect(${all ? '(created as api.PostStation201).value' : 'created'}.name, 'North');
    expect((jsonDecode(probe.body) as Map)['name'], 'South');
    expect((jsonDecode(probe.body) as Map).containsKey('id'), isFalse);
    await root.api.getOther(debug: 'on');
    expect(probe.uri.queryParameters['debug'], 'on');
    final audit = api.AuditRecord.fromJson({'detail': {'value': 9}});
    expect(audit.toJson()['detail'], {'value': 9});
    ${all ? "probe.status = 404;\nfinal failed = await root.stations.getStation(id: 'missing');\nexpect((failed as api.GetStation404).value.message, 'Missing');" : ''}
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late Map<String, Object?> headers;
  late String body;
  int status = 200;
  Object? header(String name) => headers.entries.where((e) => e.key.toLowerCase() == name).firstOrNull?.value;
  int code(String method) => status == 404 ? 404 : (uri.path == '/other' || uri.path.startsWith('/only/')) ? 204 : method == 'POST' ? 201 : 200;
  String reply() => status == 404 ? '{"message":"Missing"}' : uri.path == '/other' ? '' : '{"name":"North","id":"s1","details":{"north":{"count":2}},"tree":{"children":[]}}';
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    headers = Map.of(request.headers);
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    return http.StreamedResponse(Stream.value(utf8.encode(reply())), code(request.method), headers: {'content-type': 'application/json'});
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? request, Future<void>? cancel) async {
    uri = options.uri;
    headers = options.headers;
    body = switch (options.data) { String s => s, null => '', final data => jsonEncode(data) };
    return ResponseBody.fromString(reply(), code(options.method), headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}

String selectionModelsDriver(String folder, String kind) {
  final String check = switch (kind) {
    'unions' =>
      """
      expect(api.State.fromJson({'kind': 'online', 'uptime': 2}).toJson(), {'kind': 'online', 'uptime': 2});
      expect(api.NamedStop.fromJson({'platform': 3}).toJson(), {'platform': 3});
      expect(api.Contact.fromJson({'id': 'x', 'email': 'a@b'}).toJson(), {'id': 'x', 'email': 'a@b'});
    """,
    'tuples' =>
      """
      expect(api.Pair.fromJson(['sensor', 2]).toJson(), ['sensor', 2]);
      expect(api.Envelope.fromJson({'data': [['sensor'], {'unit': 'm'}]}).toJson(), {'data': [['sensor'], {'unit': 'm'}]});
    """,
    'dynamic' =>
      """
      expect(api.Names.fromJson(['ab']).toJson(), ['ab']);
      expect(() => api.Names.fromJson([1]), throwsA(anything));
      expect(api.NumberTree.fromJson(['ab']).toJson(), ['ab']);
    """,
    'swagger' =>
      """
      expect(api.Stop.fromJson({'kind': 'Rail', 'platform': 4}).toJson(), {'kind': 'Rail', 'platform': 4});
      expect(api.Stop.fromJson({'kind': 'Future', 'data': 1}).toJson(), {'kind': 'Future', 'data': 1});
    """,
    'mapped' =>
      """
      final api.CreateStation request = api.CreateStation(name: 'South');
      final api.Station response = api.Station(id: 's1', name: 'North');
      expect(request.name, 'South');
      expect(response.name, 'North');
    """,
    _ => throw StateError(kind),
  };
  return """
import 'package:test/test.dart';
import '$folder/api.dart' as api;
void main() {
  test('keeps $kind dependencies', () {
    $check
  });
}
""";
}
