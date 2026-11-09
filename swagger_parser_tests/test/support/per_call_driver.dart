import 'package:swagger_parser/swagger_parser.dart';

/// Tests request settings and cancellation against a local server.
String perCallDriver(
  String folder,
  HttpClientBackend backend,
  ResponseMode mode,
) {
  final http = backend == HttpClientBackend.http;
  final all = mode == ResponseMode.allStatuses;
  String value(String expression, String operation) => all
      ? '((await $expression) as api.${operation}200).value'
      : '(await $expression)';
  final cancelArg = http ? 'abortTrigger: stop.future' : 'cancelToken: stop';
  final stop = http ? 'Completer<void>()' : 'CancelToken()';
  final abort = http ? 'stop.complete()' : "stop.cancel('Test cancelled')";
  final error = http
      ? 'isA<http.RequestAbortedException>()'
      : 'isA<DioException>().having((e) => e.type, "type", DioExceptionType.cancel)';
  final options = http
      ? "const api.HttpRequestOptions(headers: {'X-Call': 'yes', 'Content-Type': 'text/plain'}, followRedirects: false, maxRedirects: 2)"
      : "Options(headers: {'X-Call': 'yes', 'Content-Type': 'text/plain'}, connectTimeout: const Duration(seconds: 3), sendTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 5), followRedirects: false, maxRedirects: 2, extra: {'option': true})";
  return '''
import 'dart:async';
import 'dart:io';
import 'package:test/test.dart';
${http ? "import 'package:http/http.dart' as http;" : "import 'package:dio/dio.dart';"}
import '$folder/api.dart' as api;

void main() {
  late HttpServer server;
  late api.Api root;
  late ${http ? 'http.Client' : 'Dio'} transport;
  late Map<String, Object?> metadata;
  late HttpRequest received;
  late Completer<void> arrived;
  late Completer<void> release;
  ${http ? '' : 'late RequestOptions sent;'}

  setUp(() async {
    arrived = Completer<void>();
    release = Completer<void>();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://127.0.0.1:\${server.port}';
    server.listen((request) async {
      received = request;
      if (request.uri.path.endsWith('/wait')) {
        if (!arrived.isCompleted) arrived.complete();
        await release.future;
      }
      if (const ['/events', '/binary', '/lines'].contains(request.uri.path)) {
        request.response.bufferOutput = false;
        request.response.headers.contentType = ContentType.parse(switch(request.uri.path) {
          '/events' => 'text/event-stream',
          '/lines' => 'application/jsonl',
          _ => 'application/octet-stream',
        });
        request.response.write(switch(request.uri.path) {
          '/events' => 'data: first\\n\\n',
          '/lines' => '{"name":"first"}\\n',
          _ => 'first',
        });
        await request.response.flush();
        await release.future;
      } else {
        if (request.uri.path.endsWith('/accepted')) request.response.statusCode = 202;
        await request.drain<void>();
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"name":"North"}');
      }
      await request.response.close();
    });
    ${http ? '''
    transport = http.Client();
    root = api.Api(transport, baseUrl: Uri.parse(base), prepareRequest: (request, extra) {
      metadata = extra;
      if (request.headers['x-call'] == 'yes') {
        expect(request.followRedirects, false);
        expect(request.maxRedirects, 2);
      }
    });
    ''' : '''
    transport = Dio(BaseOptions(baseUrl: base, headers: {'X-Base': 'base'}, receiveTimeout: const Duration(seconds: 8), extra: {'base': true}));
    transport.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      sent = request;
      metadata = request.extra;
      handler.next(request);
    }));
    root = api.Api(transport);
    '''}
  });
  tearDown(() async {
    if (!release.isCompleted) release.complete();
    transport.${http ? 'close()' : 'close(force: true)'};
    await server.close(force: true);
  });

  test('keeps defaults and replaces generated metadata', () async {
    await root.api.getStation(id: '42');
    expect(metadata['openapi.servers'], isNotEmpty);
    final station = ${value("root.api.getStation(id: '42', extra: {'screen': 'details'})", 'GetStation')};
    expect(station.name, 'North');
    expect(metadata['screen'], 'details');
    expect(metadata.containsKey('openapi.servers'), false);
    expect(received.headers.value('screen'), isNull);
    ${http ? '' : "expect(sent.receiveTimeout, const Duration(seconds: 8)); expect(metadata['base'], true);"}
  });

  test('applies options without changing typed decoding', () async {
    final options = $options;
    final station = ${value("root.api.getStation(id: '42', options: options, extra: {'screen': 'details'})", 'GetStation')};
    expect(station.name, 'North');
    expect(received.headers.value('x-call'), 'yes');
    expect(metadata['screen'], 'details');
    ${http ? '' : '''
    expect(sent.connectTimeout, const Duration(seconds: 3));
    expect(sent.sendTimeout, const Duration(seconds: 4));
    expect(sent.receiveTimeout, const Duration(seconds: 5));
    expect(sent.followRedirects, false);
    expect(sent.maxRedirects, 2);
    expect(metadata['option'], true);
    expect(metadata['base'], true);
    expect(options.extra, {'option': true});
    expect(options.headers, {'X-Call': 'yes', 'Content-Type': 'text/plain'});
    expect(received.headers.value('x-base'), 'base');
    '''}
    await root.api.echo(body: const api.Station(name: 'Sent'), options: options);
    await root.api.submitForm(name: 'Sent', options: options);
    await root.api.upload(file: ${http ? "http.MultipartFile.fromString('file', 'bytes')" : "MultipartFile.fromString('bytes')"}, options: options);
    expect(received.headers.contentType?.mimeType, 'multipart/form-data');
    await root.api.collisions(options2: 'option', extra2: 'metadata', cancelToken2: 'cancel', abortTrigger2: 'abort', options: options);
    expect(received.uri.queryParameters, {'options': 'option', 'extra': 'metadata', 'cancelToken': 'cancel', 'abortTrigger': 'abort'});
  });

  ${backend == HttpClientBackend.retrofit && !all ? """
  test('keeps Retrofit path, list, and status behavior with options', () async {
    transport.options.listFormat = ListFormat.csv;
    await root.api.getStation(id: 'north%2Fwest', tag: ['a', 'b']);
    final uri = received.uri;
    await root.api.getStation(id: 'north%2Fwest', tag: ['a', 'b'], options: Options());
    expect(received.uri, uri);
    transport.options.validateStatus = (status) => status == 202;
    expect((await root.api.getStation(id: 'accepted', options: Options())).name, 'North');
  });
  """ : ''}

  for (final withOptions in [false, true]) {
    test('cancels before send with options=\$withOptions', () async {
      final stop = $stop;
      $abort;
      await expectLater(root.api.getStation(id: '42', $cancelArg, options: withOptions ? $options : null), throwsA($error));
      await expectLater(root.api.echo(body: const api.Station(name: 'Sent'), $cancelArg, options: withOptions ? $options : null), throwsA($error));
      await expectLater(root.api.submitForm(name: 'Sent', $cancelArg, options: withOptions ? $options : null), throwsA($error));
      await expectLater(root.api.upload(file: ${http ? "http.MultipartFile.fromString('file', 'bytes')" : "MultipartFile.fromString('bytes')"}, $cancelArg, options: withOptions ? $options : null), throwsA($error));
      expect(${value("root.api.getStation(id: 'other')", 'GetStation')}.name, 'North');
    });
    test('cancels an active call with options=\$withOptions', () async {
      final stop = $stop;
      final call = root.api.getStation(id: 'wait', $cancelArg, options: withOptions ? $options : null);
      final check = expectLater(call, throwsA($error));
      await arrived.future;
      $abort;
      await check;
      expect(${value("root.api.getStation(id: 'other')", 'GetStation')}.name, 'North');
    });
  }

  ${http ? '' : """
  test('applies the receive timeout to an active call', () async {
    await expectLater(root.api.getStation(id: 'wait', options: Options(receiveTimeout: const Duration(milliseconds: 30))),
      throwsA(isA<DioException>().having((e) => e.type, 'type', DioExceptionType.receiveTimeout)));
  });
  """}

  test('subscription cancellation keeps the caller signal usable', () async {
    final stop = $stop;
    final Stream<Object?> stream = ${value('root.api.download($cancelArg)', 'Download')};
    final first = Completer<void>();
    final subscription = stream.listen((_) { if (!first.isCompleted) first.complete(); });
    await first.future;
    await subscription.cancel();
    expect(${http ? 'stop.isCompleted' : 'stop.isCancelled'}, false);
    expect(${value("root.api.getStation(id: 'other', $cancelArg)", 'GetStation')}.name, 'North');
  });

  for (final method in ['events', 'download', 'records']) {
    test('cancels a \$method response stream', () async {
      final stop = $stop;
      final Stream<Object?> stream = switch(method) {
        'events' => ${value('root.api.events($cancelArg)', 'Events')},
        'download' => ${value('root.api.download($cancelArg)', 'Download')},
        _ => ${value('root.api.records($cancelArg)', 'Records')},
      };
      final first = Completer<void>();
      final failed = Completer<Object>();
      final subscription = stream.listen((_) {
        if (!first.isCompleted) first.complete();
      }, onError: (Object error) { if (!failed.isCompleted) failed.complete(error); });
      await first.future;
      $abort;
      expect(await failed.future, $error);
      await subscription.cancel();
    });
  }
}
''';
}
