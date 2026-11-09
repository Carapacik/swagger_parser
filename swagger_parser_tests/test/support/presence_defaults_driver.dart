import 'package:swagger_parser/swagger_parser.dart';

/// Checks field presence, defaults, and encoded PATCH bodies.
String presenceDefaultsDriver(
  String folder,
  HttpClientBackend backend,
  DtoSerializer serializer, {
  required bool records,
}) {
  final http = backend == HttpClientBackend.http;
  final bool copy =
      serializer == DtoSerializer.freezed ||
      serializer == DtoSerializer.dartMappable;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('round trips missing, null, and value fields without presence flags', () {
    expect(api.PatchChanges().toJson(), isEmpty);
    expect(api.PatchChanges.fromJson({}).toJson(), isEmpty);
    final empty = api.PatchChanges(notes: ${records ? '(value: null)' : 'null'}, notesPresent: false);
    expect(empty.toJson(), {'notesPresent': false, ${records ? "'notes': null," : ''}});
    final named = api.PatchChanges(notes: ${records ? "(value: 'N')" : "'N'"}, notesPresent: true);
    expect(named.toJson(), {'notes': 'N', 'notesPresent': true});
    for (final value in [null, 'N']) {
      final json = {'notes': value, 'notesPresent': false, 'display-name': value, 'alias': value, 'nested': {'inner_value': value, 'notesPresent': true}, 'copyWith': 'wire field'};
      final expected = {'notesPresent': false, 'nested': {'notesPresent': true, if (${records ? 'true' : 'value != null'}) 'inner_value': value}, 'copyWith': 'wire field', if (${records ? 'true' : 'value != null'}) ...{'notes': value, 'display-name': value, 'alias': value}};
      final dto = api.PatchChanges.fromJson(json);
      expect(dto.toJson(), expected);
      expect(api.PatchChanges.fromJson(dto.toJson()).toJson(), expected);
    }
    for (final key in ['notesPresent', 'copyWith', 'nested']) {
      expect(() => api.PatchChanges.fromJson({key: null}), throwsA(anything));
    }
  });
  ${copy ? """
  test('copies nullable fields without changing ordinary presence-named fields', () {
    final start = api.PatchChanges(notes: ${records ? "(value: 'N')" : "'N'"}, notesPresent: true);
    expect(start.copyWith().toJson(), {'notes': 'N', 'notesPresent': true});
    final omitted = start.copyWith(notes: null);
    expect(omitted.toJson(), {'notesPresent': true});
    final cleared = start.copyWith(notes: ${records ? '(value: null)' : 'null'});
    expect(cleared.toJson(), {'notesPresent': true, ${records ? "'notes': null," : ''}});
    final set = omitted.copyWith(notes: ${records ? "(value: 'next')" : "'next'"}, notesPresent: false);
    expect(set.toJson(), {'notes': 'next', 'notesPresent': false});
    final child = api.PatchNested(innerValue: ${records ? "(value: 'child')" : "'child'"}, notesPresent: false);
    final nested = start.copyWith(nested: child.copyWith(innerValue: ${records ? '(value: null)' : 'null'}));
    expect(nested.toJson()['nested'], {'notesPresent': false, ${records ? "'inner_value': null," : ''}});
    expect(nested.copyWith(nested: null).toJson(), start.toJson());
  });
  """ : ''}
  test('uses defaults only for absent optional keys', () {
    final dto = api.Options2\$Request(id: 's', requiredName: null);
    final json = dto.toJson();
    expect(dto.limit, 20);
    expect(dto.name, 'North');
    expect(dto.enabled, false);
    expect(json['required_name'], isNull);
    expect(json.containsKey('required_name'), isTrue);
    expect(json['inherited'], 2);
    expect(json['status'], 'new');
    expect(json['count'], 3);
    expect(json['profile'], {'label': 'Main', 'status': 'active'});
    expect(json['server_id'], isNull);
    expect(json['secret'], 'secret');
    expect(api.Options2\$Request.fromJson({'id': 's', 'required_name': null}).toJson(), json);
    for (final key in ['id', 'required_name']) {
      final missing = <String, Object?>{'id': 's', 'required_name': null}..remove(key);
      expect(() => api.Options2\$Request.fromJson(missing), throwsA(anything));
    }
    for (final key in ['id', 'limit', 'enabled', 'tags', 'empty', 'weights', 'status', 'profile', 'count', 'inherited']) {
      expect(() => api.Options2\$Request.fromJson({'id': 's', 'required_name': null, key: null}), throwsA(anything));
    }
    final explicit = api.Options2\$Request.fromJson({'id': 's', 'required_name': 'R', 'name': null, 'limit': 0, 'enabled': true, 'tags': [], 'empty': [0], 'weights': <String, Object?>{}, 'status': 'active', 'profile': {'label': ''}, 'count': 0});
    expect(explicit.name, isNull);
    expect(explicit.toJson().containsKey('name'), isTrue);
    expect(explicit.toJson()['name'], isNull);
    expect(explicit.limit, 0);
    expect(explicit.tags, isEmpty);
    expect(explicit.empty, [0]);
    expect(explicit.weights, isEmpty);
    expect(explicit.profile.toJson(), {'label': '', 'status': 'new'});
    expect(explicit.toJson()['count'], 0);
    expect(api.Options2\$Request(id: 's', requiredName: null, name: null).toJson()['name'], isNull);
    expect(json.containsKey('nil'), isTrue);
    expect(json['nil'], isNull);
  });
  test('keeps nested default collections const and supplied collections mutable', () {
    const expected = {'empty': <String>[], 'rows': [<int>[], [1]], 'groups': {'east': ['a']}, 'empty_map': <String, int>{}, 'status': 'new', 'rank': 0};
    final dto = api.CollectionDefaults();
    expect(dto.toJson(), expected);
    expect(api.CollectionDefaults.fromJson({}).toJson(), expected);
    expect(() => dto.empty.add('x'), throwsUnsupportedError);
    expect(() => dto.rows.add([2]), throwsUnsupportedError);
    expect(() => dto.rows.first.add(2), throwsUnsupportedError);
    expect(() => dto.groups['east']!.add('x'), throwsUnsupportedError);
    expect(() => dto.emptyMap['x'] = 1, throwsUnsupportedError);
    expect(api.CollectionDefaults().toJson(), expected);
    final rows = <List<int>>[[2]];
    final groups = <String, List<String>>{'west': ['b']};
    final supplied = api.CollectionDefaults(rows: rows, groups: groups);
    supplied.rows.first.add(3);
    supplied.groups['west']!.add('c');
    expect(rows, [[2, 3]]);
    expect(groups, {'west': ['b', 'c']});
    for (final key in expected.keys) {
      expect(() => api.CollectionDefaults.fromJson({key: null}), throwsA(anything));
    }
    const changed = {'empty': ['x'], 'rows': <List<int>>[], 'groups': <String, List<String>>{}, 'empty_map': {'n': 2}, 'status': 'active', 'rank': 1};
    expect(api.CollectionDefaults.fromJson(changed).toJson(), changed);
  });
  test('sends PATCH bytes for both nullable APIs and materialized defaults', () async {
    final probe = Probe();
    ${http ? "final root = api.Api(probe, baseUrl: Uri.parse('https://patch.test'));" : "final dio = Dio(BaseOptions(baseUrl: 'https://patch.test'))..httpClientAdapter = probe; addTearDown(dio.close); final root = api.Api(dio);"}
    for (final value in [<String, Object?>{}, {'notes': null}, {'notes': 'N'}, {'notesPresent': false, 'display-name': null, 'alias': null, 'nested': {'inner_value': null, 'notesPresent': true}, 'copyWith': 'data'}]) {
      final dto = api.PatchChanges.fromJson(value);
      await root.api.patchChanges(body: dto);
      expect(probe.method, 'PATCH');
      expect(probe.uri.path, '/changes');
      expect(probe.contentType, startsWith('application/json'));
      expect(jsonDecode(probe.body), dto.toJson());
      if (value.isEmpty) expect(probe.body, '{}');
      if (value.length == 1 && value.containsKey('notes')) {
        expect(jsonDecode(probe.body), ${records ? 'value' : "value['notes'] == null ? isEmpty : value"});
      }
    }
    const required = {'id': 's', 'required_note': null};
    const defaults = {...required, 'default_label': 'North', 'default_count': 0, 'enabled': false};
    final empty = api.PatchEnvelope(id: 's', requiredNote: null);
    expect(empty.toJson(), defaults);
    expect(api.PatchEnvelope.fromJson(required).toJson(), defaults);
    await root.api.patchEnvelope(body: empty);
    expect(jsonDecode(probe.body), defaults);
    final changed = api.PatchEnvelope.fromJson({...required, 'default_label': null, 'changes': {'notes': null, 'notesPresent': false}});
    await root.api.patchEnvelope(body: changed);
    expect(probe.uri.path, '/envelope');
    expect(jsonDecode(probe.body), {...defaults, 'default_label': null, 'changes': {'notesPresent': false, ${records ? "'notes': null," : ''}}});
    for (final key in required.keys) {
      final missing = Map<String, Object?>.of(required)..remove(key);
      expect(() => api.PatchEnvelope.fromJson(missing), throwsA(anything));
    }
    for (final key in ['default_count', 'enabled', 'changes']) {
      expect(() => api.PatchEnvelope.fromJson({...required, key: null}), throwsA(anything));
    }
    ${copy ? """
    final initial = api.PatchChanges(notes: ${records ? "(value: 'N')" : "'N'"}, notesPresent: false);
    await root.api.patchChanges(body: initial.copyWith(notes: null));
    expect(jsonDecode(probe.body), {'notesPresent': false});
    await root.api.patchChanges(body: initial.copyWith(notes: ${records ? '(value: null)' : 'null'}));
    expect(jsonDecode(probe.body), {'notesPresent': false, ${records ? "'notes': null," : ''}});
    """ : ''}
  });
}

class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  late String method;
  late Uri uri;
  late String body;
  late String contentType;
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    method = request.method;
    uri = request.url;
    body = utf8.decode(await request.finalize().expand((v) => v).toList());
    contentType = request.headers['content-type'] ?? '';
    return http.StreamedResponse(const Stream<List<int>>.empty(), 204);
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    method = options.method;
    uri = options.uri;
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
