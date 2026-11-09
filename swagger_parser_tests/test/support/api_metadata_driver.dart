import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';

String apiMetadataDriver(
  String folder,
  String family,
  HttpClientBackend backend,
  ResponseMode mode, {
  required ApiMetadataMode metadataMode,
}) {
  final enabled = metadataMode == ApiMetadataMode.generateAndAttach;
  final generate = metadataMode != ApiMetadataMode.none;
  final http = backend == HttpClientBackend.http;
  final root = family == 'collisions' ? 'ApiMetadata' : 'TransitApi';
  final entry = family == 'collisions'
      ? 'api_metadata.dart'
      : 'transit_api.dart';
  final companion = family == 'collisions'
      ? 'StationClientMetadata2'
      : 'StationClientMetadata';
  final type = family == 'collisions'
      ? 'OperationMetadata2'
      : 'OperationMetadata';
  final method = family == 'filtered' ? 'getStationsById' : 'getStation';
  final String spec = switch (family) {
    'v2' => '2.0',
    'v3_0' => '3.0.4',
    'v3_1' => '3.1.2',
    _ => '3.2.1',
  };
  String literal(String s) => jsonEncode(s).replaceAll(r'$', r'\$');
  final String title = literal("Transit '\$api'\nAPI");
  final String version = literal(r'2026.11+$build');
  final String url = literal(r"https://example.test/docs?q=$id&name='station'");
  final String tags = literal(r"Quoted '$tag'");
  if (family == 'empty') {
    return '''
import 'package:test/test.dart';
import '$folder/$entry';
void main() {
  test('exports metadata with no generated operations', () {
    const $root();
    expect($root.title, $title);
    expect($root.apiVersion, $version);
    expect($root.specVersion, '$spec');
    ${generate ? 'expect($root.operations, isEmpty); expect(() => $root.operations.clear(), throwsUnsupportedError);' : ''}
  });
}
''';
  }
  final metadataChecks = generate
      ? '''
    const api.$type operation = api.$companion.$method;
    expect(identical(api.$root.operations.first, operation), isTrue);
    expect(api.$root.operations, hasLength(${family == 'filtered' ? 1 : 10}));
    expect(operation.operationId, 'get-station');
    expect(operation.methodName, '$method');
    expect(operation.method, 'GET');
    expect(operation.path, '/stations/{id}');
    expect(operation.tags, ['station', 'Secondary', $tags]);
    expect(operation.externalDocsUrl, $url);
    expect(operation.deprecated, isFalse);
    expect(() => api.$root.operations.clear(), throwsUnsupportedError);
    expect(() => operation.tags.clear(), throwsUnsupportedError);
    ${family == 'filtered' ? '' : '''
    expect(api.$root.operations[1].path, '/trips');
    expect(api.$root.operations[2].methodName, 'getStation2');
    expect(api.$root.operations.singleWhere((m) => m.path == '/health').operationId, isNull);
    expect(api.$root.operations.singleWhere((m) => m.path == '/info-one').deprecated, isTrue);
    expect(api.$root.operations.last.path, '/mounted');
    expect(api.$root.operations.last.externalDocsUrl, 'https://example.test/mounted');
    '''}
'''
      : '';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/$entry' as api;

void main() {
  test('exports metadata and attaches it without replacing caller extras', () async {
    expect(api.$root.title, $title);
    expect(api.$root.apiVersion, $version);
    expect(api.$root.specVersion, '$spec');
    $metadataChecks
    final probe = Probe();
    Map<String, Object?>? observed;
    ${http ? "final root = api.$root(probe, baseUrl: Uri.parse('https://example.test'), prepareRequest: (request, extra) { observed = extra; });" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) { observed = options.extra; handler.next(options); })); final root = api.$root(dio);"}
    final extra = <String, Object?>{'traceId': 'trace-1', 'openapi.operation': 'caller'};
    for (final withOptions in [false, true]) {
      await root.station.$method(id: 'north', extra: extra, ${http ? "options: withOptions ? const api.HttpRequestOptions(headers: {'X-Test': 'yes'}) : null" : "options: withOptions ? Options(extra: {'option': 42, 'openapi.operation': 'options'}, headers: {'X-Test': 'yes'}) : null"});
      expect(probe.uri.path, '/stations/north');
      expect(observed!['traceId'], 'trace-1');
      expect(observed!['openapi.operation'], ${enabled ? 'same(operation)' : "'caller'"});
      expect(extra, {'traceId': 'trace-1', 'openapi.operation': 'caller'});
      ${http ? '' : "if (withOptions) expect(observed!['option'], 42);"}
    }
    await root.station.$method(id: 'south');
    expect(observed!.containsKey('openapi.operation'), $enabled);
    ${enabled ? "expect(observed!['openapi.operation'], same(operation));" : ''}
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    expect(request.method, 'GET');
    expect(request.headers.keys.any((key) => key.startsWith('openapi')), isFalse);
    await request.finalize().drain<void>();
    return http.StreamedResponse(Stream.value(utf8.encode('{"name":"North"}')), 200, headers: {'content-type': 'application/json'});
  }
''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? request, Future<void>? cancel) async {
    uri = options.uri;
    expect(options.method, 'GET');
    expect(options.headers.keys.any((key) => key.startsWith('openapi')), isFalse);
    return ResponseBody.fromString(jsonEncode({'name': 'North'}), 200, headers: {Headers.contentTypeHeader: ['application/json']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
