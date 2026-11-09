import 'package:swagger_parser/swagger_parser.dart';

/// Checks protected symbols and unchanged wire data.
String reservedNamesDriver(
  String folder,
  DtoSerializer serializer,
  HttpClientBackend backend, {
  required bool renamed,
  required String value,
}) {
  final http = backend == HttpClientBackend.http;
  final bool copy =
      serializer == DtoSerializer.freezed ||
      serializer == DtoSerializer.dartMappable;
  final method = renamed ? 'toJson2' : 'fromJson3';
  return '''
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
${http ? "import 'package:http/http.dart' as http;" : "import 'package:dio/dio.dart';"}
import '$folder/api.dart' as api;

void main() {
  final json = jsonDecode(r\'''$value\''') as Map<String, dynamic>;
  test('decodes protected fields and enum values', () {
    final station = api.Station.fromJson(json);
    expect(station.class3, 'class');
    expect(station.fromJson3, 'fromJson');
    expect(station.toJson2, 'toJson');
    expect(station.hashCode2, 'hashCode');
    expect(station.${copy ? 'copyWith3' : 'copyWith'}, 'copyWith');
    expect(station.${serializer == DtoSerializer.dartMappable ? 'toMap3' : 'toMap'}, 'toMap');
    expect(station.userId, 'user-id');
    expect(station.userId2, 'user_id');
    expect(station.response, isA<api.${renamed ? 'Dio3' : 'Response3'}>());
    expect(station.text, isA<api.String3>());
    expect(station.status, api.Status.values3);
    expect(station.toJson(), json);
    ${copy ? "expect(station.copyWith(class3: 'changed').class3, 'changed');" : ''}
    expect(api.Response2.fromJson({'value': 'two'}).value, 'two');
    expect(api.String2.fromJson({'value': 'two'}).value, 'two');
    expect(api.Dio2.fromJson({'value': 'dio'}).value, 'dio');
    expect(api.${renamed
      ? 'class2'
      : serializer == DtoSerializer.dartMappable
      ? 'Class2'
      : 'Class'}.fromJson({'value': 'keyword'}).value, 'keyword');
    expect(api.Api2.fromJson({'value': 'facade'}).value, 'facade');
    expect(api.StationClient.fromJson({'value': 'client'}).value, 'client');
    expect(api.${serializer == DtoSerializer.freezed || serializer == DtoSerializer.jsonSerializable ? 'JsonKey2' : 'JsonKey'}.fromJson({'value': 'annotation'}).value, 'annotation');
  });

  test('keeps wire names separate from request controls', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final base = 'http://127.0.0.1:\${server.port}';
    final transport = ${http ? 'http.Client()' : 'Dio(BaseOptions(baseUrl: base))'};
    addTearDown(() => transport.${http ? 'close()' : 'close(force: true)'});
    late Map<String, dynamic> body;
    late Uri uri;
    late String? header;
    Map<String, dynamic>? extra;
    server.listen((request) async {
      uri = request.uri;
      header = request.headers.value('x-call');
      final text = await utf8.decoder.bind(request).join();
      if (text.isNotEmpty) body = jsonDecode(text) as Map<String, dynamic>;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(json));
      await request.response.close();
    });
    ${http ? '' : 'transport.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) { extra = request.extra; handler.next(request); }));'}
    final root = api.Api(transport${http ? ', baseUrl: Uri.parse(base), prepareRequest: (request, metadata) { extra = metadata; }' : ''});
    final station = api.Station.fromJson(json);
    final result = await root.station2.$method(
      class3: 'path', class2: 'query', body: station,
      options2: 'two', options3: 'option', extra2: 'two', extra3: 'wire', cancelToken2: 'cancel',
      extra: {'test': true},
      options: ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"},
    );
    expect(uri.path, '/reserved/path');
    expect(uri.queryParameters, {'class2': 'query', 'options2': 'two', 'options': 'option', 'extra2': 'two', 'extra': 'wire', 'cancelToken': 'cancel'});
    expect(header, 'yes');
    expect(extra!['test'], true);
    expect(body, json);
    expect(result.toJson(), json);
    expect((await root.station2.fromJson2()).status, api.Status.values3);
    expect((await root.station2.fetchJson()).status, api.Status.values3);
    expect((await root.station2.fetchJson2()).status, api.Status.values3);
  });
}
''';
}
