import 'package:swagger_parser/swagger_parser.dart';

/// Checks container, item, reference, and composition nullability.
String nullableCollectionsDriver(
  String folder,
  String version,
  HttpClientBackend backend, {
  required bool enabled,
}) {
  final http = backend == HttpClientBackend.http;
  final bool modern = version == 'v3_1' || version == 'v3_2';
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

Map<String, Object?> wire() => {
  'listRequiredRequired': ['a'], 'mapRequiredRequired': {'a':'b'},
  'listRequiredNullable': [null, 'a'], 'mapRequiredNullable': {'a':null,'b':'c'},
  'listNullableRequired': null, 'mapNullableRequired': null,
  'listNullableNullable': [null,'a'], 'mapNullableNullable': {'a':null},
  'refs': [null,'a'], 'nested': [null, {'a':null,'b':[null,'c']}],
  'criteria': null, 'gender': null, 'empty': [], 'filled': ['a'],
};
Object? json(Object? value) => jsonDecode(jsonEncode(value));
void main() {
  test('keeps all container and item nullability combinations', () {
    final input = wire();
    final dto = api.NullableCollections.fromJson(input);
    final List<String> a = dto.listRequiredRequired;
    final List<String?> b = dto.listRequiredNullable;
    final List<String>? c = dto.listNullableRequired;
    final List<String?>? d = dto.listNullableNullable;
    final Map<String,String> e = dto.mapRequiredRequired;
    final Map<String,String?> f = dto.mapRequiredNullable;
    final Map<String,String>? g = dto.mapNullableRequired;
    final Map<String,String?>? h = dto.mapNullableNullable;
    final List<Map<String,List<String?>?>?>? nested = dto.nested;
    expect([a,b,c,d,e,f,g,h,nested], [input['listRequiredRequired'],input['listRequiredNullable'],input['listNullableRequired'],input['listNullableNullable'],input['mapRequiredRequired'],input['mapRequiredNullable'],input['mapNullableRequired'],input['mapNullableNullable'],input['nested']]);
    expect(json(dto),input);
    expect(dto.validate(),isEmpty);
    for (final key in ['listRequiredRequired','listRequiredNullable','mapRequiredRequired','mapRequiredNullable']) {
      expect(() => api.NullableCollections.fromJson({...input,key:null}),throwsA(anything),reason:key);
    }
    for (final key in ['listRequiredRequired','listNullableRequired']) {
      expect(() => api.NullableCollections.fromJson({...input,key:[null]}),throwsA(anything),reason:key);
    }
    for (final key in ['mapRequiredRequired','mapNullableRequired']) {
      expect(() => api.NullableCollections.fromJson({...input,key:{'x':null}}),throwsA(anything),reason:key);
    }
    for (final key in ['listNullableRequired','listNullableNullable','mapNullableRequired','mapNullableNullable','nested','criteria']) {
      expect(json(api.NullableCollections.fromJson({...input,key:null})),{...input,key:null});
    }
    final values = {...input,'listNullableRequired':['x'],'mapNullableRequired':{'x':'y'},'criteria':{'code':'c'}};
    expect(json(api.NullableCollections.fromJson(values)),values);
  });
  test('keeps required presence, optional references, and collection defaults', () {
    final input=wire();
    expect(() => api.NullableCollections.fromJson({...input}..remove('criteria')),throwsA(anything));
    final missing=api.NullableCollections.fromJson({...input}..remove('empty')..remove('filled'));
    expect(missing.empty,isEmpty);
    expect(missing.filled,['a']);
    expect(() => missing.empty.add('x'),throwsUnsupportedError);
    final explicit=api.NullableCollections.fromJson({...input,'optionalCriteria':null});
    expect(json(explicit),${enabled ? "{...input,'optionalCriteria':null}" : 'input'});
    expect(json(api.NullableCollections.fromJson({...input,'optionalCriteria':{'code':'x'},'optionalList':['y']})),{...input,'optionalCriteria':{'code':'x'},'optionalList':['y']});
  });
  test('decodes nullable and empty object responses through each client', () async {
    final probe=Probe();
    ${http ? "final root=api.Api(probe,baseUrl:Uri.parse('https://collections.test'));" : "final dio=Dio(BaseOptions(baseUrl:'https://collections.test'))..httpClientAdapter=probe;addTearDown(dio.close);final root=api.Api(dio);"}
    final input=wire();probe.reply=input;
    expect(json(await root.api.echoCollections(body:api.NullableCollections.fromJson(input))),input);
    expect(jsonDecode(probe.body),input);
    probe.reply={'extra':[null,{'unicode':'Ж'}]};
    expect(json(await root.api.getFreeObject()),probe.reply);
    probe.reply={};expect(json(await root.api.getClosedObject()),{});
    probe.reply={'extra':1};await expectLater(root.api.getClosedObject(),throwsA(anything));
    probe.reply={'name':'one'};expect((await root.api.getSingleObject()).name,'one');
    probe.reply=null;expect(await root.api.getCriteria(),isNull);expect(await root.api.getGender(),isNull);
    probe.reply={'code':'c'};expect((await root.api.getCriteria())!.code,'c');
    probe.reply='female';expect(json(await root.api.getGender()),'female');
  });
  ${modern ? _modern : ''}
}
class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
  Object? reply;
  String body='';
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    body=utf8.decode(await request.finalize().expand((v)=>v).toList());
    return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(reply))),200,headers:{'content-type':'application/json'});
  }
  ''' : '''
  @override
  Future<ResponseBody> fetch(RequestOptions options,Stream<Uint8List>? stream,Future<void>? cancel) async {
    body=utf8.decode(await stream?.expand((v)=>v).toList()??[]);
    return ResponseBody.fromString(jsonEncode(reply),200,headers:{'content-type':['application/json']});
  }
  @override
  void close({bool force=false}) {}
  '''}
}
''';
}

