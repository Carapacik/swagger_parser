/// Runs the shared HTTP wire checks in a generated client package.
const httpTransportDriver = r"""
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:client_check/http_firstSuccess/api.dart' as http;
import 'package:client_check/http_firstSuccess/api.dart';
import 'package:client_check/http_allStatuses/api.dart' as all;
import 'package:client_check/swagger_forms_firstSuccess/api.dart' as swagger;

class Probe implements HttpClientAdapter {
  late RequestOptions request;
  late List<int> sent;
  late ResponseBody Function() reply;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    request = options;
    sent = await stream?.expand((part) => part).toList() ?? [];
    return reply();
  }

  @override
  void close({bool force = false}) {}
}

Future<void> main() async {
  final probe = Probe();
  final dio = Dio(BaseOptions(baseUrl: 'https://caller.example'))..httpClientAdapter = probe;
  final client = http.ApiClient(dio);
  final statuses = all.ApiClient(dio);
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    final servers = options.extra['openapi.servers'] as List?;
    if (servers != null && servers.isNotEmpty) options.baseUrl = servers.first['url'] as String;
    final security = options.extra['openapi.security'] as List?;
    if (security != null && security.any((item) => item.containsKey('token') as bool)) {
      final schemes = options.extra['openapi.securitySchemes'] as Map;
      options.headers[schemes['token']['name'] as String] = 'test-key';
    }
    handler.next(options);
  }));
  probe.reply = () => ResponseBody.fromString('{"term":"north"}', 200,
    headers: {'content-type': ['application/json']});
  final result = await client.search(body: const http.Search(term: 'south'));
  assert(result.term == 'north');
  assert(probe.request.method == 'QUERY' && probe.request.uri.host == 'search.example');
  assert(probe.request.headers['X-Token'] == null && jsonDecode(utf8.decode(probe.sent))['term'] == 'south');
  final query = await statuses.search(body: const all.Search(term: 'east'));
  assert(query is all.Search200 && query.value.term == 'north' && probe.request.method == 'QUERY');

  probe.reply = () => ResponseBody.fromString('', 204);
  await client.ping();
  assert(probe.request.method == 'HEAD' && probe.request.uri.host == 'stations.example');
  assert(probe.request.headers['X-Token'] == 'test-key');
  await client.capabilities(extra: {});
  assert(probe.request.method == 'OPTIONS' && probe.request.uri.host == 'caller.example');
  await client.traceCall();
  assert(probe.request.method == 'TRACE');
  await client.filter(area: {'north': 2}, location: {'name': 'east'}, session: 'abc def');
  assert(probe.request.uri.queryParameters['area'] == 'north|2');
  assert(probe.request.uri.queryParameters['location'] == 'name east');
  assert(probe.request.headers['Cookie'] == 'session=abc%20def');
  await FiltersClient(dio).combined(first: {'name':'a/b'}, second: {'count':3});
  assert(probe.request.uri.query.contains('first=name,a/b'));
  assert(probe.request.uri.queryParameters['second[count]'] == '3');
  await client.readParameters(term: 'west:gate', source: '/a?b%20c&cat', detail: const http.Search(term: 'abc'), flags: ['a%20b', 'c'], mode: http.ReadParametersMode.byId);
  assert(probe.request.uri.path == '/parameters/west:gate');
  assert(probe.request.uri.query.contains('source=/a?b%20c%26cat'));
  assert(jsonDecode(probe.request.uri.queryParameters['detail']!)['term'] == 'abc');
  assert(probe.request.headers['Cookie'] == 'flags=a%20b; flags=c');
  assert(probe.request.headers['mode'] == 'by-id');
  await client.encodedQuery(filter: const http.EncodedQueryFilter(term: 'd & e'));
  assert(probe.request.uri.queryParameters['term'] == 'd & e');
  await client.rawQuery(filter: 'tag=a%26b&tag=c');
  assert(probe.request.uri.queryParametersAll['tag']!.join('|') == 'a&b|c');
  await client.sendForm(station: 'a & b', tags: ['one', 'two']);
  final encoded = Uri.parse('?${utf8.decode(probe.sent)}').queryParametersAll;
  assert(encoded['station']!.single == 'a & b' && encoded['tags']!.join('|') == 'one|two');
  final old = swagger.ApiClient(dio);
  await old.sendForm(station: 'a', tags: ['one', 'two']);
  assert(Uri.splitQueryString(utf8.decode(probe.sent))['tags'] == 'one|two');
  MultipartFile photo() => MultipartFile.fromBytes([0, 255, 13, 10], filename: 'photo.bin', headers: {'X-Source':['station']});
  await client.upload(photo: photo(), label: 'north');
  final multipart = latin1.decode(probe.sent).toLowerCase();
  assert(probe.request.contentType!.startsWith('multipart/form-data; boundary='));
  for (final token in ['name="photo"', 'filename="photo.bin"', 'image/png', 'x-source: station', 'name="label"', 'north', '\x00\xff\r\n']) {
    assert(multipart.contains(token), token);
  }
  await old.upload(photo: photo());
  assert(latin1.decode(probe.sent).contains('photo.bin'));

  probe.reply = () => ResponseBody.fromString('[1,2]', 200, headers: {'content-type':['application/json']});
  assert((await client.report()).join(',') == '1,2' && probe.request.method == 'Report');
  probe.reply = () => ResponseBody.fromBytes([0, 255], 200);
  assert((await client.echoBytes(body: [255, 0]).expand((chunk) => chunk).toList()).join(',') == '0,255' && probe.sent.join(',') == '255,0');

  final records = utf8.encode('{"term":"café"}\r\n{"term":"east"}');
  probe.reply = () => ResponseBody(Stream.fromIterable(records.map((b) => Uint8List.fromList([b]))), 200);
  // ignore: deprecated_member_use
  assert((await client.records().map((r) => r.term).join('|')) == 'café|east');
  // ignore: deprecated_member_use
  final sequence = await statuses.records() as all.Records200;
  assert((await sequence.value.first).term == 'café');
  probe.reply = () => ResponseBody.fromString('', 200);
  // ignore: deprecated_member_use
  assert(await client.records().isEmpty);
  probe.reply = () => ResponseBody.fromString('{', 200);
  try {
    // ignore: deprecated_member_use
    await client.records().drain<void>();
    throw StateError('Expected invalid JSON.');
  } on FormatException { }
  final download = StreamController<Uint8List>();
  final stopped = Completer<void>();
  download.onCancel = stopped.complete;
  probe.reply = () => ResponseBody(download.stream, 200);
  download.add(Uint8List.fromList([3]));
  assert((await client.echoBytes(body: []).first).single == 3);
  await stopped.future.timeout(const Duration(seconds: 3));
  await download.close();

  final source = utf8.encode(': keepalive\r\nid: 7\r\nretry: 25\r\nevent: station\r\ndata: café\r\ndata: west\r\n\r\ndata: next\n\ndata: incomplete');
  probe.reply = () => ResponseBody(Stream.fromIterable(source.map((b) => Uint8List.fromList([b]))), 200);
  final events = await client.events().toList();
  assert(events.length == 2 && events.first.data == 'café\nwest');
  assert(events.first.event == 'station' && events.first.retry == 25 && events.last.id == '7' && events.last.event == 'message');
  final streamed = await statuses.events() as all.Events200;
  assert((await streamed.value.first).data == 'café\nwest');
  final cancelled = Completer<void>();
  final chunks = StreamController<Uint8List>(onCancel: cancelled.complete);
  probe.reply = () => ResponseBody(chunks.stream, 200);
  chunks.add(Uint8List.fromList(utf8.encode('data: ready\n\n')));
  assert((await client.events().first).data == 'ready');
  await cancelled.future.timeout(const Duration(seconds: 3));
  await chunks.close();
  probe.reply = () => ResponseBody.fromString('{"term":"missing"}', 404);
  final missing = await statuses.events() as all.Events404;
  assert(missing.value.term == 'missing');
  probe.reply = () => ResponseBody.fromString('', 503);
  assert(await statuses.events() is all.Events503);
  dio.close();

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final network = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:${server.port}'));
  final received = server.first.then((request) async {
    final data = jsonDecode(await utf8.decoder.bind(request).join());
    assert(request.method == 'QUERY' && request.uri.path == '/search');
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(data));
    await request.response.close();
  });
  try {
    final result = await http.ApiClient(network).search(body: const http.Search(term: 'wire'));
    assert(result.term == 'wire');
    await received;
  } finally {
    network.close(force: true);
    await server.close(force: true);
  }
}
""";
