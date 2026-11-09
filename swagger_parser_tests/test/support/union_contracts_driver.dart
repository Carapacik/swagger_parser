import 'package:swagger_parser/swagger_parser.dart';

/// Checks shared branches, nested unions, and custom codecs in response workers.
String unionContractsDriver(
  String folder,
  String version,
  HttpClientBackend backend, {
  required bool enabled,
}) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:async';
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;

$_values
void main() {
  test('shares standalone branches between named and inline unions', () {
    for (final tag in ['class','class_']) {
      final value=branch(tag);
      final union=api.ChoiceUnion.fromJson(value);
      expect(json(union),value);
      expect(union,tag=='class'?isA<api.${enabled ? 'HTTPItemA' : 'ItemA'}>():isA<api.ItemB>());
    }
    expect(api.OtherChoice.fromJson(branch('class')),isA<api.${enabled ? 'HTTPItemA' : 'ItemA'}>());
    expect(api.OtherChoice.fromJson(branch('int')),isA<api.ItemC>());
    final a=branch('class');final b=branch('class_');
    final recursive={...a,'child':b};
    expect(json(api.${enabled ? 'HTTPItemA' : 'ItemA'}.fromJson(recursive)),recursive);
    final envelope={'named':recursive,'inline':[a,b],'byName':{'a':a,'b':b},'other':branch('int')};
    expect(json(api.Envelope.fromJson(envelope)),envelope);
    expect(() => api.ChoiceUnion.fromJson({...a}..remove('type')),throwsA(anything));
    expect(() => api.ChoiceUnion.fromJson({...a,'type':'unknown'}),throwsA(anything));
    expect(() => api.ChoiceUnion.fromJson({...a,'class':12}),throwsA(anything));
  });
  test('keeps required nullable union fields distinct from optional fields', () {
    final missing=api.NullableHolder.fromJson({'requiredChoice':null});
    expect(json(missing),{'requiredChoice':null});
    expect(json(api.NullableHolder.fromJson({'requiredChoice':null,'optionalChoice':null})),{'requiredChoice':null});
    final value={'requiredChoice':branch('class'),'optionalChoice':branch('class_')};
    expect(json(api.NullableHolder.fromJson(value)),value);
  });
  test('retains overlapping anyOf views and empty structural variants', () {
    const both={'color':'red','red':true,'sweet':true};
    final fruit=api.Fruit.fromJson(both);
    expect(fruit.hasRed,isTrue);expect(fruit.hasSweet,isTrue);
    expect(fruit.asRed!.toJson()['color'],'red');
    expect(fruit.asSweet!.toJson()['color'],'red');
    expect(json(fruit),both);
    expect(api.Fruit.fromJson({'color':'red','red':false}).hasSweet,isFalse);
    expect(() => api.Fruit.fromJson({'red':true}),throwsA(anything));
    expect(json(api.EmptyChoice.fromJson(<String,Object?>{})),{});
    expect(json(api.EmptyChoice.fromJson({'name':'n'})),{'name':'n'});
    expect(() => api.EmptyChoice.fromJson({'extra':1}),throwsA(anything));
    expect(json(api.ScalarChoice.fromJson(12)),12);
    expect(json(api.ScalarChoice.fromJson('12')),'12');
    expect(() => api.Ambiguous.fromJson(12),throwsA(anything));
    ${version == 'v3_0' ? '' : "for (final value in [0,1,'0','1',null]) { expect(() => api.Contradictory.fromJson(value),throwsA(anything)); }"}
  });
  test('preserves offsets and decodes shared unions in the selected context', () async {
    final probe=Probe();
    ${http ? "final root=api.Api(probe,baseUrl:Uri.parse('https://unions.test'));" : "final dio=Dio(BaseOptions(baseUrl:'https://unions.test'))..httpClientAdapter=probe;addTearDown(dio.close);final root=api.Api(dio);"}
    for(final stamp in ['2026-01-02T03:04:05Z','2026-01-02T03:04:05+05:30','2026-01-02T03:04:05-04:00']) {
      final input=branch('class',stamp);
      probe.reply=input;
      final result=await runZoned(() => root.api.echoChoiceUnion(body:api.ChoiceUnion.fromJson(input)),zoneValues:{#decoderMarker:'caller'});
      expect(json(result),input);
      expect(jsonDecode(probe.body),input);
      expect((result as api.${enabled ? 'HTTPItemA' : 'ItemA'}).stamp.value,stamp);
      expect(result.stamp.context,${enabled ? "const bool.fromEnvironment('dart.library.js_interop') ? 'caller' : 'worker'" : "'caller'"});
    }
    final a=branch('class');
    probe.reply={'named':a,'inline':[a],'byName':{'a':a},'other':branch('int')};
    expect(json(await root.api.echoEnvelope(body:api.Envelope.fromJson(probe.reply as Map<String,Object?>))),probe.reply);
    probe.reply={'color':'red','red':true,'sweet':true};
    expect(json(await root.api.echoFruit(body:api.Fruit.fromJson(probe.reply as Map<String,Object?>))),probe.reply);
    probe.reply={};expect(json(await root.api.echoEmptyChoice(body:api.EmptyChoice.fromJson(<String,Object?>{}))),{});
    probe.reply='12';expect(json(await root.api.echoScalarChoice(body:api.ScalarChoice.fromJson('12'))),'12');
    for(final bad in [{...a,'stamp':'invalid'}, {...a,'type':'unknown'}]) {
      probe.reply=bad;
      await expectLater(root.api.echoChoiceUnion(body:api.ChoiceUnion.fromJson(a)),throwsA(anything));
    }
  });
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

const _values = r'''
Map<String,Object?> branch(String tag,[String stamp='2026-01-02T03:04:05+05:30']) => {
  'type':tag,'class':'keyword','snake_case':'wire',r'$value':'dollar',"quote'key":'quote','stamp':stamp,
};
Object? json(Object? value) => jsonDecode(jsonEncode(value));
''';
