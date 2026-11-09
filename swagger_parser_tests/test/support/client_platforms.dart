import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'client_consumer.dart';
import 'test_platforms.dart';

/// Sends forms and reads streams with the generated client on VM and Chrome.
Future<void> checkClientPlatforms(
  ClientConsumer consumer, {
  required bool http,
}) async {
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    0,
  );
  var release = Completer<void>();
  server.listen((request) async {
    final HttpResponse res = request.response;
    res.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS')
      ..set('Access-Control-Allow-Headers', '*')
      ..set('Access-Control-Allow-Private-Network', 'true');
    try {
      if (request.method == 'OPTIONS') {
        res.statusCode = 204;
      } else {
        final List<int> bytes = await request.expand((chunk) => chunk).toList();
        switch (request.uri.path) {
          case '/photos':
            final String parts = latin1.decode(bytes);
            if (request.headers.contentType?.mimeType !=
                    'multipart/form-data' ||
                !parts.contains('name="photo"; filename="photo.bin"') ||
                !parts.contains('\x00\xff') ||
                !parts.contains('north')) {
              throw StateError('Invalid multipart body.');
            }
            if (parts.contains('custom-north') &&
                !(parts.toLowerCase().contains('content-type: image/png') &&
                    parts.toLowerCase().contains('x-source: station'))) {
              throw StateError('Invalid part metadata.');
            }
            res.statusCode = 204;
          case '/form':
            final Map<String, List<String>> query = Uri.parse(
              '?${utf8.decode(bytes)}',
            ).queryParametersAll;
            if (request.headers.contentType?.mimeType !=
                    'application/x-www-form-urlencoded' ||
                query['station']?.single != 'a & b' ||
                query['tags']?.join('|') != 'first|second') {
              throw StateError('Invalid form body.');
            }
            res.statusCode = 204;
          case '/ack':
            release.complete();
            res.statusCode = 204;
          case '/progress/records':
            res.bufferOutput = false;
            res.headers
              ..contentType = ContentType.parse('application/x-ndjson')
              ..set('X-Content-Type-Options', 'nosniff');
            res.write('{"term":"first"}\n');
            await res.flush();
            await release.future.timeout(const Duration(seconds: 8));
            release = Completer<void>();
            res.write('{"term":"last"}\n');
          case '/records':
            res.headers.contentType = ContentType.parse('application/x-ndjson');
            res.add(utf8.encode('{"term":"café"}\n{"term":"south"}\n'));
          case '/bytes':
            res.add(bytes);
          default:
            res.statusCode = 404;
        }
      }
    } on Object catch (error) {
      res
        ..statusCode = 500
        ..write(error);
    } finally {
      await res.close();
    }
  });
  const dioUpload = """
    final custom = MultipartFile.fromBytes([0, 255], filename: 'photo.bin', headers: {'X-Source': ['station']});
    await client.upload(photo: custom, label: 'custom-north');
""";
  const nativeChecks = """
    final progress = api.ApiClient(transport, baseUrl: url.resolve('/progress'));
    final names = <String>[];
    // ignore: deprecated_member_use
    await for (final station in progress.records()) {
      names.add(station.term);
      if (names.length == 1) {
        await transport.get(url.resolve('/ack'));
      }
    }
    expect(names, ['first', 'last']);
""";
  try {
    await consumer.write('test/platform_test.dart', """
import 'package:test/test.dart';
import 'package:${http ? 'http/http' : 'dio/dio'}.dart';
import 'package:client_check/http_firstSuccess/api.dart' as api;
import 'package:client_check/swagger_forms_firstSuccess/api.dart' as forms;
void main() {
  test('sends forms and reads response streams', () async {
    final url = Uri.parse('http://127.0.0.1:${server.port}');
    final transport = ${http ? 'Client()' : 'Dio(BaseOptions(baseUrl: url.toString()))'};
    addTearDown(transport.close);
    final client = api.ApiClient(transport${http ? ', baseUrl: url' : ''});
    final uploads = forms.ApiClient(transport${http ? ', baseUrl: url' : ''});
    final photo = MultipartFile.fromBytes(${http ? "'photo', " : ''}[0, 255], filename: 'photo.bin');
    await uploads.upload(photo: photo, label: 'north');
    ${http ? '' : dioUpload}
    await client.sendForm(station: 'a & b', tags: ['first', 'second']);
    expect(await client.echoBytes(body: [1, 255]).expand((b) => b).toList(), [1, 255]);
    // ignore: deprecated_member_use
    expect(await client.records().map((r) => r.term).toList(), ['café', 'south']);
    ${http ? nativeChecks : ''}
  });
}
""");
    await consumer.dart([
      'test',
      '--concurrency=1',
      '-p',
      if (runChromeTests) 'vm,chrome' else 'vm',
      'test/platform_test.dart',
    ]);
  } finally {
    await server.close(force: true);
  }
}
