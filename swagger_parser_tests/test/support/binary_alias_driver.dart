import 'package:swagger_parser/swagger_parser.dart';

String binaryAliasDriver(String folder, HttpClientBackend backend) {
  final http = backend == HttpClientBackend.http;
  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart' as dio;"}
import 'package:test/test.dart';
import '$folder/api.dart';

void main() {
  test('sends file bytes and decodes referenced results', () async {
    final routes = <String>[];
    List<int> reply(Uri uri, List<int> body, String? contentType) {
      routes.add(uri.path);
      switch(uri.path) {
        case '/download': return [0, 255, 13, 10];
        case '/files': return utf8.encode('[{"file_name":"remote.bin"}]');
        case '/file-id': return utf8.encode('"file-42"');
        case '/upload':
          expect(contentType, startsWith('multipart/form-data;'));
          final parts = latin1.decode(body);
          expect(parts, contains('name="file"'));
          expect(parts, contains('filename="data.bin"'));
          expect(parts, contains(String.fromCharCodes([0,255,13,10])));
          return [];
        default: throw StateError('Unexpected path.');
      }
    }
    ${http ? "final transport = MockClient((request) async => http.Response.bytes(reply(request.url, request.bodyBytes, request.headers['content-type']), request.url.path == '/upload' ? 204 : 200, headers:{'content-type':request.url.path == '/download' ? 'application/octet-stream':'application/json'})); final api=Api(transport,baseUrl:Uri.parse('https://example.test'));" : "final transport=dio.Dio(dio.BaseOptions(baseUrl:'https://example.test')); transport.httpClientAdapter=Adapter(reply); final api=Api(transport);"}
    final List<int> bytes = await api.api.download();
    expect(bytes, [0,255,13,10]);
    await api.api.upload(file: ${http ? 'http' : 'dio'}.MultipartFile.fromBytes(${http ? "'file', " : ''}[0,255,13,10],filename:'data.bin'));
    expect(jsonDecode(jsonEncode(await api.api.listFiles())), [{'file_name':'remote.bin'}]);
    expect(jsonDecode(jsonEncode(await api.api.fileId())), 'file-42');
    final FileInfo own = FileInfo(fileName:'local.bin');
    expect(own.toJson(), {'file_name':'local.bin'});
    expect(routes, ['/download','/upload','/files','/file-id']);
    transport.${http ? 'close()' : 'close(force:true)'};
  });
}
${http ? '' : '''
class Adapter implements dio.HttpClientAdapter {
  Adapter(this.reply);
  final List<int> Function(Uri,List<int>,String?) reply;
  @override Future<dio.ResponseBody> fetch(dio.RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    final bytes = stream == null ? <int>[] : await stream.expand((b) => b).toList();
    return dio.ResponseBody.fromBytes(reply(options.uri,bytes,options.contentType), options.path == '/upload' ? 204 : 200, headers:{'content-type':[options.path == '/download'?'application/octet-stream':'application/json']});
  }
  @override void close({bool force=false}) {}
}
'''}
''';
}
