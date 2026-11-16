import 'package:swagger_parser/swagger_parser.dart';

/// Checks nullable fields, defaults, and exclusive union decoding.
String nullableUnionDriver(String folder) =>
    '''
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  const required = <String, dynamic>{'anyCard': null, 'oneCard': null, 'text': null};
  test('uses nullable fields and constant defaults', () {
    final dto = api.Holder.fromJson(required);
    expect(dto.anyCard, isNull);
    expect(dto.oneCard, isNull);
    expect(dto.text, isNull);
    expect(dto.archived, false);
    expect(dto.label, 'none');
    expect(dto.cleared, isNull);
    expect(dto.zero, 0);
    expect(dto.empty, '');
    expect(dto.listDefault, ['a', 'b']);
    final cleared = api.Holder.fromJson({...required, 'archived': null, 'label': null, 'listDefault': null});
    expect(cleared.archived, isNull);
    expect(cleared.label, isNull);
    expect(cleared.listDefault, isNull);
  });
  test('keeps referenced objects and nullable collection items typed', () {
    final dto = api.Holder.fromJson({...required,
      'anyCard': {'name': 'first'}, 'oneCard': {'name': 'second'},
      'cards': [null, {'name': 'third'}],
      'reach': {'exclusions': {'a': 1}}, 'constNull': 'value', 'enumNull': 3,
    });
    final api.Card card = dto.anyCard!;
    expect(card.name, 'first');
    expect(dto.oneCard!.name, 'second');
    expect(dto.cards!.first, isNull);
    expect(dto.cards!.last!.name, 'third');
    expect(dto.reach!.exclusions, {'a': 1});
    expect(dto.constNull, 'value');
    expect(dto.enumNull, 3);
    expect(dto.toJson()['constNull'], 'value');
  });
  test('preserves named unions and rejects overlapping oneOf null', () {
    expect(api.NamedNullable.fromJson(null).toJson(), isNull);
    expect(api.HolderOverlap.fromJson('value').toJson(), 'value');
    expect(() => api.HolderOverlap.fromJson(null), throwsFormatException);
    expect(() => api.HolderOverlapConst.fromJson(null), throwsFormatException);
    expect(() => api.HolderConstrained.fromJson(null), throwsFormatException);
    expect(api.HolderConstrained.fromJson('value').toJson(), 'value');
    expect(() => api.Holder.fromJson({...required, 'overlap': null}),
      throwsA(predicate<Object>((error) => error.toString().contains('Expected exactly one HolderOverlap variant'))));
  });
}
''';

/// Checks null policy at each transport boundary, including per-call options.
String nullParametersDriver(
  String folder,
  HttpClientBackend backend, {
  required bool include,
  required bool defaults,
}) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  for (final withOptions in [false, true]) {
    test('serializes null parameters with options=\$withOptions', () async {
      final probe = Probe();
      ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://example.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
      final options = withOptions ? ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"} : null;
      await root.api.sendQuery(requiredQuery: null, options: options);
      expect(probe.uri.query.split('&').where((s) => s.isNotEmpty).toSet(), <String>{
        ${include ? "'requiredQuery', 'count', 'flag', 'label', 'tags'," : ''}
        ${defaults
      ? "'limit=7',"
      : include
      ? "'limit',"
      : ''}
      });
      await root.api.sendQuery(requiredQuery: null, limit: null, options: options);
      expect(probe.uri.query.split('&').where((s) => s.isNotEmpty).toSet(), <String>{${include ? "'requiredQuery', 'count', 'flag', 'label', 'tags', 'limit'" : ''}});
      await root.api.sendQuery(requiredQuery: '', count: 0, flag: false, label: '', tags: ['a', 'b'], limit: 0, options: options);
      expect(probe.uri.queryParametersAll, {'requiredQuery': [''], 'count': ['0'], 'flag': ['false'], 'label': [''], 'tags': ['a', 'b'], 'limit': ['0']});
      expect(probe.uri.query, contains('requiredQuery='));
      await root.api.sendHeaders(xRequired: null, options: options);
      for (final key in ['x-required', 'x-optional', 'x-tags', 'x-mode']) {
        expect(probe.header(key), ${include ? "'null'" : 'isNull'});
      }
      expect(probe.header('x-call'), withOptions ? 'yes' : null);
      await root.api.sendHeaders(xRequired: '', xOptional: 'value', xTags: ['a', 'b'], xMode: api.Mode.a, options: options);
      expect(probe.header('x-required'), '');
      expect(probe.header('x-optional'), 'value');
      expect(probe.header('x-tags'), 'a,b');
      expect(probe.header('x-mode'), 'a');
      await root.api.sendObjects(options: options);
      expect(probe.uri.query.split('&').where((s) => s.isNotEmpty).toSet(), <String>{${include ? "'filter', 'reserved', 'joined', 'json', 'mode', 'modes', 'dto', 'reservedMode', 'encoded'" : ''}});
      await root.api.sendObjects(filter: {'name': 'a'}, reserved: 'a/b', joined: ['a','b'], json: 'x', mode: api.Mode.a, modes: [api.Mode.b], dto: api.Filter(key: 'v', value: null), reservedMode: api.Mode.b, encoded: {'key': 'value'}, options: options);
      expect(probe.uri.queryParameters, {'name': 'a', 'reserved': 'a/b', 'joined': 'a|b', 'json': '"x"', 'mode': 'a', 'modes': 'b', 'dto[key]': 'v', 'dto[value]': '', 'reservedMode': 'b', 'encoded': 'key=value'});
      expect(probe.uri.query.split('&'), contains(${http ? "'dto%5Bvalue%5D='" : "'dto%5Bvalue%5D'"}));
      expect(probe.uri.query, contains('reserved=a/b'));
      ${include ? "await expectLater(root.api.sendObjects(filter: {'dto': 'value'}, options: options), throwsArgumentError);" : ''}
      await root.api.sendBody(body: api.Payload(value: null), options: options);
      expect(probe.uri.query, ${include ? "'q'" : "''"});
      expect(jsonDecode(probe.body), {'value': null});
      await root.api.sendForm(token: 'yes', options: options);
      expect(probe.uri.query, ${include ? "'q'" : "''"});
      expect(Uri.splitQueryString(probe.body), {'token': 'yes'});
      await root.api.sendMultipart(token: 'yes', options: options);
      expect(probe.uri.query, ${include ? "'q'" : "''"});
      expect(probe.body, contains('name="token"'));
      expect(probe.body, isNot(contains('name="value"')));
      final reserved = await root.api.reservedName(options: options);
      expect(reserved.ok, isTrue);
      expect(probe.uri.query, ${include ? "'q'" : "''"});
    });
  }
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late Map<String, Object?> headers;
  late String body;
  Object? header(String name) => headers.entries.where((e) => e.key.toLowerCase() == name).firstOrNull?.value;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    headers = Map.of(request.headers);
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    return http.StreamedResponse(Stream.value(utf8.encode('{"ok":true}')), 200, headers: {'content-type': 'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    headers = Map.of(options.headers);
    body = utf8.decode(await stream?.expand((v) => v).toList() ?? []);
    return ResponseBody.fromString('{"ok":true}', 200, headers: {'content-type': ['application/json']});
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}
