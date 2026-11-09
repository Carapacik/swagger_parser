import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';

/// Checks wire names independently from allocated Dart symbols.
String namingContractsDriver(
  String folder,
  HttpClientBackend backend,
  DtoSerializer serializer,
  DartGenerationModel model, {
  required bool enabled,
  required String values,
  required String models,
  required String words,
}) {
  final http = backend == HttpClientBackend.http;
  final DartClientOperation operation = model.libraries
      .expand((l) => l.operations)
      .single;
  final DartFacadeModel facade = model.libraries
      .map((l) => l.facade)
      .whereType<DartFacadeModel>()
      .single;
  final String dto = operation.body!.type.symbol;
  final DartEnumModel enumeration = model.libraries
      .expand((l) => l.enums)
      .singleWhere((e) => e.values.values.contains('100Continue'));
  String literal(Object? value) => jsonEncode(value).replaceAll(r'$', r'\$');
  final String args = operation.parameters
      .map(
        (p) =>
            '${p.name}: ${literal(p.location == DartClientParameterLocation.path ? 'route' : '${p.location.name}:${p.wireName}')}',
      )
      .join(',');
  final Map<String, String> query = {
    for (final p in operation.parameters)
      if (p.location == DartClientParameterLocation.query)
        p.wireName: 'query:${p.wireName}',
  };
  final String enumType = enumeration.name;
  final String declared = enumeration.openNames?.values ?? enumType;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;
final input = jsonDecode(${literal(values)}) as Map<String,dynamic>;
final modelInput = jsonDecode(${literal(models)}) as Map<String,dynamic>;
final words = jsonDecode(${literal(words)}) as List<dynamic>;
Object? json(Object? value) => jsonDecode(jsonEncode(value));
void main() {
 test('preserves punctuation, keywords, scalar types, and colliding names', () {
   expect(json(api.$dto.fromJson(input)),input);
   expect(json(api.AllModels.fromJson(modelInput)),modelInput);
   final first=api.ParentOne.fromJson({'state':'a'});
   final second=api.ParentTwo.fromJson({'state':'x'});
   expect(json(first),{'state':'a'});expect(json(second),{'state':'x'});
   expect(first.state.runtimeType,isNot(second.state.runtimeType));
   expect(api.${enabled ? 'SignedValue' : 'Signed'}.values.map((v)=>${enabled ? 'v.value' : 'v.toJson()'}),[1,-1,0]);
 });
 test('keeps declared enum order separate from unknown values', () {
   expect(api.$declared.values.map((v)=>${enabled ? 'v.value' : 'v.toJson()'}),words);
   for(final word in words) {
     final value=api.$enumType.fromJson(word);
     expect(value.toJson(),word);expect(value.toString(),isA<String>());
     ${enabled ? 'expect(value,isA<api.${enumeration.openNames!.known}>());' : ''}
   }
   ${enabled ? "final other=api.$enumType.fromJson('future');expect(other,isA<api.${enumeration.openNames!.unknown}>());expect(other.toJson(),'future');" : "expect(() => api.$enumType.fromJson('future'),throwsA(${serializer == DtoSerializer.jsonSerializable || serializer == DtoSerializer.freezed ? "isA<ArgumentError>().having((e)=>e.toString(),'message',contains('future'))" : "isA<FormatException>().having((e)=>e.message,'message','Unknown $enumType value.')"}));"}
   expect(() => api.$enumType.fromJson(1),throwsA(anything));
 });
 test('keeps path, query, header, cookie, and body names independent', () async {
   final probe=Probe();
   ${http ? "final root=api.${facade.name}(probe,baseUrl:Uri.parse('https://names.test'));" : "final dio=Dio(BaseOptions(baseUrl:'https://names.test'))..httpClientAdapter=probe;addTearDown(dio.close);final root=api.${facade.name}(dio);"}
   final result=await root.${facade.clients.keys.single}.${operation.name}($args,body:api.$dto.fromJson(input));
   expect(probe.uri.path,${literal(r'/UserJWTPair/$route/route')});
   expect(probe.uri.queryParameters,${literal(query)});
   expect(probe.headers['id'],'header:id');
   expect(probe.headers['x-api-key'],'header:x-api-key');
   expect(probe.headers[r'\$header'],r'header:\$header');
   ${operation.parameters.any((p) => p.location == DartClientParameterLocation.cookie) ? "expect(probe.headers['cookie'],contains('id=cookie%3Aid'));" : ''}
   expect(jsonDecode(probe.body),input);
   expect(json(result),input);
 });
}
class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
 late Uri uri;
 late Map<String,Object?> headers;
 String body='';
 ${http ? '''
 @override
 Future<http.StreamedResponse> send(http.BaseRequest request) async {
   uri=request.url;headers={for(final e in request.headers.entries)e.key.toLowerCase():e.value};
   body=utf8.decode(await request.finalize().expand((v)=>v).toList());
   return http.StreamedResponse(Stream.value(utf8.encode(jsonEncode(input))),200,headers:{'content-type':'application/json'});
 }
 ''' : '''
 @override
 Future<ResponseBody> fetch(RequestOptions options,Stream<Uint8List>? stream,Future<void>? cancel) async {
   uri=options.uri;headers={for(final e in options.headers.entries)e.key.toLowerCase():e.value};
   body=utf8.decode(await stream?.expand((v)=>v).toList()??[]);
   return ResponseBody.fromString(jsonEncode(input),200,headers:{'content-type':['application/json']});
 }
 @override
 void close({bool force=false}) {}
 '''}
}
''';
}
