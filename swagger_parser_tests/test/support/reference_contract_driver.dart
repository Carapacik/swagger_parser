import 'package:swagger_parser/swagger_parser.dart';

String referenceContractDriver(
  String folder,
  String version,
  ResponseMode mode,
) {
  final bool modern = version == 'v3_1' || version == 'v3_2';
  final all = mode == ResponseMode.allStatuses;
  String value(String call, String type, [String status = '200']) =>
      all ? '((await $call) as api.$type$status).value' : '(await $call)';
  return '''
import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:test/test.dart';
import '$folder/api.dart' as api;

const timestamp = '2024-02-29T23:30:45+01:00';
const scalarJson = <String, dynamic>{
  'date': '2024-02-29', 'timestamp': timestamp,
  'externalDate': '2024-02-29', 'externalTimestamp': timestamp,
  'count': 3, 'free': {'data': [null, 2, true]},
  'string': 'text', 'object': [1, 'two'], 'list': [1, 2],
  'map': {'x': 3}, 'uri': 'https://example.test/a',
};
const aliasJson = <String, dynamic>{
  'station': {'upper_code': 1}, 'stations': [{'upper_code': 2}],
  'byKey': {'north': {'upper_code': 3}},
  'credentials': {'login': 'user', 'password': 'secret'},
};

Object? wire(Object? value) => jsonDecode(jsonEncode(value));

void main() {
  test('keeps scalar formats, aliases, constraints, and reserved names', () {
    final dto = api.ScalarUse.fromJson(scalarJson);
    final String date = dto.date.value;
    final DateTime instant = dto.timestamp.value.value.value;
    final DateTime external = dto.externalTimestamp.value.value;
    expect(date, '2024-02-29');
    expect(dto.externalDate.value.value, date);
    expect(instant, DateTime.utc(2024, 2, 29, 22, 30, 45));
    expect(instant.isUtc && external.isUtc, true);
    expect(dto.count.value.value, 3);
    expect(dto.list.value, [1, 2]);
    expect(dto.map.value, {'x': 3});
    expect(dto.uri.value, 'https://example.test/a');
    expect(dto.validate(), isEmpty);
    expect(wire(dto), {...scalarJson, 'timestamp': instant.toIso8601String(), 'externalTimestamp': external.toIso8601String()});
    expect(api.ScalarUse.fromJson({...scalarJson, 'count': 0}).validate().map((e) => (e.path, e.keyword)), contains(('/count','minimum')));
    expect(api.ScalarUse.fromJson({...scalarJson, 'count': 10}).validate().map((e) => (e.path, e.keyword)), contains(('/count','maximum')));
    for (final value in [null, 2, 'text', false, [1], {'key': 2}]) {
      expect(api.FreeValue.fromJson(value).toJson(), value);
    }
  });
  test('resolves exact case, escaped keys, external types, and reference siblings', () {
    const json = <String, dynamic>{
      'upper': {'upper_code': 1}, 'lower': {'lower_code': 'lower'},
      'sibling': {'upper_code': 2${modern ? ", 'label': 'AB'" : ''}},
      'external': {'external': 'file'}, 'escaped': {'value': 'slash'},
      'encoded': {'encoded': 'space'}, 'query': 'unchanged', 'in': 'wire',
      'camel': {'camel_code': 'camel'}, 'pascal': {'pascal_code': 'pascal'},
      'flat': {'flat_code': 'flat'},
    };
    final dto = api.ReferenceUse.fromJson(json);
    expect(dto.upper.upperCode, 1);
    expect(dto.lower.lowerCode, 'lower');
    expect(dto.sibling.upperCode, 2);
    expect(dto.upper.runtimeType, isNot(dto.lower.runtimeType));
    expect(dto.camel.camelCode, 'camel');
    expect(dto.pascal.pascalCode, 'pascal');
    expect(dto.flat.flatCode, 'flat');
    expect({dto.camel.runtimeType, dto.pascal.runtimeType, dto.flat.runtimeType}, hasLength(3));
    expect(wire(dto.external2), {'external': 'file'});
    expect(dto.escaped.value, 'slash');
    expect(dto.encoded.encoded, 'space');
    expect(wire(dto), json);
    expect(dto.validate(), isEmpty);
    expect(wire(api.LowerStation.fromJson({'lower_code': 'lower','height': 4})), {'lower_code': 'lower','height': 4});
    ${modern ? "expect(api.ReferenceUse.fromJson({...json, 'sibling': {'upper_code': 2, 'label': 'A'}}).validate().map((e)=>(e.path,e.keyword)), contains(('/sibling/label','minLength')));" : ''}
  });
  test('round trips transitive object, list, and map aliases from one import', () {
    final dto = api.AliasUse.fromJson(aliasJson);
    final api.Station station = dto.station.value.value;
    expect(station.upperCode, 1);
    expect(dto.stations.value.value.single.value.value.upperCode, 2);
    expect(dto.byKey.value.value['north']!.value.value.upperCode, 3);
    expect(dto.credentials.value.login, 'user');
    expect(wire(dto), aliasJson);
    expect(dto.validate(), isEmpty);
  });
  test('uses reusable parameters, bodies, and response types on the wire', () async {
    final adapter = Adapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    final api.Api root = api.Api(dio);
    final first = ${value("root.api.lookup(id: 'north', query2: 'wire')", 'Lookup')};
    expect(first.upperCode, 5);
    final request = adapter.last!;
    expect(request.uri.queryParametersAll['tag'], ['north','south']);
    expect(request.uri.queryParameters['limit'], '7');
    expect(request.uri.queryParameters['query'], 'wire');
    expect(request.headers['limit'].toString(), '9');
    await root.api.inlineLookup(id: 'north', query2: 'wire');
    expect(adapter.last!.uri.query, request.uri.query);
    expect(adapter.last!.headers, request.headers);
    final login = ${value("root.api.login(body: api.Credentials${version == 'v2' ? '2' : ''}.fromJson({'login':'user','password':'secret'}))", 'Login')};
    expect(wire(login), {'external':'logged-in'});
    expect(jsonDecode(adapter.body), {'login':'user','password':'secret'});
    final form = ${value("root.api.submitForm(login: 'user', password: 'secret')", 'SubmitForm')};
    expect(wire(form), {'external':'logged-in'});
    expect(Uri.splitQueryString(adapter.body), {'login':'user','password':'secret'});
    final multipart = ${value("root.api.submitMultipart(login: 'user', password: 'secret')", 'SubmitMultipart')};
    expect(wire(multipart), {'external':'logged-in'});
    expect(adapter.body, contains('name="login"'));
    expect(adapter.body, contains('name="password"'));
    expect(adapter.body, contains('secret'));
    final aliases = ${value('root.api.aliases(body: api.AliasUse.fromJson(aliasJson))', 'Aliases')};
    expect(jsonDecode(adapter.body), aliasJson);
    expect(wire(aliases), aliasJson);
    final listed = ${value('root.api.listStations()', 'ListStations')};
    expect(listed.single.value.value.upperCode, 5);
    final accepted = ${value('root.api.accepted()', 'Accepted', '202')};
    expect(accepted.upperCode, 5);
    final typed = ${value('root.api.typed()', 'Typed')};
    expect(typed.upperCode, 5);
    final escaped = ${value('root.api.escapedResponse()', 'EscapedResponse')};
    expect(wire(escaped), {'external':'logged-in'});
    final scalar = ${value('root.api.scalar()', 'Scalar')};
    expect(scalar.value.value.value.isUtc, true);
    ${all ? "expect(((await root.api.failure()) as api.Failure400).value.message, 'Denied'); expect(((await root.api.lookup(id: 'error')) as api.Lookup400).value.message, 'Denied');" : "final Future<void> failure = root.api.failure(); await expectLater(failure, throwsA(isA<DioException>())); await expectLater(root.api.lookup(id: 'error'), throwsA(isA<DioException>()));"}
  });
}

class Adapter implements HttpClientAdapter {
  RequestOptions? last;
  String body = '';
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    last = options;
    body = requestStream == null ? '' : await utf8.decoder.bind(requestStream).join();
    final path = options.uri.path;
    final error = path == '/failure' || path.endsWith('/error');
    final Object? value = error ? {'message': 'Denied'} : switch(path) {
      '/login' || '/form' || '/multipart' || '/escaped' => {'external':'logged-in'},
      '/aliases' => jsonDecode(body),
      '/stations' => [{'upper_code': 5}],
      '/scalar' => timestamp,
      _ => {'upper_code': 5},
    };
    return ResponseBody.fromString(jsonEncode(value), error ? 400 : path == '/accepted' ? 202 : 200, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}
''';
}

