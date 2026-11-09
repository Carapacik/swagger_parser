import 'package:swagger_parser/swagger_parser.dart';

String fileSuffixDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode,
) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  final bang = backend == HttpClientBackend.dio ? '!' : '';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/transit_api.dart' as api;

void main() {
  test('imports shared models and support files through one facade', () async {
    final probe = Probe();
    ${http ? "final root = api.TransitApi(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.TransitApi(dio);"}
    final result = await root.stations.getStation();
    final api.Station station = ${all ? '(result as api.GetStation200).value' : 'result.data$bang'};
    expect(station.name, 'North');
    final api.StationAddress address = station.address;
    expect(address.city, 'Town');
    expect(station.status, api.StationStatus.active);
    expect(station.toJson()['vehicle'], {'kind': 'rail', 'platform': 2});
    ${all ? '' : "expect(${backend == HttpClientBackend.dio ? 'result' : 'result.response'}.statusCode, 200);"}
    final options = ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"};
    final created = await root.stations.postStation(body: station, options: options);
    expect(${all ? '(created as api.PostStation200).value' : 'created.data$bang'}.name, 'North');
    expect((jsonDecode(probe.body) as Map)['name'], 'North');
    expect(probe.header('x-call'), 'yes');
    final trip = await root.trips.getTrip();
    final api.Station shared = ${all ? '(trip as api.GetTrip200).value' : 'trip.data$bang'};
    expect(shared.address.city, 'Town');
    expect(probe.uri.path, '/trips');
    expect(api.Vehicle.fromJson({'kind': 'bus', 'route': 'A'}).toJson(), {'kind': 'bus', 'route': 'A'});
    ${all ? "probe.code = 404;\nfinal failed = await root.stations.getStation();\nexpect((failed as api.GetStation404).value.message, 'Missing');" : ''}
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late String body;
  late Map<String, Object?> headers;
  int code = 200;
  Object? header(String name) => headers.entries.where((e) => e.key.toLowerCase() == name).firstOrNull?.value;
  String reply() => code == 404 ? '{"message":"Missing"}' : '{"name":"North","address":{"city":"Town"},"status":"active","vehicle":{"kind":"rail","platform":2}}';
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    headers = Map.of(request.headers);
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    return http.StreamedResponse(Stream.value(utf8.encode(reply())), code, headers: {'content-type': 'application/json'});
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? request, Future<void>? cancel) async {
    uri = options.uri;
    headers = options.headers;
    body = switch (options.data) { String s => s, null => '', final data => jsonEncode(data) };
    return ResponseBody.fromString(reply(), code, headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
