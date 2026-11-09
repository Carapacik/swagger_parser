import 'package:swagger_parser/swagger_parser.dart';

String multipartContractDriver(
  String folder,
  String version,
  HttpClientBackend backend,
) {
  final http = backend == HttpClientBackend.http;
  final old = version == 'v2';
  return r'''
import 'dart:convert';
TRANSPORT_IMPORT
import 'package:test/test.dart';
import 'IMPORT/api.dart' as api;

FILE_FACTORY
RAW_FACTORY

void main() {
  late Probe probe;
  late api.ApiClient client;
  setUp(() {
    probe = Probe();
    CREATE_CLIENT
  });
  test('sends native files with exact bytes and optional fields', () async {
    await client.uploadNative(photo: file('photo', [0, 255, 13, 10], 'photo.bin'), label: 'a & café');
    expect(probe.parts.map((p) => p.name), containsAll(['photo', 'label']));
    expect(probe.part('photo').bytes, [0, 255, 13, 10]);
    expect(probe.part('photo').filename, 'photo.bin');
    expect(probe.part('photo').contentType, 'application/octet-stream');
    expect(probe.part('label').text, 'a & café');
    expect(probe.parts, hasLength(2));
    await client.uploadSingle(label: 'empty');
    expect(probe.parts.map((p) => p.name), ['label']);
    await client.uploadSingle(label: '', photo: file('photo', [], 'empty.bin'), note: '');
    expect(probe.parts, hasLength(3));
    expect(probe.part('photo').bytes, isEmpty);
    expect(probe.part('photo').filename, 'empty.bin');
    expect(probe.part('note').text, '');
  });
  test('keeps wire names and referenced form signatures', () async {
    await client.uploadEscaped(photoMain: file(r'photo$main', [1], 'x.bin'), class2: 'tag');
    expect(probe.part(r'photo$main').bytes, [1]);
    expect(probe.part('class').text, 'tag');
    await client.uploadInline(photo: file('photo', [2], 'same.bin'), label: 'same', note: 'note');
    final before = probe.parts.map((p) => (p.name, p.filename, p.contentType, p.text)).toList();
    await client.uploadReferenced(photo: file('photo', [2], 'same.bin'), label: 'same', note: 'note');
    expect(probe.parts.map((p) => (p.name, p.filename, p.contentType, p.text)), before);
  });
  test('encodes URL forms and repeated fields', () async {
    await client.nativeForm(name: 'a & b+ café');
    expect(probe.headers['content-type'], startsWith('application/x-www-form-urlencoded'));
    expect(Uri.splitQueryString(utf8.decode(probe.bytes)), {'name': 'a & b+ café'});
    await client.formList(tags: ['a b', '&+']);
    expect(Uri(query: utf8.decode(probe.bytes)).queryParametersAll, {'tags': ['a b', '&+']});
  });
  test('omits nullable parts but retains empty files and strings', () async {
    await client.nullableParts(requiredText: null, requiredFile: null);
    expect(probe.parts, isEmpty);
    await client.nullableParts(requiredText: '', requiredFile: file('requiredFile', [], 'empty.bin'), optionalText: 'null', optionalFile: file('optionalFile', [255], 'one.bin'));
    expect(probe.parts, hasLength(4));
    expect(probe.part('requiredText').text, '');
    expect(probe.part('optionalText').text, 'null');
    expect(probe.part('requiredFile').bytes, isEmpty);
    expect(probe.part('optionalFile').bytes, [255]);
    await client.optionalEnums();
    expect(probe.parts, isEmpty);
    await client.optionalEnums(mode: api.ENUM_PREFIXMode.fromJson(''), code: api.ENUM_PREFIXCode.fromJson(2));
    expect(probe.part('mode').text, '');
    expect(probe.part('code').text, '2');
  });
  MODERN_TESTS
}

class Part {
  Part(this.name, this.filename, this.contentType, this.bytes);
  final String name;
  final String? filename;
  final String? contentType;
  final List<int> bytes;
  String get text => utf8.decode(bytes);
}

class Probe TRANSPORT_BASE {
  Map<String,String> headers = {};
  List<int> bytes = [];
  List<Part> parts = [];
  Part part(String name) => parts.singleWhere((p) => p.name == name);
  List<int> reply(Uri uri, Map<String,String> headers, List<int> bytes) {
    this.headers = {for (final e in headers.entries) e.key.toLowerCase(): e.value};
    this.bytes = bytes;
    parts = [];
    final contentType = this.headers['content-type'] ?? '';
    final boundary = RegExp(r'boundary="?([^";]+)').firstMatch(contentType)?.group(1);
    if (boundary != null) {
      for (final segment in latin1.decode(bytes).split('--$boundary').skip(1)) {
        if (segment.startsWith('--')) break;
        final data = segment.substring(2, segment.length - 2);
        final end = data.indexOf('\r\n\r\n');
        final head = data.substring(0, end);
        final body = data.substring(end + 4);
        final name = RegExp(r'(?:^|; )name="([^"]*)"').firstMatch(head)!.group(1)!;
        final filename = RegExp(r'; filename="([^"]*)"').firstMatch(head)?.group(1);
        final media = RegExp(r'content-type: ([^\r\n]+)', caseSensitive: false).firstMatch(head)?.group(1);
        parts.add(Part(name, filename, media, latin1.encode(body)));
      }
    }
    return uri.path == '/json' ? bytes : [];
  }
  TRANSPORT_SEND
}
'''
      .replaceAll('IMPORT/api.dart', '$folder/api.dart')
      .replaceAll('ENUM_PREFIX', old ? 'OptionalEnums' : 'OptionalEnumsRequest')
      .replaceAll(
        'MODERN_TESTS',
        old
            ? ''
            : '''
  test('retains file arrays and JSON object parts', () async {
    await client.uploadFiles(files: [file('files', [1], 'a.bin'), file('files', [], 'b.bin')], tags: ['a', 'b']);
    expect(probe.parts.where((p) => p.name == 'files').map((p) => p.filename), ['a.bin', 'b.bin']);
    expect(probe.parts.where((p) => p.name == 'tags').map((p) => p.text), ['a', 'b']);
    await client.uploadObjects(photo: file('photo', [0, 255], 'a.png'), metadata: api.Metadata.fromJson({'title': 'demo', 'details': {'count': 2}}), nested: [[1,2],[3]], inlineObject: api.UploadObjectsRequestInlineObject.fromJson({'code': 7}), external2: api.ExternalMetadata.fromJson({'source': 'remote'}));
    expect(probe.part('photo').bytes, [0, 255]);
    expect(probe.part('photo').contentType, 'image/png');
    expect(jsonDecode(probe.part('metadata').text), {'title': 'demo', 'details': {'count': 2}});
    expect(probe.parts.where((p) => p.name == 'nested').map((p) => jsonDecode(p.text)), [[1,2],[3]]);
    expect(jsonDecode(probe.part('inlineObject').text), {'code': 7});
    expect(jsonDecode(probe.part('external').text), {'source': 'remote'});
    final value = {'label': 'json', 'photo': 'binary-format text', 'note': 'same model'};
    expect(jsonDecode(jsonEncode(await client.echoUpload(body: api.Upload.fromJson(value)))), value);
    await client.uploadComposed(label: 'base', caption: 'derived');
    expect(probe.part('label').text, 'base');
    expect(probe.part('caption').text, 'derived');
  });
  test('omits null list entries and writes explicit JSON null parts', () async {
    await client.nullableLists(files: null, texts: null);
    expect(probe.parts, isEmpty);
    await client.nullableLists(files: [null, file('files', [], 'empty.bin'), null], texts: [null, '', 'x', null], csv: [null, 'a', null, 'b']);
    expect(probe.parts, hasLength(4));
    expect(probe.part('csv').text, 'a,b');
    expect(probe.part('files').filename, 'empty.bin');
    expect(probe.parts.where((p) => p.name == 'texts').map((p) => p.text), ['', 'x']);
    await client.jsonParts(requiredJson: null, values: null);
    expect(probe.parts.map((p) => (p.name, p.contentType?.split(';').first, p.text)), [
      ('requiredJson', 'application/json', 'null'),
      ('optionalJson', 'application/json', 'null'),
      ('values', 'application/json', 'null'),
    ]);
    await client.optionalJsonPart();
    expect(probe.part('value').text, 'null');
    await client.jsonParts(requiredJson: '', optionalJson: 'null', values: [null, 'a']);
    expect(probe.part('requiredJson').text, '""');
    expect(probe.part('optionalJson').text, '"null"');
    expect(probe.parts.where((p) => p.name == 'values').map((p) => p.text), ['null', '"a"']);
  });
  test('keeps raw multipart bodies and absent optional bodies', () async {
    for (final send in [client.rawEmpty, client.rawClosed, client.rawExternalEmpty, client.rawInlineEmpty]) {
      await send(body: raw());
      expect(probe.headers['content-type'], startsWith('multipart/form-data;'));
      expect(probe.parts, isEmpty);
    }
    await client.rawDynamic(body: raw({'count': '3'}));
    expect(probe.part('count').text, '3');
    await client.rawArray(body: raw({'entry': '{"value":1}'}));
    expect(jsonDecode(probe.part('entry').text), {'value': 1});
    await client.rawOptional();
    expect(probe.bytes, isEmpty);
    await client.optionalFields();
    expect(probe.bytes, isEmpty);
    await client.optionalFields(body: raw({'caption': 'present'}));
    expect(probe.part('caption').text, 'present');
    await client.noBody();
    expect(probe.bytes, isEmpty);
  });
''',
      )
      .replaceAll(
        'TRANSPORT_IMPORT',
        http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart' as dio;",
      )
      .replaceAll(
        'FILE_FACTORY',
        http
            ? 'http.MultipartFile file(String name, List<int> bytes, String filename) => http.MultipartFile.fromBytes(name, bytes, filename: filename);'
            : 'dio.MultipartFile file(String name, List<int> bytes, String filename) => dio.MultipartFile.fromBytes(bytes, filename: filename);',
      )
      .replaceAll(
        'RAW_FACTORY',
        old
            ? ''
            : http
            ? "http.MultipartRequest raw([Map<String,String> fields = const {}]) => http.MultipartRequest('POST', Uri.parse('https://unused.test'))..fields.addAll(fields);"
            : 'dio.FormData raw([Map<String,String> fields = const {}]) => dio.FormData()..fields.addAll(fields.entries);',
      )
      .replaceAll(
        'CREATE_CLIENT',
        http
            ? "addTearDown(probe.close); client = api.Api(probe, baseUrl: Uri.parse('https://example.test')).api;"
            : "final transport = dio.Dio(dio.BaseOptions(baseUrl:'https://example.test'))..httpClientAdapter = probe; addTearDown(() => transport.close(force: true)); client = api.Api(transport).api;",
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
    final bytes = await request.finalize().toBytes();
    final data = reply(request.url, request.headers, bytes);
    return http.StreamedResponse(Stream.value(data), request.url.path == '/json' ? 200 : 204, headers: {'content-type':'application/json'}, request: request);
  }
'''
            : '''
  @override
  Future<dio.ResponseBody> fetch(dio.RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final bytes = requestStream == null ? <int>[] : await requestStream.fold<List<int>>([], (all, chunk) => all..addAll(chunk));
    final data = reply(options.uri, options.headers.map((k,v) => MapEntry(k,v.toString())), bytes);
    return dio.ResponseBody.fromBytes(data, options.uri.path == '/json' ? 200 : 204, headers: {'content-type':['application/json']});
  }
  @override
  void close({bool force = false}) {}
''',
      );
}
