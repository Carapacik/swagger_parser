import 'package:swagger_parser/swagger_parser.dart';

/// Checks the effective query values after transport URL encoding.
String delimitedQueryArraysDriver(
  String folder,
  HttpClientBackend backend,
  DelimitedQueryArrayExplodeMode mode,
) {
  final http = backend == HttpClientBackend.http;
  final repeat = mode == DelimitedQueryArrayExplodeMode.repeat;
  return '''
${http ? "import 'dart:convert';\nimport 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('sends ${mode.name} values with reserved characters and empty arrays', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    await root.stations.getStations(regions: ['a', 'b'], zones: ['a', 'b']);
    expect(probe.uri.queryParametersAll, {
      'regions': ${repeat ? "['a', 'b']" : "['a b']"},
      'zones': ${repeat ? "['a', 'b']" : "['a|b']"},
    });
    expect(probe.uri.query, ${repeat ? "contains('zones=a&zones=b')" : "contains('zones=a%7Cb')"});
    final values = ['a&b', 'c+d', 'x/y?'];
    await root.stations.getStations(regions: values, zones: values);
    expect(probe.uri.queryParametersAll, {
      'regions': ${repeat ? 'values' : "[values.join(' ')]"},
      'zones': ${repeat ? 'values' : "[values.join('|')]"},
    });
    await root.stations.getStations();
    expect(probe.uri.queryParametersAll, isEmpty);
    await root.stations.getStations(regions: [], zones: []);
    expect(probe.uri.queryParametersAll, ${repeat ? 'isEmpty' : "{'regions': [''], 'zones': ['']}"});
    await root.stations.getControls(regions: values, zones: values, tags: values);
    expect(probe.uri.queryParametersAll, {
      'regions': [values.join(' ')],
      'zones': [values.join('|')],
      'tags': values,
    });
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    await request.finalize().drain<void>();
    return http.StreamedResponse(Stream.value(utf8.encode('[]')), 200, headers: {'content-type': 'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    await stream?.drain<void>();
    return ResponseBody.fromString('[]', 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}
