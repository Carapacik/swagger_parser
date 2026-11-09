import 'dart:async';
import 'dart:io';

Future<HttpServer> binaryServer(List<int> bytes) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  var started = Completer<void>();
  var released = Completer<void>();
  server.listen((request) async {
    final HttpResponse response = request.response;
    response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Headers', '*')
      ..set('Access-Control-Allow-Methods', 'GET, OPTIONS')
      ..set('Access-Control-Allow-Private-Network', 'true');
    try {
      if (request.method == 'OPTIONS') {
        response.statusCode = 204;
      } else {
        switch (request.uri.path) {
          case '/reset':
            started = Completer<void>();
            released = Completer<void>();
          case '/ready':
            await started.future.timeout(const Duration(seconds: 10));
          case '/release':
            released.complete();
          case '/pdf':
            final ready = started;
            final release = released;
            response.bufferOutput = false;
            response.headers
              ..contentType = ContentType.parse('application/pdf')
              ..set('X-Content-Type-Options', 'nosniff');
            final int middle = bytes.length ~/ 2;
            response.add(bytes.sublist(0, middle));
            await response.flush();
            ready.complete();
            await release.future.timeout(const Duration(seconds: 10));
            response.add(bytes.sublist(middle));
          default:
            response.statusCode = 404;
        }
      }
    } finally {
      await response.close();
    }
  });
  return server;
}

String binaryNetworkDriver(int port) =>
    '''
import 'dart:async';
import 'package:test/test.dart';
import 'package:dio/dio.dart' as dio;
import 'package:http/http.dart' as http;
import 'payloads.dart';
${[
      for (final backend in ['retrofit', 'dio', 'http'])
        for (final stream in [false, true]) "import 'v3_2_plain_${backend}_firstSuccess_${stream}_false/api.dart' as ${backend}_$stream;",
    ].join('\n')}

void main() {
  final base = Uri.parse('http://127.0.0.1:$port');
  late http.Client control;
  setUp(() async {
    control = http.Client();
    addTearDown(control.close);
    await control.get(base.resolve('/reset'));
  });
  ${[
      for (final backend in ['retrofit', 'dio', 'http'])
        for (final stream in [false, true]) '''
  test('$backend ${stream ? 'streams within its transport limits' : 'buffers the complete network body'}', () async {
    final transport = ${backend == 'http' ? 'http.Client()' : 'dio.Dio(dio.BaseOptions(baseUrl: base.toString()))'};
    addTearDown(transport.close);
    final client = ${backend}_$stream.Api(transport${backend == 'http' ? ', baseUrl: base' : ''}).api;
    var completed = false;
    ${stream ? '''
    final first = Completer<void>();
    final output = <int>[];
    final done = client.pdf().forEach((chunk) {
      output.addAll(chunk);
      if (!first.isCompleted) first.complete();
    }).then((_) => completed = true);
''' : '''
    final result = client.pdf().then((bytes) { completed = true; return bytes; });
'''}
    await control.get(base.resolve('/ready'));
    expect(completed, false);
    ${stream ? '''
    ${backend == 'http' ? '' : "if (!const bool.fromEnvironment('dart.library.js_interop')) {"}
      await first.future.timeout(const Duration(seconds: 3));
      expect(output, isNotEmpty);
      expect(output.length, lessThan(payloads['pdf']!.length));
    ${backend == 'http' ? '' : '}'}
''' : ''}
    await control.get(base.resolve('/release'));
    ${stream ? "await done.timeout(const Duration(seconds: 3)); expect(output, payloads['pdf']);" : "expect(await result.timeout(const Duration(seconds: 3)), payloads['pdf']);"}
  });
''',
    ].join('\n')}
}
''';
