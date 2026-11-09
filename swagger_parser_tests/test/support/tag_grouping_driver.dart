import 'package:swagger_parser/swagger_parser.dart';

String tagGroupingDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode, {
  required bool collision,
}) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  final station = collision ? 'station2' : 'station';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('retains each route and its parameter and response types', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    final first = await root.$station.getStation(id: 'north');
    final api.Station value = ${all ? '(first as api.GetStation200).value' : 'first'};
    expect(value.name, 'North');
    expect(probe.uri.path, '/stations/north');
    final second = await root.$station.getStation2(code: 42);
    final api.Lookup lookup = ${all ? '(second as api.GetStation2200).value' : 'second'};
    expect(lookup.code, 42);
    expect(probe.uri.path, '/codes/42');
    await root.stationInfo.infoOne();
    expect(probe.uri.path, '/info-one');
    await root.stationInfo.infoTwo();
    expect(probe.uri.path, '/info-two');
    await root.stations.internal();
    expect(probe.uri.path, '/internal');
    await root.stations.publicStations();
    expect(probe.uri.path, '/public');
    await root.api.health();
    expect(probe.uri.path, '/health');
    await root.api2.taggedApi();
    expect(probe.uri.path, '/tagged-api');
    await root.trips.trips();
    expect(probe.uri.path, '/trips');
    expect(probe.calls, 9);
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  int calls = 0;
  String reply() => uri.path.startsWith('/codes/') ? '{"code":42}' : '{"name":"North"}';
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    calls++;
    uri = request.url;
    expect(request.method, 'GET');
    await request.finalize().drain<void>();
    return http.StreamedResponse(Stream.value(utf8.encode(reply())), 200, headers: {'content-type': 'application/json'});
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? request, Future<void>? cancel) async {
    calls++;
    uri = options.uri;
    expect(options.method, 'GET');
    return ResponseBody.fromString(jsonEncode(jsonDecode(reply())), 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
