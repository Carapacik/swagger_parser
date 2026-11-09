import 'package:swagger_parser/swagger_parser.dart';

String enumContractDriver(
  String folder,
  String version,
  HttpClientBackend backend,
  String value,
) {
  final http = backend == HttpClientBackend.http;
  final old = version == 'v2';
  final bool modern = version == 'v3_1' || version == 'v3_2';
  return r"""
import 'dart:convert';
TRANSPORT_IMPORT
import 'package:test/test.dart';
import 'IMPORT/api.dart' as api;

Object? wire(Object? value) => jsonDecode(jsonEncode(value));

void main() {
  final input = jsonDecode(r'''VALUE_JSON''') as Map<String, dynamic>;
  MODERN_INPUT
  test('preserves named, inline, external, and collection enum values', () {
    final dto = api.Envelope.fromJson(input);
    expect(dto.code.toJson(), 1);
    expect(dto.integral.toJson(), 1000);
    expect(api.IntegralCode.fromJson(1000).toJson(), 1000);
    expect(() => api.IntegralCode.fromJson(1000.5), throwsA(anything));
    expect(dto.inlineCode.toJson(), 1);
    expect(dto.external2.toJson(), 7);
    expect(dto.alias.toJson(), 2);
    expect(dto.inlineCodes.map((v) => v.toJson()), [2, 1]);
    expect(dto.byName['east']!.toJson(), 'north-bound');
    expect(dto.validate(), isEmpty);
    expect(wire(dto), input);
    for (final bad in [99, '1', false, <Object?>[], <String,Object?>{}]) {
      expect(() => api.Code.fromJson(bad), throwsA(anything));
    }
    expect(() => api.ExternalCode.fromJson(99), throwsA(anything));
    expect(() => api.CodeAlias.fromJson(99), throwsA(anything));
    expect(() => api.Envelope.fromJson({...input, 'inlineCodes': [99]}), throwsA(anything));
    expect(() => api.Envelope.fromJson({...input, 'inlineCode': 99}), throwsA(anything));
    expect(() => api.Envelope.fromJson({...input, 'inlineMode': 'wrong'}), throwsA(anything));
  });
  test('distinguishes empty text, null text, and nullable values', () {
    const texts = ['', 'empty', 'null', '0', 'line\n"\\\$'];
    expect(api.Text.values.map((v) => v.name).toSet(), hasLength(texts.length));
    for (final text in texts) {
      final dto = api.Envelope.fromJson({...input, 'text': text});
      expect(dto.text.toJson(), text);
      expect((wire(dto) as Map)['text'], text);
    }
    for (final value in [null, '', 'empty', 'null']) {
      final dto = api.Envelope.fromJson({...input, 'nullableText': value});
      final json = wire(dto) as Map;
      expect(json.containsKey('nullableText'), true);
      expect(json['nullableText'], value);
    }
    for (final value in [null, 0, 2]) {
      expect((wire(api.Envelope.fromJson({...input, 'nullableCode': value})) as Map)['nullableCode'], value);
    }
    expect(() => api.Text.fromJson(null), throwsA(anything));
    expect(() => api.Text.fromJson('unknown'), throwsA(anything));
    expect(() => api.NullableCode.fromJson('0'), throwsA(anything));
  });
  test('retains inferred enums and allOf restrictions', () {
    expect(api.InferredCode.fromJson(1).toJson(), 1);
    expect(() => api.InferredCode.fromJson(9), throwsA(anything));
    for (final value in [1, 2]) {
      final model = api.NarrowCode.fromJson(value);
      expect(model.toJson(), value);
      expect(model.validate(), isEmpty);
    }
    expect(api.NarrowCode.fromJson(0).validate().map((e) => (e.path,e.keyword)), contains(('', 'enum')));
    expect(api.NarrowText.fromJson('a\n"\\\$').validate(), isEmpty);
    expect(api.NarrowText.fromJson('b').validate().map((e) => e.keyword), contains('enum'));
    for (final value in [0, 1, 2, 9]) {
      expect(api.ImpossibleCode.fromJson(value).validate().map((e) => e.keyword), contains('enum'));
    }
    expect(api.Envelope.fromJson({...input, 'narrowCode': 0}).validate().map((e) => (e.path,e.keyword)), contains(('/narrowCode','enum')));
  });
  MODERN_CHECK
  test('sends typed JSON bodies and decodes enum responses', () async {
    final probe = Probe();
    CREATE_CLIENT
    final dto = api.Envelope.fromJson(input);
    expect(wire(await client.echoEnvelope(body: dto)), input);
    expect(jsonDecode(probe.body), input);
    expect((await client.echoCode(body: api.Code.fromJson(2))).toJson(), 2);
    expect(jsonDecode(probe.body), isA<int>());
    expect(wire(await client.echoCodes(body: [api.Code.fromJson(0), api.Code.fromJson(2)])), [0,2]);
    expect(jsonDecode(probe.body), [0,2]);
    expect((await client.echoExternal(body: api.ExternalCode.fromJson(7))).toJson(), 7);
    expect(jsonDecode(probe.body), 7);
    probe.badResponse = true;
    await expectLater(client.echoCode(body: api.Code.fromJson(2)), throwsA(anything));
  });
  test('uses enum wire values in parameters, forms, and multipart', () async {
    final probe = Probe();
    CREATE_CLIENT
    expect((await client.parameters(code: api.PARAM_CODE.fromJson(2), mode: api.PARAM_MODE.fromJson('north-bound'), xFlag: api.PARAM_FLAG.fromJson(true))).toJson(), 2);
    expect(probe.uri.path, '/parameters/2');
    expect(probe.uri.queryParameters['mode'], 'north-bound');
    expect(probe.headers['x-flag'], 'true');
    await client.sendForm(code: api.FORM_PREFIXCode.fromJson(2), mode: api.FORM_PREFIXMode.fromJson('north-bound'), flag: api.FORM_PREFIXFlag.fromJson(true));
    expect(probe.headers['content-type'], startsWith('application/x-www-form-urlencoded'));
    expect(Uri.splitQueryString(probe.body), {'code':'2','mode':'north-bound','flag':'true'});
    await client.sendMultipart(code: api.MULTIPART_PREFIXCode.fromJson(2), mode: api.MULTIPART_PREFIXMode.fromJson('north-bound'), flag: api.MULTIPART_PREFIXFlag.fromJson(true)JSON_PART_ARGUMENT);
    expect(probe.headers['content-type'], startsWith('multipart/form-data;'));
    final parts = <String,String>{};
    final pattern = RegExp(r'name="([^"]+)"[^\r\n]*\r\n(?:[^\r\n]+\r\n)*\r\n([^\r\n]*)\r\n');
    for (final match in pattern.allMatches(probe.body)) { parts[match[1]!] = match[2]!; }
    expect(parts, {'code':'2','mode':'north-bound','flag':'true'JSON_PART_EXPECTATION});
  });
}

class Probe TRANSPORT_BASE {
  late Uri uri;
  Map<String,String> headers = {};
  String body = '';
  bool badResponse = false;
  String reply(Uri uri, Map<String,String> headers, String body) {
    this.uri = uri;
    this.headers = {for (final entry in headers.entries) entry.key.toLowerCase():entry.value};
    this.body = body;
    if (badResponse) return jsonEncode('unknown');
    return switch (uri.path) { '/envelope' || '/code' || '/codes' || '/external' => body, _ => '2' };
  }
  TRANSPORT_SEND
}
"""
      .replaceAll('IMPORT/api.dart', '$folder/api.dart')
      .replaceAll('VALUE_JSON', value)
      .replaceAll('MODERN_INPUT', modern ? "input['mixed'] = null;" : '')
      .replaceAll(
        'MODERN_CHECK',
        modern
            ? r'''
  test('preserves distinct scalar types in nullable enum lists', () {
    for (final value in [null, '0', 0, 'null', false, true, 1.0e+3, 1.25, '', 'line\n"\\\$']) {
      final dto = api.Envelope.fromJson({...input, 'mixed': value});
      final json = wire(dto) as Map;
      expect(json.containsKey('mixed'), true);
      expect(json['mixed'], value);
      if (value is String) expect(json['mixed'], isA<String>());
      if (value is num) expect(json['mixed'], isA<num>());
      if (value is bool) expect(json['mixed'], isA<bool>());
    }
    expect(api.Mixed.fromJson('0'), isNot(api.Mixed.fromJson(0)));
    expect(() => api.Mixed.fromJson('1000'), throwsA(anything));
    expect(() => api.Mixed.fromJson(99), throwsA(anything));
  });
'''
            : '',
      )
      .replaceAll(
        'JSON_PART_ARGUMENT',
        old ? '' : ", jsonMode: api.SendMultipartRequestJsonMode.fromJson('north-bound')",
      )
      .replaceAll(
        'JSON_PART_EXPECTATION',
        old ? '' : ''' , 'jsonMode': '"north-bound"' ''',
      )
      .replaceAll('PARAM_CODE', old ? 'ParametersCode' : 'Code')
      .replaceAll('PARAM_MODE', old ? 'ParametersMode' : 'Mode')
      .replaceAll('PARAM_FLAG', old ? 'ParametersXFlag' : 'Flag')
      .replaceAll('FORM_PREFIX', old ? 'SendForm' : 'SendFormRequest')
      .replaceAll(
        'MULTIPART_PREFIX',
        old ? 'SendMultipart' : 'SendMultipartRequest',
      )
      .replaceAll(
        'TRANSPORT_IMPORT',
        http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart' as dio;",
      )
      .replaceAll(
        'CREATE_CLIENT',
        http
            ? "addTearDown(probe.close); final client = api.Api(probe, baseUrl: Uri.parse('https://example.test')).api;"
            : "final transport = dio.Dio(dio.BaseOptions(baseUrl:'https://example.test'))..httpClientAdapter = probe; addTearDown(() => transport.close(force: true)); final client = api.Api(transport).api;",
      )
      .replaceAll(
        'TRANSPORT_BASE',
        http ? 'extends http.BaseClient' : 'implements dio.HttpClientAdapter',
      )
      .replaceAll(
        'TRANSPORT_SEND',
        http
            ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = await utf8.decoder.bind(request.finalize()).join();
    final data = reply(request.url, request.headers, body);
    return http.StreamedResponse(Stream.value(utf8.encode(data)), 200, headers: {'content-type':'application/json'}, request: request);
  }
'''
            : '''
  @override
  Future<dio.ResponseBody> fetch(dio.RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final body = requestStream == null ? '' : await utf8.decoder.bind(requestStream).join();
    final data = reply(options.uri, options.headers.map((k,v) => MapEntry(k,v.toString())), body);
    return dio.ResponseBody.fromString(data, 200, headers: {'content-type':['application/json']});
  }
  @override
  void close({bool force = false}) {}
''',
      );
}
