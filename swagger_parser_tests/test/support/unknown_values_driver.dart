import 'package:swagger_parser/swagger_parser.dart';

String unknownValuesDriver(
  String dir,
  String version,
  DtoSerializer serializer,
  HttpClientBackend backend, {
  required bool preserve,
}) {
  final http = backend == HttpClientBackend.http;
  return '''
import '$dir/api.dart';
import 'dart:convert';
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'package:dio/dio.dart' as dio;"}
void rejects(void Function() run) {
  try { run(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}
Future<void> main() async {
  assert(Status.fromJson('active') == Status.active);
  assert(Status.active.toJson() == 'active');
  assert(Stop.fromJson({'kind':'Rail','platform':1}) is Rail);
  for (final bad in [<String,Object?>{}, {'kind':null}, {'kind':1}, {'kind':'Rail'}, {'kind':'Rail','platform':'wrong'}]) {
    rejects(() => Stop.fromJson(bad));
  }
  final known = Rail(platform:2);
  assert(known.toJson()['kind']=='Rail');
  final input = <String,Object?>{
    'status': '${preserve ? 'paused' : 'active'}',
    'numeric': ${preserve ? 99 : 1},
    'flag': ${!preserve},
    'fraction': ${preserve ? 2.5 : 1.5},
    'stop': ${preserve ? "{'kind':'Boat','kind_label':'express','details':{'decks':[1,2]}}" : "{'kind':'Rail','platform':1}"},
    'history':['active', '${preserve ? 'paused' : 'disabled'}'],
    'by_name':{'next':'${preserve ? 'paused' : 'active'}'},
  };
  final envelope = Envelope.fromJson(input);
  assert(envelope.fallback == Status.active);
  final encoded = envelope.toJson();
  assert(encoded['status']==input['status'] && encoded['numeric']==input['numeric']);
  assert(encoded['flag']==input['flag'] && encoded['fraction']==input['fraction']);
  assert(envelope.history!.last.toJson()==(input['history'] as List).last);
  assert(envelope.byName!['next']!.toJson()==(input['by_name'] as Map)['next']);
  ${preserve ? '''
  final Status value = Status.fromJson('paused');
  assert(value is StatusUnknown && value.rawValue == 'paused');
  assert(Status.active.value == StatusValue.active);
  assert(value == const StatusUnknown('paused'));
  assert(value.hashCode == const StatusUnknown('paused').hashCode);
  assert(NumericStatus.fromJson(99) is NumericStatusUnknown);
  assert(NumericStatus.fromJson(99).toJson().runtimeType == int);
  assert(Fraction.fromJson(2.5).toJson().runtimeType == double);
  assert(Flag.fromJson(false).toJson() == false);
  assert(Collision.fromJson('other').toJson() == 'other');
  for(final bad in [null, 1, true, <String,Object?>{}, <Object?>[]]) {
    rejects(() => Status.fromJson(bad));
  }
  rejects(() => NumericStatus.fromJson('99'));
  rejects(() => NumericStatus.fromJson(1.5));
  rejects(() => Fraction.fromJson(double.nan));
  final raw = {'kind':'Boat','details':{'decks':[1,2]},'nullable':null};
  final unknown = Stop.fromJson(raw) as StopUnknown;
  (raw['details'] as Map)['decks'] = [9];
  assert(((unknown.rawJson['details'] as Map)['decks'] as List).first == 1);
  rejects(() => unknown.rawJson['kind'] = 'Bus');
  rejects(() => ((unknown.rawJson['details'] as Map)['decks'] as List).add(3));
  final output = unknown.toJson();
  ((output['details'] as Map)['decks'] as List).add(3);
  assert(((unknown.toJson()['details'] as Map)['decks'] as List).length == 2);
  assert(unknown.toJson().containsKey('nullable'));
  assert(envelope.stop is StopUnknown);
  rejects(() => Rail.fromJson({'kind':'Boat','platform':1}));
  rejects(() => Alias.fromJson({'kind':'Boat','platform':1}));
  rejects(() => Alias(kind:AliasKind.fromJson('Boat'),platform:1).toJson());
''' : '''
  rejects(() => Status.fromJson('paused'));
  rejects(() => Stop.fromJson({'kind':'Boat','details':{}}));
'''}
  ${version == '3_2' ? '''
  final fallback = DeclaredStop.fromJson({'kind':'Boat','code':7});
  assert(fallback is DeclaredFallback && fallback.code == 7);
  rejects(() => DeclaredStop.fromJson({'kind':'Boat'}));
''' : ''}
  ${version == '2_0' ? r'''
  final base = Stop.fromJson({'kind':'Stop'});
  assert(base is StopValue && base.toJson()['kind']=='Stop');
  final middle = Stop.fromJson({'kind':'Middle','label':'group'});
  assert(middle is MiddleValue && middle.toJson()['label']=='group');
  final leaf = Stop.fromJson({'kind':'Leaf','label':'group','level':2});
  assert(leaf is Leaf && leaf.toJson()['level']==2);
  assert(Middle.fromJson({'kind':'Leaf','label':'group','level':2}) is Leaf);
  rejects(() => Stop.fromJson({'kind':'Leaf','label':'group'}));
  final request = Entity$Request.fromJson({'kind':'Entry','name':'entry'});
  assert(request is Entry$Request && !request.toJson().containsKey('id'));
  final response = Entity$Response.fromJson({'kind':'Entry','name':'entry','id':4});
  assert(response is Entry$Response && response.toJson()['id']==4);
  rejects(() => Entity$Response.fromJson({'kind':'Entry','name':'entry'}));
''' : '''
  final alias = Stop.fromJson({'kind':'Train','platform':2});
  assert(alias is Alias && alias.toJson()['kind']=='Train');
'''}
  ${serializer == DtoSerializer.freezed || serializer == DtoSerializer.dartMappable ? '''
  final changed = envelope.copyWith(status:Status.disabled);
  assert(changed.status == Status.disabled && changed.stop.toJson()['kind']==envelope.stop.toJson()['kind']);
''' : ''}
  ${http ? '''
  final api = Api(MockClient((request) async {
    final data = request.url.path == '/status' ? input['status'] : request.url.path == '/stop' ? input['stop'] : jsonDecode(request.body);
    return http.Response(jsonEncode(data),200,headers:{'content-type':'application/json'});
  }),baseUrl:Uri.parse('https://unknown.test'));
''' : '''
  final dioClient = dio.Dio(dio.BaseOptions(baseUrl:'https://unknown.test'));
  dioClient.interceptors.add(dio.InterceptorsWrapper(onRequest:(req,handler) {
    final data = req.path == '/status' ? input['status'] : req.path == '/stop' ? input['stop'] : req.data is String ? jsonDecode(req.data as String) : req.data;
    handler.resolve(dio.Response(requestOptions:req,statusCode:200,data:data));
  }));
  final api = Api(dioClient);
'''}
  final Status status = await api.api.getStatus();
  final Stop stop = await api.api.getStop();
  assert(status.toJson()==input['status'] && stop.toJson()['kind']==(input['stop'] as Map)['kind']);
  final Envelope returned = await api.api.saveEnvelope(body:envelope);
  assert(returned.status.toJson()==input['status']);
}
''';
}