const _modern = '''
  test('keeps reversed type arrays and both null branch orders', () {
    const empty={'text':null,'at':null,'state':null,'number':null};
    expect(json(api.ReverseTypes.fromJson(empty)),empty);
    const data={'text':'x','at':'2026-01-02T03:04:05Z','state':'01','number':1};
    final dto=api.ReverseTypes.fromJson(data);
    expect(dto.at!.isUtc,isTrue);
    expect(dto.at!.hour,3);
    expect(json(dto),{...data,'at':'2026-01-02T03:04:05.000Z'});
    expect(() => api.ReverseTypes.fromJson({...data,'state':1}),throwsA(anything));
    const stamp='2026-01-02T03:04:05+02:00';
    for (final decode in [api.AnyofFirst.fromJson,api.AnyofLast.fromJson]) {
      expect(json(decode(null)),isNull);
      expect(json(decode(stamp)),stamp);
    }
    expect(api.AnyofFirst.fromJson(stamp).asString!.toIso8601String(),'2026-01-02T01:04:05.000Z');
    expect(api.AnyofLast.fromJson(stamp).asString!.toIso8601String(),'2026-01-02T01:04:05.000Z');
    for (final decode in [api.OneofFirst.fromJson,api.OneofLast.fromJson]) {
      expect(json(decode(null)),isNull);
      expect(json(decode(stamp)),'2026-01-02T01:04:05.000Z');
    }
    expect(() => api.OverlappingNull.fromJson(null),throwsA(anything));
    expect(json(api.OverlappingAnyNull.fromJson(null)),isNull);
  });
  test('intersects outer and branch item constraints without dropping nulls', () {
    for (final value in [null,[null,1,5]]) {
      final dto=api.ComposedLists.fromJson({'first':value,'last':value});
      expect(json(dto),{'first':value,'last':value});
      expect(dto.validate(),isEmpty);
    }
    for (final value in [[0],[6],['1']]) {
      expect(() => api.ComposedLists.fromJson({'first':value,'last':value}),throwsA(anything));
    }
  });
''';
