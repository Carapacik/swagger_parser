import 'package:swagger_parser/swagger_parser.dart';

String directionDriver(HttpClientBackend backend, String dir, String keywords) {
  final http = backend == HttpClientBackend.http;
  final setup = http
      ? '''
  final api = Api(MockClient((req) async {
    if (req.url.path == '/original') return http.Response('{"marker":"M"}', 200);
    if (req.url.path == '/reserved/Dio') {
      assert(req.url.queryParameters['class'] == 'C' && req.url.queryParameters['http'] == 'H');
      return http.Response(jsonEncode(protected.toJson()), 200);
    }
    sent.add(jsonDecode(req.body) as Map<String,Object?>);
    return http.Response(jsonEncode(wire), 200, headers:{'content-type':'application/json'});
  }), baseUrl: Uri.parse('https://station.test'));
'''
      : '''
  final transport = dio.Dio(dio.BaseOptions(baseUrl:'https://station.test'));
  transport.interceptors.add(dio.InterceptorsWrapper(onRequest:(opts,handler) {
    if (opts.uri.path == '/original') {
      handler.resolve(dio.Response(requestOptions:opts, statusCode:200, data:{'marker':'M'}));
      return;
    }
    if (opts.uri.path == '/reserved/Dio') {
      assert(opts.uri.queryParameters['class'] == 'C' && opts.uri.queryParameters['http'] == 'H');
      handler.resolve(dio.Response(requestOptions:opts, statusCode:200, data:protected.toJson()));
      return;
    }
    sent.add((opts.data is String ? jsonDecode(opts.data as String) : opts.data) as Map<String,Object?>);
    handler.resolve(dio.Response(requestOptions:opts, statusCode:200, data:wire));
  }));
  final api = Api(transport);
''';
  return <String>[
    '''
import 'dart:convert';
import '$dir/api.dart';
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'package:dio/dio.dart' as dio;"}
''',
    r'''
void rejects(void Function() run) {
  try { run(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}
Future<void> main() async {
  final request = Station$Request.fromJson({
    'name':'North', 'access_code':'secret', 'id':'drop',
    'profile':{'label':'P', 'server_stamp':1},
    'children':[{'name':'Child', 'access_code':'child', 'id':'drop'}],
  });
  final encoded = request.toJson();
  assert(!encoded.containsKey('id') && encoded['access_code'] == 'secret');
  assert(!(encoded['profile'] as Map).containsKey('server_stamp'));
  assert(!((encoded['children'] as List).single as Map).containsKey('id'));
  const wire = <String,Object?>{'id':'s','name':'North','access_code':'drop','profile':{'label':'P','server_stamp':1}};
  final response = Station$Response.fromJson(wire);
  assert(response.id == 's' && response.profile!.serverStamp == 1);
  assert(!response.toJson().containsKey('access_code'));
  final extras = Station$Response(id:'s', name:'N', additionalProperties:{'access_code':'drop','extra':42}).toJson();
  assert(!extras.containsKey('access_code') && extras['extra'] == 42);
  rejects(() => Station$Request.fromJson({'name':'N'}));
  rejects(() => Station$Response.fromJson({'name':'N'}));
  assert(Shared.fromJson({'value':'x'}).value == 'x');
  assert(StationRequest.fromJson({'marker':'M'}).marker == 'M');
  assert(StationRequest2.fromJson({'literal':'L'}).literal == 'L');
  final envelope = Envelope$Request.fromJson({'station':request.toJson(),'untouched':{'marker':'M'}});
  assert(envelope.station.accessCode == 'secret' && envelope.untouched.marker == 'M');
  final catalog = Catalog$Response.fromJson([wire]);
  assert(catalog.value.single.id == 's');
  assert(!((catalog.toJson() as List).single as Map).containsKey('access_code'));
  assert(Index$Request.fromJson({'one':request.toJson()}).value['one']!.accessCode == 'secret');
  assert(StationAlias$Response.fromJson(wire).value.id == 's');
  assert(Composed$Request.fromJson({'name':'N'}).name == 'N');
  assert(Composed$Response.fromJson({'name':'N','id':'s'}).id == 's');
  assert(Referenced$Request.fromJson({'name':'N'}).name == 'N');
  assert(Referenced$Response.fromJson({'name':'N','id':'s'}).id.value == 's');
  assert(!Closed$Request.fromJson({'id':'drop','name':'N'}).toJson().containsKey('id'));
  rejects(() => Closed$Request.fromJson({'other':'bad','name':'N'}));
  for (final value in [Animal$Request.fromJson({'kind':'cat','secret':'s','id':'drop'}).toJson(),
      Choice$Request.fromJson({'kind':'cat','secret':'s','id':'drop'}).toJson(),
      Views$Request.fromJson({'kind':'cat','secret':'s','id':'drop'}).toJson()]) {
    assert(!(value as Map).containsKey('id') && value['secret'] == 's');
  }
  for (final value in [Animal$Response.fromJson({'kind':'cat','id':'s','secret':'drop'}).toJson(),
      Choice$Response.fromJson({'kind':'cat','id':'s','secret':'drop'}).toJson(),
      Views$Response.fromJson({'kind':'cat','id':'s','secret':'drop'}).toJson()]) {
    assert(!(value as Map).containsKey('secret') && value['id'] == 's');
  }
  final slot = Slot$Response.fromJson([wire]);
  final route = Route$Request.fromJson({'rail':'R'});
  assert(!(route.toJson() as Map).containsKey('kind'));
  assert(Route$Response.fromJson({'kind':'bus','bus':'B'}).toJson()['kind'] == 'bus');
  assert(slot.item1.id == 's' && !(slot.toJson().single as Map).containsKey('access_code'));
  final protected = Dio2.fromJson({'class':'C','fromJson':'J','new':'N','data':'D'});
  assert(protected.class2 == 'C' && protected.fromJson2 == 'J' && protected.new2 == 'N');
  assert(protected.toJson()['class'] == 'C');
  assert(Options2.fromJson({'value':'o'}).value == 'o');
  assert(Future2.fromJson({'value':'f'}).value == 'f');
  assert(RestApi2.fromJson({'value':'r'}).value == 'r');
  final sent = <Map<String,Object?>>[];
''',
    '''
  final keywordWire = <String,Object?>$keywords;
  final words = ReservedWords.fromJson(keywordWire);
  assert(jsonEncode(words.toJson()) == jsonEncode(keywordWire));
''',
    setup,
    r'''
  for (final patch in [Station$Request(name:'N', accessCode:'s'),
    Station$Request(name:'N', accessCode:'s', note:(value:null)),
    Station$Request(name:'N', accessCode:'s', note:(value:'changed'))]) {
    final Station$Response result = await api.stations.saveStation(body:patch);
    assert(result.id == 's' && !result.toJson().containsKey('access_code'));
  }
  assert(!sent[0].containsKey('note'));
  assert(sent[1].containsKey('note') && sent[1]['note'] == null);
  assert(sent[2]['note'] == 'changed' && sent.every((json) => !json.containsKey('id')));
  final StationRequest original = await api.stations.getOriginal();
  assert(original.marker == 'M');
''',
    '''
  final Dio2 result = await api.reserved.getDio(class2:'C', ${http ? 'http2' : 'http'}:'H');
  assert(result.class2 == 'C');
}
''',
  ].join();
}
