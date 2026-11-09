import 'package:swagger_parser/swagger_parser.dart';

/// Checks independent DTOs, exact wire keys, and shared client return types.
String modelIdentityDriver(
  String folder,
  HttpClientBackend backend, {
  required bool renamed,
}) {
  final http = backend == HttpClientBackend.http;
  final station = renamed ? 'Stop' : 'Station';
  final caseName = renamed ? 'CaseDto' : 'CaseModel';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

const loginJson = {'token': 't', 'data': {'id': 's'}};
const sharedJson = {'station': {'id': 's'}, 'again': {'id': 's'}, 'depot': {'id': 's'}};
const caseJson = {'Station': {'id': 'UP'}, 'station': {'id': 'down'}, 'Code': 'UP', 'code': 'down', 'nested': {'Station': 'UP', 'station': 'down', 'x-name': 'quoted'}};
const enumJson = {'first': 'left', 'second': 'right', 'again': 'left'};
const mergedJson = {'count': 5, 'snake-key': 'dash', 'snake_key': 'underscore'};
const nearbyJson = {'locations': [{'label': 'North', 'coordinates': {'latitude': 1.5, 'longitude': 2.0}}]};

void main() {
  test('keeps equal inline and named object types distinct', () {
    final first = api.LoginResponse2002.fromJson(loginJson);
    final second = api.LoginAltResponse200.fromJson(loginJson);
    expect(first.runtimeType, isNot(second.runtimeType));
    expect(first.data.runtimeType, isNot(second.data.runtimeType));
    expect(first.toJson(), loginJson);
    expect(second.toJson(), loginJson);
    expect(first.data.id, 's');
    expect(second.data.id, 's');
    expect(() => api.LoginResponse2002.fromJson({'data': {'id': 's'}}), throwsA(anything));
    expect(() => api.LoginAltResponse200.fromJson({'token': 't', 'data': <String, Object?>{}}), throwsA(anything));
    expect(api.LoginResponse200.fromJson({'reserved': 7}).toJson(), {'reserved': 7});
    final shared = api.Shared.fromJson(sharedJson);
    final api.$station a = shared.station;
    final api.$station b = shared.again;
    final api.Depot depot = shared.depot;
    expect(a.toJson(), depot.toJson());
    expect(a.runtimeType, b.runtimeType);
    expect(a.runtimeType, isNot(depot.runtimeType));
    expect(shared.toJson(), sharedJson);
  });
  test('keeps colliding enums distinct and repeated references shared', () {
    final dto = api.EnumUse.fromJson(enumJson);
    expect(dto.toJson(), enumJson);
    expect(dto.first.runtimeType, isNot(dto.second.runtimeType));
    expect(identical(dto.first, dto.again), isTrue);
    expect(() => api.EnumUse.fromJson({...enumJson, 'first': 'right'}), throwsA(anything));
    expect(() => api.EnumUse.fromJson({...enumJson, 'second': 'left'}), throwsA(anything));
    expect(api.EnumUse.fromJson({'first': 'same', 'second': 'same', 'again': 'same'}).toJson(), {'first': 'same', 'second': 'same', 'again': 'same'});
  });
  test('preserves exact property keys and constraints after renaming', () {
    final dto = api.$caseName.fromJson(caseJson);
    expect(dto.toJson(), caseJson);
    expect(dto.station.id, 'UP');
    expect(dto.station2.id, 'down');
    expect(dto.nested.xName, 'quoted');
    for (final key in caseJson.keys) {
      final missing = Map<String, Object?>.of(caseJson)..remove(key);
      expect(() => api.$caseName.fromJson(missing), throwsA(anything));
    }
    final merged = api.Merged.fromJson(mergedJson);
    final int count = merged.count;
    expect(count, 5);
    expect(merged.toJson(), mergedJson);
    expect(merged.validate(), isEmpty);
    expect(api.Merged.fromJson({...mergedJson, 'count': -1}).validate().map((e) => (e.path, e.keyword)), contains(('/count', 'minimum')));
    expect(api.Merged.fromJson({...mergedJson, 'count': 11}).validate().map((e) => (e.path, e.keyword)), contains(('/count', 'maximum')));
    expect(api.NearbyResponse200.fromJson(nearbyJson).locations.single.coordinates.latitude, 1.5);
    expect(api.NearbyResponse200.fromJson(nearbyJson).toJson(), nearbyJson);
  });
  test('uses one public import for shared responses and inline request types', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://identity.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://identity.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    final api.Shared first = await root.trips.firstShared();
    final api.Shared second = await root.stations.secondShared();
    expect(first.toJson(), sharedJson);
    expect(second.runtimeType, first.runtimeType);
    final api.LoginResponse2002 login = await root.auth.login(body: const api.LoginRequest(userName: 'u', password: 'p'));
    expect(login.toJson(), loginJson);
    expect(jsonDecode(probe.body), {'user_name': 'u', 'password': 'p'});
    final api.LoginAltResponse200 alternative = await root.auth.loginAlt(body: const api.LoginAltRequest(token: 't'));
    expect(alternative.toJson(), loginJson);
    expect(jsonDecode(probe.body), {'token': 't'});
    final api.PostAByBCByDAndEResponse200 posted = await root.auth.postAByBCByDAndE(b: 'B', d: 'D', e: 'E', body: const api.PostAByBCByDAndERequest(active: false));
    expect(posted.data.code, 'code');
    expect(probe.uri.path, '/a/B/c/D/E');
    expect(jsonDecode(probe.body), {'active': false});
    await root.auth.putAByBCByDAndE(b: 'B', d: 'D', e: 'E', body: const api.PutAByBCByDAndERequest(count: 0));
    expect(probe.method, 'PUT');
    expect(jsonDecode(probe.body), {'count': 0});
    final api.NearbyResponse200 nearby = await root.geo.nearby();
    final api.Coordinates coordinates = nearby.locations.single.coordinates;
    expect(coordinates.longitude, 2.0);
    expect(nearby.toJson(), nearbyJson);
    expect((await root.trips.getCases()).toJson(), caseJson);
    expect((await root.trips.getEnums()).toJson(), enumJson);
    expect((await root.trips.getMerged()).toJson(), mergedJson);
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late String method;
  late String body;
  Object? response() => switch (uri.path) {
    '/trips/shared' || '/stations/shared' => sharedJson,
    '/login' || '/other-login' => loginJson,
    '/cases' => caseJson,
    '/enums' => enumJson,
    '/merged' => mergedJson,
    '/nearby' => nearbyJson,
    _ => {'data': {'code': 'code'}},
  };
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    method = request.method;
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    return http.StreamedResponse(Stream.value(method == 'PUT' ? <int>[] : utf8.encode(jsonEncode(response()))), method == 'PUT' ? 204 : 200, headers: {'content-type': 'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    method = options.method;
    body = utf8.decode(await stream?.expand((v) => v).toList() ?? []);
    return ResponseBody.fromString(method == 'PUT' ? '' : jsonEncode(response()), method == 'PUT' ? 204 : 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}
