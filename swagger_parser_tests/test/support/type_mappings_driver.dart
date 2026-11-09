import 'package:swagger_parser/swagger_parser.dart';

String typeMappingsDriver(
  String dir,
  String version,
  DtoSerializer serializer,
  HttpClientBackend backend, {
  bool allStatuses = false,
}) {
  final http = backend == HttpClientBackend.http;
  String call(String method, String args, String result) {
    final expression = 'await api.api.$method($args)';
    return allStatuses ? '(($expression) as ${result}200).value' : expression;
  }

  return '''
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import '$dir/api.dart';

void rejects(void Function() read) {
  try { read(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

final wire = <String,Object?>{
  'id':'north', 'wireId':'wire:east', 'count':2, 'ratio':1.5, 'enabled':true,
  'aliases':['west','east'], 'byName':{'main':'north'}, 'date':'2026-11-07',
};
Future<void> main() async {
  final dto = Station.fromJson(wire);
  assert(dto.id.value == 'north');
  assert(dto.wireId.value == 'east');
  assert(Tagged().kind.value == 'stop');
  assert(Tagged.fromJson({'kind':'stop'}).toJson()['kind'] == 'stop');
  ${version != '2_0' ? "assert(AnyChoice.fromJson('north').toJson() == 'north');" : ''}
  ${version == '3_1' || version == '3_2' ? "assert(Pair.fromJson(['north',2]).item1.value == 'north');" : ''}
  assert(dto.count.value == 2 && dto.ratio.value == 1.5 && dto.enabled.value);
  assert(dto.aliases.first.value == 'west');
  assert(dto.byName['main']!.value == 'north');
  assert(dto.date.value == '2026-11-07');
  assert(dto.toJson().length == wire.length);
  for (final key in wire.keys) assert(jsonEncode(dto.toJson()[key]) == jsonEncode(wire[key]));
  assert(!dto.toJson().containsKey('note'));
  final cleared = Station.fromJson({...wire,'note':null});
  assert(cleared.note != null && cleared.note!.value == null);
  assert(cleared.toJson().containsKey('note') && cleared.toJson()['note'] == null);
  final changed = Station.fromJson({...wire,'note':'south'});
  assert(changed.note!.value!.value == 'south');
  assert(changed.toJson()['note'] == 'south');
  rejects(() => Station.fromJson({...wire,'id':12}));
  rejects(() => Station.fromJson({...wire,'id':''}));
  rejects(() => Station.fromJson({...wire,'count':1.5}));
  rejects(() => Station.fromJson({...wire,'enabled':'true'}));
  rejects(() => Station.fromJson({...wire,'optionalId':null}));
  ${serializer == DtoSerializer.freezed || serializer == DtoSerializer.dartMappable ? "assert(dto.copyWith(id: const StationId('south')).id.value == 'south');" : ''}
  ${version != '2_0' ? "assert(Choice.fromJson('north').toJson() == 'north'); assert(Choice.fromJson(2).toJson() == 2); rejects(() => Choice.fromJson(true));" : ''}
  final calls = <Uri>[];
  Object? reply(Uri uri, Map<String,String> headers, String? body) {
    calls.add(uri);
    if (uri.path == '/stations/north') {
      assert(headers['X-Station'] == 'north' || headers['x-station'] == 'north');
      assert(uri.query.contains('ids=west'));
      assert(!uri.query.contains('Instance'));
      return wire;
    }
    if (uri.path == '/id') { assert(jsonDecode(body!) == 'north'); return 'south'; }
    if (uri.path == '/ticket') return {'id':'north'};
    if (uri.path == '/form') { assert(body == 'code=north'); return 'south'; }
    if (uri.path == '/multipart') { final text = body!; assert(text.contains('name="code"')); assert(text.contains('north')); assert(!text.contains('Instance')); return 'south'; }
    if (uri.path == '/text') { assert(body == 'north'); return 'south'; }
    throw StateError('Unexpected URL: \$uri');
  }
  ${http ? "final transport = MockClient((request) async => http.Response(request.url.path == '/text' ? reply(request.url, request.headers, request.body)! as String : jsonEncode(reply(request.url, request.headers, request.body)),200,headers:{'content-type':request.url.path == '/text' ? 'text/plain' : 'application/json'})); final api = Api(transport, baseUrl: Uri.parse('https://example.test'));" : "final transport = Dio(BaseOptions(baseUrl:'https://example.test')); transport.httpClientAdapter = Adapter(reply); final api = Api(transport);"}
  final result = ${call("getStation", "id: const ExternalId('north'), xStation: const ExternalId('north'), ids: [const ExternalId('west'), const ExternalId('east')]", "GetStation")};
  assert(result.id.value == 'north');
  final StationId id = ${call("echoId", "body: const StationId('north')", "EchoId")};
  assert(id.value == 'south');
  final ticket = ${call("getTicket", "", "GetTicket")};
  assert(ticket.id.value == 'north');
  assert((${call("sendForm", "code: const ExternalId('north')", "SendForm")}).value == 'south');
  assert((${call("sendMultipart", "code: const ExternalId('north')", "SendMultipart")}).value == 'south');
  assert((${call("echoText", "body: const StationId('north')", "EchoText")}).value == 'south');
  assert(calls.length == 6);
  transport.${http ? 'close()' : 'close(force: true)'};
}
${http ? '' : '''
class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final Object? Function(Uri,Map<String,String>,String?) reply;
  @override Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    final body = stream == null ? null : utf8.decode(await stream.expand((b)=>b).toList());
    final data = reply(options.uri,options.headers.map((k,v)=>MapEntry(k,v.toString())),body);
    return ResponseBody.fromString(options.uri.path == '/text' ? data! as String : jsonEncode(data),200,headers:{'content-type':[options.uri.path == '/text' ? 'text/plain' : 'application/json']});
  }
  @override void close({bool force = false}) {}
}
'''}
''';
}
