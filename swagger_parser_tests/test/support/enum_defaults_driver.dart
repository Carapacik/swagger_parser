import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';

const _special =
    r'''quote'"\$line'''
    '\nnext';

/// Checks enum defaults against DTO codecs and encoded query/form values.
String enumDefaultsDriver(
  String folder,
  String version,
  HttpClientBackend backend, {
  required bool enabled,
}) {
  final http = backend == HttpClientBackend.http;
  final legacy = version == 'v2';
  final String special = jsonEncode(_special).replaceAll(r'$', r'\$');
  final queryUnit = legacy ? 'GetDefaultsUnit' : 'Unit';
  final querySort = legacy ? 'GetDefaultsSort' : 'Sort';
  final queryNumeric = legacy ? 'GetDefaultsNumeric' : 'Numeric';
  final formUnit = legacy ? 'SubmitFormUnit' : 'Unit';
  final formNumeric = legacy ? 'SubmitFormNumeric' : 'Numeric';
  final formState = legacy
      ? 'SubmitFormInlineState'
      : 'SubmitFormRequestInlineState';
  final formNullable = legacy ? 'SubmitFormNullable' : 'Nullable';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

const special = $special;
const jsonDefaults = {'unit': 'celsius', 'composed': 'celsius', 'sort': 'asc', 'protected': 'DEFAULT', 'inlineState': 'success', 'numeric': 5, 'special': special, 'nullable': null};
const parameterDefaults = {'unit': 'celsius', 'composed': 'celsius', 'sort': 'asc', 'protected': 'DEFAULT', 'inlineState': 'success', 'numeric': '5', 'special': special};

$_multipartReader

void main() {
  late Probe probe;
  late api.Api root;
  setUp(() {
    probe = Probe();
    ${http ? "root = api.Api(probe, baseUrl: Uri.parse('https://defaults.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://defaults.test'))..httpClientAdapter = probe; addTearDown(dio.close); root = api.Api(dio);"}
  });
  test('uses declared enum defaults in constructors and JSON codecs', () {
    const dto = api.Settings();
    expect(dto.unit, api.Unit.celsius);
    expect(dto.sort, api.Sort.asc);
    expect(dto.inlineState, api.SettingsInlineState.ready);
    expect(dto.numeric, api.Numeric.high);
    expect(dto.toJson(), jsonDefaults);
    expect(api.Settings.fromJson({}).toJson(), jsonDefaults);
    expect(api.Settings.fromJson({'nullable': null}).toJson(), jsonDefaults);
    final changed = {...jsonDefaults, 'unit': 'fahrenheit', 'composed': 'fahrenheit', 'sort': 'desc', 'protected': 'asc', 'inlineState': 'paused', 'numeric': 0, 'nullable': 'available', 'special': 'plain'};
    expect(api.Settings.fromJson(changed).toJson(), changed);
    expect(() => api.Settings.fromJson({'inlineState': 'SUCCESS'}), throwsA(anything));
    expect(() => api.Numeric.fromJson('5'), throwsA(anything));
    expect(api.Special.fromJson(special).toJson(), special);
    expect(() => api.Special.fromJson('bad ' + special), throwsA(anything));
  });
  for (final withOptions in [false, true]) {
    test('encodes query defaults=$enabled with options=\$withOptions', () async {
      final options = withOptions ? ${http ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes'})" : "Options(headers: {'X-Call': 'yes'})"} : null;
      await root.api.getDefaults(options: options);
      expect(probe.uri.queryParameters, ${enabled ? 'parameterDefaults' : 'isEmpty'});
      expect(probe.method, 'GET');
      await root.api.getDefaults(unit: null, composed: null, sort: null, protected: null, inlineState: null, numeric: null, special: null, options: options);
      expect(probe.uri.queryParameters, isEmpty);
      await root.api.getDefaults(unit: api.$queryUnit.fahrenheit, composed: ${legacy ? 'api.GetDefaultsComposed.fahrenheit' : "const api.UnitAlias('fahrenheit')"}, sort: api.$querySort.desc, protected: ${legacy ? 'api.GetDefaultsProtected.default2' : "const api.ProtectedSort('DEFAULT')"}, inlineState: api.GetDefaultsInlineState.paused, numeric: api.$queryNumeric.zero, special: null, options: options);
      expect(probe.uri.queryParameters, {'unit': 'fahrenheit', 'composed': 'fahrenheit', 'sort': 'desc', 'protected': 'DEFAULT', 'inlineState': 'paused', 'numeric': '0'});
    });
  }
  test('encodes enum form defaults as wire values and omits nulls', () async {
    await root.api.submitForm(token: 't');
    expect(probe.contentType, startsWith('application/x-www-form-urlencoded'));
    expect(Uri.splitQueryString(probe.body), {'token': 't', ${enabled ? '...parameterDefaults,' : ''}});
    await root.api.submitForm(token: 't', unit: null, composed: null, sort: null, protected: null, inlineState: null, numeric: null, special: null, nullable: null);
    expect(Uri.splitQueryString(probe.body), {'token': 't'});
    await root.api.submitForm(token: '', unit: api.$formUnit.fahrenheit, composed: null, sort: null, protected: null, inlineState: api.$formState.paused, numeric: api.$formNumeric.zero, special: null, nullable: api.$formNullable.available);
    expect(Uri.splitQueryString(probe.body), {'token': '', 'unit': 'fahrenheit', 'inlineState': 'paused', 'numeric': '0', 'nullable': 'available'});
  });
  test('encodes enum multipart defaults as unquoted wire values', () async {
    await root.api.submitMultipart(token: 't');
    expect(probe.contentType, startsWith('multipart/form-data;'));
    expect(parts(probe.body, probe.contentType), {'token': 't', ${enabled ? '...parameterDefaults,' : ''}});
    await root.api.submitMultipart(token: '', unit: null, composed: null, sort: null, protected: null, inlineState: null, numeric: null, special: null, nullable: null);
    expect(parts(probe.body, probe.contentType), {'token': ''});
  });
  test('sends typed enum JSON defaults independently from parameter substitution', () async {
    await root.api.saveSettings(body: const api.Settings());
    expect(probe.contentType, startsWith('application/json'));
    expect(jsonDecode(probe.body), jsonDefaults);
    await root.api.saveSettings(body: api.Settings.fromJson({...jsonDefaults, 'inlineState': 'paused', 'numeric': 0, 'nullable': 'available'}));
    expect(jsonDecode(probe.body), {...jsonDefaults, 'inlineState': 'paused', 'numeric': 0, 'nullable': 'available'});
  });
}


class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late Uri uri;
  late String method;
  late String body;
  late String contentType;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    uri = request.url;
    method = request.method;
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    contentType = request.headers['content-type'] ?? '';
    return http.StreamedResponse(const Stream<List<int>>.empty(), 204);
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    uri = options.uri;
    method = options.method;
    body = utf8.decode(await stream?.expand((v) => v).toList() ?? []);
    contentType = options.contentType ?? '';
    return ResponseBody.fromBytes([], 204);
  }
  @override
  void close({bool force = false}) {}
  '''}
}
''';
}

const _multipartReader = r'''
Map<String, String> parts(String body, String contentType) {
  final boundary = RegExp(r'boundary="?([^";]+)').firstMatch(contentType)!.group(1)!;
  final result = <String, String>{};
  for (final segment in body.split('--$boundary').skip(1)) {
    if (segment.startsWith('--')) break;
    final data = segment.substring(2, segment.length - 2);
    final end = data.indexOf('\r\n\r\n');
    final header = data.substring(0, end);
    final name = RegExp(r'name="([^"]+)"').firstMatch(header)!.group(1)!;
    result[name] = data.substring(end + 4);
  }
  return result;
}
''';