String dynamicReferenceDriver(String folder) =>
    '''
import 'dart:convert';
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('keeps two concrete page bindings and recursive items separate', () {
    const labels = {'items': ['AB'], 'next': {'items': ['CD']}};
    const numbers = {'items': [2], 'next': {'items': [3]}};
    final first = api.LabelPage.fromJson(labels);
    final second = api.NumberPage.fromJson(numbers);
    final List<String> names = first.value.items;
    final List<int> values = second.value.items;
    expect(names, ['AB']);
    expect(values, [2]);
    expect(first.value.next!.items, ['CD']);
    expect(second.value.next!.items, [3]);
    expect(jsonDecode(jsonEncode(first)), labels);
    expect(jsonDecode(jsonEncode(second)), numbers);
    expect(first.validate(), isEmpty);
    expect(second.validate(), isEmpty);
    expect(api.LabelPage.fromJson({'items':['A']}).validate().map((e)=>(e.path,e.keyword)), contains(('/items/0','minLength')));
    expect(api.NumberPage.fromJson({'items':[0]}).validate().map((e)=>(e.path,e.keyword)), contains(('/items/0','minimum')));
    expect(api.LabelPage.fromJson({'items':['AB'],'next':{'items':['C']}}).validate().map((e)=>(e.path,e.keyword)), contains(('/next/items/0','minLength')));
  });
  test('resolves nested dynamic scopes and external anchors', () {
    final List<int> defaults = api.DefaultPacket.fromJson([2]).value.asArray!;
    expect(defaults, [2]);
    final names = api.Names.fromJson({'next':['A1']});
    final List<String> strings = names.value.asObject!.next.asArray!;
    expect(strings, ['A1']);
    expect(() => api.Names.fromJson({'next':['A']}), throwsFormatException);
    expect(() => api.DefaultPacket.fromJson(['A1']), throwsFormatException);
    final imported = api.Imported.fromJson(['x1']).value.value;
    expect(imported.asArray!.single.value, 'x1');
    expect(() => api.Imported.fromJson(['A1']), throwsFormatException);
    final choice = api.Choice.fromJson({'next':[true]}) as api.ChoiceNames;
    final List<bool> flags = choice.value.asObject!.next.asArray!;
    expect(flags, [true]);
    expect(api.Choice.fromJson(choice.toJson()), isA<api.ChoiceNames>());
    expect(api.Choice.fromJson('off'), isA<api.ChoiceString>());
    expect(() => api.Choice.fromJson({'next':['A1']}), throwsFormatException);
  });
  test('keeps static fallback constraints and recursive dynamic targets', () {
    final both = api.StaticFallback.fromJson(2);
    expect(both.hasInteger && both.hasInteger2 && !both.hasVariant3, true);
    expect(api.StaticFallback.fromJson(1).hasInteger, false);
    expect(api.StaticFallback.fromJson(4).hasInteger2, false);
    expect(() => api.StaticFallback.fromJson('A1'), throwsFormatException);
    expect(api.StaticFallback.fromJson([false]).asArray, [false]);
    expect(() => api.StaticFallback.fromJson([]), throwsFormatException);
    expect(api.Combined.fromJson(2).hasInteger, true);
    expect(() => api.Combined.fromJson(3), throwsFormatException);
    expect(() => api.Combined.fromJson(-2), throwsFormatException);
    final tree = api.Tree.fromJson([['leaf']]) as api.TreeArray;
    expect((tree.value.single as api.TreeArray).value.single, isA<api.TreeString>());
    expect(() => api.Tree.fromJson([1]), throwsFormatException);
    final nested = api.NumberTree.fromJson([1]).asTree! as api.Tree2Array;
    expect(nested.value.single.asInteger, 1);
    expect(api.NumberTree.fromJson(nested.toJson()).hasTree, true);
  });
}
''';
