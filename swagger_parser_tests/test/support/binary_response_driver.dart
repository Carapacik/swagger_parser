import 'package:swagger_parser/swagger_parser.dart';

String binaryResponseDriver(
  String folder,
  String version,
  HttpClientBackend backend,
  ResponseMode mode, {
  required bool stream,
  required bool wrapped,
}) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  final type = stream ? 'Stream<List<int>>' : 'List<int>';
  String read(String method, String variant) => all
      ? '(await client.$method() as api.${variant}200).value'
      : wrapped
      ? '(await client.$method()).data${backend == HttpClientBackend.dio ? '!' : ''}'
      : '${stream ? '' : 'await '}client.$method()';
  return '''
import 'dart:async';
${all && version != 'v2' ? "import 'dart:convert';" : ''}
${http ? "import 'package:http/http.dart' as http;" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart' as dio;"}
import 'package:test/test.dart';
import '$folder/api.dart' as api;
import 'payloads.dart';

void main() {
  late Probe probe;
  late api.ApiClient client;
  setUp(() {
    probe = Probe();
    ${http ? "addTearDown(probe.close); client = api.Api(probe, baseUrl: Uri.parse('https://example.test')).api;" : "final transport = dio.Dio(dio.BaseOptions(baseUrl: 'https://example.test'))..httpClientAdapter = probe; addTearDown(() => transport.close(force: true)); client = api.Api(transport).api;"}
  });
  Future<$type> pdf() async => ${read('pdf', 'Pdf')};
  Future<$type> spreadsheet() async => ${read('spreadsheet', 'Spreadsheet')};
  Future<$type> bytes() async => ${read('bytes', 'Bytes')};
  Future<List<int>> drainPdf() async => ${stream ? '(await pdf()).expand((chunk) => chunk).toList()' : 'pdf()'};

  test('preserves PDF, spreadsheet, and arbitrary bytes', () async {
    for (final (name, read, media) in [
      ('pdf', pdf, 'application/pdf'),
      ('spreadsheet', spreadsheet, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
      ('bytes', bytes, 'application/octet-stream'),
    ]) {
      probe.bytes = payloads[name]!;
      final value = await read();
      expect(${stream ? 'await value.expand((chunk) => chunk).toList()' : 'value'}, payloads[name]);
      expect(probe.accept, contains(media));
    }
  });
  test('keeps an empty binary response distinct from a bodyless status', () async {
    probe.bytes = [];
    expect(await drainPdf(), isEmpty);
    ${all ? "probe.status = 204; expect(await client.pdf(), isA<api.Pdf204>());" : ''}
  });
  test('preserves byte order across non-UTF8 chunks', () async {
    final bytes = payloads['bytes']!;
    probe.source = Stream.fromIterable(bytes.map((b) => [b]));
    expect(await drainPdf(), bytes);
  });
  test('${stream ? 'emits bytes before completion and cancels upstream' : 'buffers bytes until the response completes'}', () async {
    final cancelled = Completer<void>();
    final source = StreamController<List<int>>(onCancel: cancelled.complete);
    probe.source = source.stream;
    ${stream ? '''
    final input = StreamIterator(await pdf());
    final next = input.moveNext();
    await probe.started.future.timeout(const Duration(seconds: 2));
    source.add([0, 255, 128]);
    expect(await next.timeout(const Duration(seconds: 2)), true);
    expect(input.current, [0, 255, 128]);
    await input.cancel();
    await cancelled.future.timeout(const Duration(seconds: 2));
    await source.close();
''' : '''
    var completed = false;
    final result = drainPdf().then((v) {completed = true; return v;});
    await probe.started.future.timeout(const Duration(seconds: 2));
    source.add([0, 255]);
    await Future<void>.delayed(Duration.zero);
    expect(completed, false);
    source.add([128, 1]);
    await source.close();
    expect(await result.timeout(const Duration(seconds: 2)), [0, 255, 128, 1]);
'''}
  });
  test('propagates a source failure after partial bytes', () async {
    final source = StreamController<List<int>>();
    probe.source = source.stream;
    final check = expectLater(drainPdf(), throwsA(anything));
    await probe.started.future.timeout(const Duration(seconds: 2));
    source.add([0, 255]);
    source.addError(StateError('Download failed.'));
    await source.close();
    await check;
  });
  test('keeps status and transport failures as errors', () async {
    probe.status = 503;
    await expectLater(drainPdf(), throwsA(${http ? 'isA<http.ClientException>()' : 'isA<dio.DioException>()'}));
    probe.status = 200;
    probe.fail = true;
    await expectLater(drainPdf(), throwsA(${http ? 'isA<http.ClientException>()' : 'isA<dio.DioException>()'}));
  });
  ${all && version != 'v2' ? '''
  test('decodes a JSON error beside a binary success response', () async {
    probe.status = 400;
    probe.bytes = utf8.encode('{"message":"missing"}');
    expect((await client.pdf() as api.Pdf400).value.message, 'missing');
  });
''' : ''}
  ${wrapped ? '''
  test('keeps original response metadata independent from buffering', () async {
    probe.bytes = payloads['pdf']!;
    final result = await client.pdf();
    final response = ${backend == HttpClientBackend.dio ? 'result' : 'result.response'};
    expect(response.statusCode, 200);
    expect(response.${http ? "headers['x-download']" : "headers.value('x-download')"}, 'report');
    expect(${stream ? "await result.data${backend == HttpClientBackend.dio ? '!' : ''}.expand((chunk) => chunk).toList()" : 'result.data'}, payloads['pdf']);
    ${http ? "expect(response, isA<http.${stream ? 'StreamedResponse' : 'Response'}>());" : ''}
    ${http && !stream ? "expect((response as http.Response).bodyBytes, payloads['pdf']);" : ''}
  });
''' : ''}
}

class Probe ${http ? 'extends http.BaseClient' : 'implements dio.HttpClientAdapter'} {
  List<int> bytes = [];
  Stream<List<int>>? source;
  int status = 200;
  bool fail = false;
  String accept = '';
  final started = Completer<void>();
  String media(Uri uri) => status == 400 ? 'application/json' : switch(uri.path) {
    '/pdf' => 'application/pdf',
    '/spreadsheet' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    _ => 'application/octet-stream',
  };
  ${http ? '''
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    await request.finalize().drain<void>();
    accept = request.headers['Accept'] ?? request.headers['accept'] ?? '';
    if (!started.isCompleted) started.complete();
    if (fail) throw http.ClientException('Network failed.', request.url);
    return http.StreamedResponse(source ?? Stream.value(bytes), status,
      headers: {'content-type': media(request.url), 'x-download': 'report'}, request: request);
  }
''' : '''
  @override
  Future<dio.ResponseBody> fetch(dio.RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancel) async {
    await requestStream?.drain<void>();
    accept = options.headers['Accept'].toString();
    if (!started.isCompleted) started.complete();
    if (fail) throw dio.DioException.connectionError(requestOptions: options, reason: 'Network failed.');
    return dio.ResponseBody((source ?? Stream.value(bytes)).map(Uint8List.fromList), status,
      headers: {'content-type': [media(options.uri)], 'x-download': ['report']});
  }
  @override
  void close({bool force = false}) {}
'''}
}
''';
}
