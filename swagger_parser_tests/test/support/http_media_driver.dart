import 'package:swagger_parser/swagger_parser.dart';

/// Checks request media selection and scalar cookie encoding.
String httpMediaDriver(
  String folder,
  String version,
  HttpClientBackend backend,
) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;
void main() {
 test('sends JSON, patch, vendor, and mixed-content bodies once', () async {
  final probe=Probe();
  ${http ? "final root=api.Api(probe,baseUrl:Uri.parse('https://media.test'));" : "final dio=Dio(BaseOptions(baseUrl:'https://media.test'))..httpClientAdapter=probe;addTearDown(dio.close);final root=api.Api(dio);"}
  const dto=api.User(value:'user');
  for(final (send,media) in [(root.api.sendJson,'application/json'),(root.api.sendPatch,'application/json-patch+json'),(root.api.sendVendor,'application/vnd.example+json')]) {
   await send(body:dto);
   expect(probe.contentType,startsWith(media));
   expect(jsonDecode(probe.body),{'value':'user'});
  }
  await root.api.sendMixed(body:[dto]);
  expect(probe.contentType,startsWith('application/json'));
  expect(jsonDecode(probe.body),[{'value':'user'}]);
  expect(api.TokenObtainPair.fromJson({'value':'token'}).toJson(),{'value':'token'});
  expect(api.TokenRefresh.fromJson({'value':'refresh'}).toJson(),{'value':'refresh'});
  ${version == 'v2' ? '' : "await root.api.cookies(scalar:'a b',array:['one','two'],object:{'a':'b'}); expect(probe.cookie,contains('scalar=a%20b')); expect(probe.cookie,contains('${version == 'v3_2' ? 'array=one; array=two' : 'array=one,two'}')); expect(probe.cookie,contains('${version == 'v3_2' ? 'a=b' : 'object=a,b'}'));"}
 });
}
class Probe ${http ? 'extends http.BaseClient' : 'implements HttpClientAdapter'} {
 String body='';String contentType='';String cookie='';
 ${http ? '''
 @override
 Future<http.StreamedResponse> send(http.BaseRequest request) async {
  body=utf8.decode(await request.finalize().expand((v)=>v).toList());contentType=request.headers['content-type']??'';cookie=request.headers['cookie']??'';
  return http.StreamedResponse(const Stream<List<int>>.empty(),204);
 }
 ''' : '''
 @override
 Future<ResponseBody> fetch(RequestOptions options,Stream<Uint8List>? stream,Future<void>? cancel) async {
  body=utf8.decode(await stream?.expand((v)=>v).toList()??[]);contentType=options.contentType??'';cookie=options.headers['Cookie'] as String? ?? '';
  return ResponseBody.fromBytes([],204);
 }
 @override
 void close({bool force=false}) {}
 '''}
}
''';
}
