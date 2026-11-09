import 'package:swagger_parser/swagger_parser.dart';

String defaultDriver(
  HttpClientBackend backend,
  String dir,
  DtoSerializer serializer,
) {
  final http = backend == HttpClientBackend.http;
  final copy =
      serializer == DtoSerializer.freezed ||
          serializer == DtoSerializer.dartMappable
      ? 'assert(dto.copyWith(name:null).name==null); assert(dto.copyWith(limit:8).limit==8);'
      : '';
  return <String>[
    '''
import '$dir/api.dart';
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'package:dio/dio.dart' as dio;"}
''',
    r'''
void rejects(void Function() run) {
  try { run(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}
Future<void> main() async {
  final dto = Options2$Request(id:'s', requiredName:null);
  assert(dto.limit == 20 && dto.name == 'North' && !dto.enabled);
  assert(dto.tags.single == 'one' && dto.empty.isEmpty && dto.weights['east'] == 1.5);
  assert(dto.status == Status.new2 && dto.count.value == 3);
  assert(dto.profile.label == 'Main' && dto.profile.status == Status.active);
  assert(!dto.toJson().containsKey('server_id') && dto.toJson()['secret'] == 'secret');
  assert(!dto.toJson().containsKey('note') && dto.toJson().containsKey('nil'));
  final decoded = Options2$Request.fromJson({'id':'s','required_name':null});
  assert(jsonEncode(decoded.toJson()) == jsonEncode(dto.toJson()));
  final explicit = Options2$Request.fromJson({'id':'s','required_name':null,'name':null});
  assert(explicit.name == null && explicit.toJson().containsKey('name') && explicit.toJson()['name']==null);
  assert(Options2$Request(id:'s',requiredName:null,name:null).name == null);
  final zero = Options2$Request.fromJson({'id':'s','required_name':null,'limit':0,'nil':null});
  assert(zero.limit==0 && zero.nil==null);
  assert(Options2$Request.fromJson({'id':'s','required_name':null,'nil':'N'}).nil=='N');
  rejects(() => Options2$Request.fromJson({'required_name':null}));
  rejects(() => Options2$Request.fromJson({'id':'s'}));
  for (final key in ['limit','enabled','tags','empty','weights','status','profile','count']) {
    rejects(() => Options2$Request.fromJson({'id':'s','required_name':null,key:null}));
  }
  final changed = Options2$Request.fromJson({'id':'s','required_name':'R','limit':5,'name':'South','enabled':true,'tags':[],'empty':[1],'status':'active','profile':{'label':'Other'},'count':4});
  assert(changed.limit==5 && changed.name=='South' && changed.enabled && changed.tags.isEmpty && changed.empty.single==1);
  assert(changed.profile.status == Status.new2 && changed.count.value==4);
  final mutableTags = <String>['x'];
  final mutableMap = <String,num>{'west':2};
  final mutable = Options2$Request(id:'s',requiredName:null,tags:mutableTags,weights:mutableMap);
  mutable.tags.add('y');
  mutable.weights['north']=3;
  assert(mutableTags.length==2 && mutableMap['north']==3);
  final patches = [Options2$Request(id:'s',requiredName:null),
    Options2$Request(id:'s',requiredName:null,note:(value:null)),
    Options2$Request(id:'s',requiredName:null,note:(value:'N'))];
  final rail = Stop.fromJson({'kind':'rail'});
  assert(rail is Rail && rail.name=='Rail' && rail.limit==5);
  final bus = Stop.fromJson({'kind':'bus','name':null});
  assert(bus is Bus && bus.name==null && bus.limit==10 && bus.toJson()['name']==null);
  final sent = <Map<String,Object?>>[];
  final queries = <String?>[];
''',
    if (http)
      '''
  $copy
  final api = Api(MockClient((req) async {
    if (req.method == 'GET') queries.add(req.url.queryParameters['limit']);
    else sent.add(jsonDecode(req.body) as Map<String,Object?>);
    return http.Response('{"id":"s","required_name":null}',200,headers:{'content-type':'application/json'});
  }),baseUrl:Uri.parse('https://options.test'));
'''
    else
      '''
  $copy
  final client = dio.Dio(dio.BaseOptions(baseUrl:'https://options.test'));
  client.interceptors.add(dio.InterceptorsWrapper(onRequest:(req,handler) {
    if (req.method == 'GET') queries.add(req.uri.queryParameters['limit']);
    else sent.add((req.data is String ? jsonDecode(req.data as String) : req.data) as Map<String,Object?>);
    handler.resolve(dio.Response(requestOptions:req,statusCode:200,data:{'id':'s','required_name':null}));
  }));
  final api = Api(client);
''',
    '''
  for (final patch in patches) {
    final result = await api.api.saveOptions(body:patch);
    assert(result.limit==20 && result.name=='North' && result.serverId=='server');
    assert(!result.toJson().containsKey('secret'));
  }
  assert(sent.every((v)=>v['limit']==20 && v['name']=='North'));
  assert(!sent[0].containsKey('note') && sent[1].containsKey('note') && sent[1]['note']==null && sent[2]['note']=='N');
  await api.api.getOptions();
  await api.api.getOptions(limit:7);
  assert(queries[0]==null && queries[1]=='7');
}
''',
  ].join();
}
