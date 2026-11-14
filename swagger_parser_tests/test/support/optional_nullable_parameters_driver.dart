import 'package:swagger_parser/swagger_parser.dart';

/// Checks that omitted and null optional parameters stay absent, and that
/// supplied scalar and list values reach the transport as specified.
String optionalNullableParametersDriver(
  String folder,
  HttpClientBackend backend,
) {
  final http = backend == HttpClientBackend.http;
  return '''
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  for (final withOptions in [false, true]) {
    test('sends optional nullable parameters with options=\$withOptions', () async {
      final probe = Probe();
      ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
      final options = withOptions ? ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"} : null;

      await root.api.search(page: 1, options: options);
      expect(probe.uri.path, '/search');
      expect(probe.uri.queryParametersAll, {'page': ['1']});
      expect(probe.header('x-trace'), isNull);
      expect(probe.header('x-ids'), isNull);
      expect(probe.header('x-call'), withOptions ? 'yes' : null);

      await root.api.search(q: null, limit: null, since: null, tags: null, kinds: null, xTrace: null, xIds: null, page: 1, options: options);
      expect(probe.uri.queryParametersAll, {'page': ['1']});
      expect(probe.header('x-trace'), isNull);
      expect(probe.header('x-ids'), isNull);

      await root.api.search(q: 'a b', limit: 0, since: '2026-01-02T03:04:05Z', tags: ['x', 'y'], kinds: [api.SearchKindsItem.b, api.SearchKindsItem.a], xTrace: 'trace', xIds: [1, 2], page: 3, options: options);
      expect(probe.uri.queryParametersAll, {
        'q': ['a b'],
        'limit': ['0'],
        'since': ['2026-01-02T03:04:05Z'],
        'tags': ['x', 'y'],
        'kinds': ['b', 'a'],
        'page': ['3'],
      });
      expect(probe.header('x-trace'), 'trace');
      expect(probe.header('x-ids'), '1,2');

      // An empty string is a value. It is not an omission.
      await root.api.search(q: '', page: 1, options: options);
      expect(probe.uri.queryParametersAll['q'], ['']);
      await root.api.item(id: 7, options: options);
      expect(probe.uri.path, '/items/7');
      expect(probe.uri.queryParametersAll, isEmpty);
      await root.api.item(id: 7, q: 'z', options: options);
      expect(probe.uri.queryParametersAll, {'q': ['z']});
    });
  }
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late Map<String, Object?> headers;
  Object? header(String name) => headers.entries.where((e) => e.key.toLowerCase() == name).firstOrNull?.value;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    headers = Map.of(request.headers);
    await request.finalize().drain<void>();
    return http.StreamedResponse(const Stream.empty(), 204);
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    headers = Map.of(options.headers);
    await stream?.drain<void>();
    return ResponseBody.fromString('', 204);
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}
