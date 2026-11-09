import 'package:swagger_parser/swagger_parser.dart';

String directionalMappingsDriver(
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

  return r'''
import 'dart:convert';
import 'package:swagger_parser_tests/directional_types.dart' as defaults;
@transportImport@
import '@dir@/api.dart';

bool sameJson(Object? a, Object? b) {
  if (a is Map && b is Map) return a.length==b.length && a.keys.every((key)=>b.containsKey(key) && sameJson(a[key],b[key]));
  if (a is List && b is List) return a.length==b.length && List.generate(a.length,(i)=>i).every((i)=>sameJson(a[i],b[i]));
  return a==b;
}

void rejects(void Function() read) {
  try { read(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

final requestStation = <String,Object?>{'name':'North',@secret@};
final responseStation = <String,Object?>{'name':'North','id':'s1'};
Map<String,Object?> envelope(Map<String,Object?> station, {bool response=false}) => {
  'station':station,
  'stations':[station],
  'byName':{'north':station},
  'label':{'name':'label'},
  'same':{'name':'same',if(response) 'id':'shared'},
  'partial':station,
};

Future<void> main() async {
  final request = Envelope$Request.fromJson(envelope(requestStation));
  final CreateStation station = request.station;
  final List<CreateStation> stations = request.stations;
  final Map<String,CreateStation> byName = request.byName;
  final DraftLabel label = request.label;
  assert(station.name=='North' && stations.first.name=='North');
  assert(byName['north']!.name=='North' && label.name=='label');
  assert(sameJson(request.toJson(),envelope(requestStation)));
  assert(!((request.toJson()['same']! as Map).containsKey('id')));
  final response = Envelope$Response.fromJson(envelope(responseStation,response:true));
  final Station received = response.station;
  final Label receivedLabel = response.label;
  final Partial$Response partial = response.partial;
  assert(received.id=='s1' && receivedLabel.name=='label' && partial.id=='s1');
  assert(response.stations.first.id=='s1');
  assert(response.byName['north']!.id=='s1');
  assert(response.same.id=='shared');
  assert(sameJson(response.toJson(),envelope(responseStation,response:true)));
  rejects(()=>Envelope$Response.fromJson(envelope(requestStation,response:true)));
  assert(!((Envelope$Request.fromJson(envelope(responseStation)).toJson()['station']! as Map).containsKey('id')));
  rejects(()=>Envelope$Request.fromJson(envelope({...requestStation,'extra':true})));
  rejects(()=>Envelope$Request.fromJson(envelope({'name':12})));
  rejects(()=>Envelope$Response.fromJson(envelope({'id':12,'name':'North'},response:true)));
  const settingsRequest = Settings$Request();
  const settingsResponse = Settings$Response();
  assert(identical(settingsRequest.preferences,defaults.defaultDraft));
  assert(identical(settingsResponse.preferences,defaults.defaultView));
  assert(identical(Settings$Request.fromJson({}).preferences,defaults.defaultDraft));
  assert(identical(Settings$Response.fromJson({}).preferences,defaults.defaultView));
  assert(Settings$Request.fromJson({'preferences':null}).preferences==null);
  assert(Settings$Response.fromJson({'preferences':null}).preferences==null);
  assert(Settings$Request(preferences:null).toJson()['preferences']==null);
  assert(Settings$Request.fromJson({'preferences':{'name':'South'}}).preferences!.name=='South');
  assert(Settings$Response.fromJson({'preferences':{'name':'South','id':'p1'}}).preferences!.id=='p1');
  assert(Settings$Request.fromJson({'preferences':{'name':'South','id':'p1'}}).preferences!.name=='South');
  final DraftLabel forced = LabelBox$Request.fromJson({'label':{'name':'in'}}).label;
  final Label shared = LabelBox$Response.fromJson({'label':{'name':'out'}}).label;
  assert(forced.name=='in' && shared.name=='out');
  final DraftLabel aliasRequest=AliasBox$Request.fromJson({'alias':{'name':'in'}}).alias; assert(aliasRequest.name=='in');
  final Label aliasResponse=AliasBox$Response.fromJson({'alias':{'name':'out'}}).alias; assert(aliasResponse.name=='out');
  final InboundOnly$Request inboundRequest=InboundBox$Request.fromJson({'station':requestStation}).station;
  final Station inboundResponse=InboundBox$Response.fromJson({'station':responseStation}).station;
  assert(inboundRequest.name=='North' && inboundResponse.id=='s1');
  assert(Composed$Request.fromJson({'label':{'name':'in'}}).label.name=='in');
  assert(Composed$Response.fromJson({'label':{'name':'out'}}).label.name=='out');
  final tree=Node$Request.fromJson({'station':requestStation,'children':[{'station':requestStation,'children':<Object?>[]}]});
  assert(tree.children.single.station.name=='North');
  assert((tree.toJson()['children']! as List).length==1);
  assert(Node$Response.fromJson({'station':responseStation,'children':<Object?>[]}).station.id=='s1');
  final DraftLabel requestId=CodeBox$Request.fromJson({'id':'input'}).id;
  final Label responseId=CodeBox$Response.fromJson({'id':'output'}).id;
  assert(requestId.name=='input' && responseId.name=='output');
  assert(CodeBox$Request(id:requestId).toJson()['id']=='input');
  rejects(()=>Settings$Request(preferences:const PreferenceDraft('')).toJson());
  rejects(()=>Settings$Response(preferences:const PreferenceView('')).toJson());
  @dynamic@
  @copyWith@
  @union@
  final calls=<Uri>[];
  Object reply(Uri uri, String? body) {
    calls.add(uri);
    final json=jsonDecode(body!) as Map;
    if (uri.path=='/station') {
      assert(json['name']=='North' && !json.containsKey('id'));
      @checkSecret@
      return responseStation;
    }
    if (uri.path=='/envelope') {
      assert(sameJson(json,envelope(requestStation)));
      return envelope(responseStation,response:true);
    }
    throw StateError('Unexpected URL: $uri');
  }
  @transport@
  final Station result = @callStation@;
  assert(result.id=='s1');
  final Envelope$Response batch = @callEnvelope@;
  assert(batch.station.id=='s1' && batch.partial.id=='s1');
  assert(calls.length==2);
  transport.@close@;
}
@adapter@
'''
      .replaceAll('@dir@', dir)
      .replaceAll(
        '@dynamic@',
        ['3_1', '3_2'].contains(version)
            ? r"final DraftLabel dynamicRequest=DynamicBox$Request.fromJson({'label':{'name':'in'}}).label; final Label dynamicResponse=DynamicBox$Response.fromJson({'label':{'name':'out'}}).label; assert(dynamicRequest.name=='in' && dynamicResponse.name=='out');"
            : '',
      )
      .replaceAll('@secret@', version == '2_0' ? '' : "'secret':'token'")
      .replaceAll(
        '@checkSecret@',
        version == '2_0' ? '' : "assert(json['secret']=='token');",
      )
      .replaceAll(
        '@transportImport@',
        http
            ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';"
            : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';",
      )
      .replaceAll(
        '@copyWith@',
        serializer == DtoSerializer.freezed ||
                serializer == DtoSerializer.dartMappable
            ? 'assert(settingsRequest.copyWith(preferences:null).preferences==null); assert(settingsResponse.copyWith(preferences:null).preferences==null);'
            : '',
      )
      .replaceAll(
        '@union@',
        version == '2_0' ? '' : r'assert(Choice$Request.fromJson(requestStation).toJson() is Map); assert(Choice$Response.fromJson(responseStation).toJson() is Map); rejects(()=>Choice$Response.fromJson(requestStation));',
      )
      .replaceAll(
        '@transport@',
        http
            ? "final transport=MockClient((request) async=>http.Response(jsonEncode(reply(request.url,request.body)),200,headers:{'content-type':'application/json'})); final api=Api(transport,baseUrl:Uri.parse('https://example.test'));"
            : "final transport=Dio(BaseOptions(baseUrl:'https://example.test')); transport.httpClientAdapter=Adapter(reply); final api=Api(transport);",
      )
      .replaceAll(
        '@callStation@',
        call('echoStation', 'body:station', 'EchoStation'),
      )
      .replaceAll(
        '@callEnvelope@',
        call('echoEnvelope', 'body:request', 'EchoEnvelope'),
      )
      .replaceAll('@close@', http ? 'close()' : 'close(force:true)')
      .replaceAll(
        '@adapter@',
        http
            ? ''
            : '''
class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final Object Function(Uri,String?) reply;
  @override Future<ResponseBody> fetch(RequestOptions options,Stream<Uint8List>? stream,Future<void>? cancel) async {
    final body=stream==null?null:utf8.decode(await stream.expand((b)=>b).toList());
    return ResponseBody.fromString(jsonEncode(reply(options.uri,body)),200,headers:{'content-type':['application/json']});
  }
  @override void close({bool force=false}) {}
}
''',
      );
}
