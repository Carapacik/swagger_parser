import 'package:swagger_parser/swagger_parser.dart';

String objectMappingsDriver(
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
import 'package:swagger_parser_tests/object_defaults.dart' as defaults;
import 'package:swagger_parser_tests/object_codecs.dart' as codecs;
${http ? "import 'package:http/http.dart' as http;\nimport 'package:http/testing.dart';" : "import 'dart:typed_data';\nimport 'package:dio/dio.dart';"}
import '$dir/api.dart';

void rejects(void Function() read) {
  try { read(); } catch (_) { return; }
  throw StateError('Expected rejection.');
}

final requiredWire = <String,Object?>{'requiredPoint':{'latitude':0,'longitude':0},'requiredId':'unknown'};
Future<void> main() async {
  const dto = Station(requiredPoint:defaults.origin,requiredId:defaults.unknownStationId);
  assert(identical(dto.location,defaults.origin));
  assert(identical(dto.id,defaults.unknownStationId));
  assert(identical(dto.nullableId,defaults.unknownStationId));
  assert(dto.nullId == null && dto.plainId == null && dto.optionalLocation == null);
  assert(identical(dto.points.first,defaults.origin));
  assert(identical(dto.points.last,defaults.east));
  assert(identical(dto.byName['origin'],defaults.origin));
  codecs.pointReads=0;
  final read = Station.fromJson(requiredWire);
  assert(codecs.pointReads == 1);
  assert(identical(read.location,defaults.origin));
  assert(identical(read.id,defaults.unknownStationId));
  assert(identical(read.points.last,defaults.east));
  final cleared = Station.fromJson({...requiredWire,'location':null,'nullableId':null,'optionalLocation':null});
  assert(cleared.location == null && cleared.nullableId == null);
  assert(cleared.optionalLocation != null && cleared.optionalLocation!.value == null);
  assert(cleared.toJson().containsKey('location') && cleared.toJson()['location'] == null);
  assert(cleared.toJson().containsKey('optionalLocation'));
  assert(!read.toJson().containsKey('optionalLocation'));
  final changed = Station.fromJson({...requiredWire,'location':{'latitude':1,'longitude':2},'allOfPoint':{'latitude':4,'longitude':5}});
  assert(changed.location!.latitude == 1 && changed.location!.longitude == 2);
  assert(changed.allOfPoint!.latitude == 4);
  rejects(()=>Station.fromJson({}));
  rejects(()=>Station.fromJson({'requiredPoint':requiredWire['requiredPoint']}));
  rejects(()=>Station.fromJson({...requiredWire,'requiredPoint':null}));
  rejects(()=>Station.fromJson({...requiredWire,'id':null}));
  rejects(()=>Station.fromJson({...requiredWire,'location':{'latitude':100,'longitude':0}}));
  rejects(()=>Station.fromJson({...requiredWire,'location':{'latitude':0}}));
  rejects(()=>Station.fromJson({...requiredWire,'location':{'latitude':0,'longitude':0,'extra':true}}));
  rejects(()=>Station(requiredPoint:const GeoPoint(latitude:100,longitude:0),requiredId:defaults.unknownStationId).toJson());
  const empty = Station(requiredPoint:defaults.origin,requiredId:defaults.unknownStationId,location:null,nullableId:null);
  assert(empty.location == null && empty.nullableId == null);
  const dashboard = Dashboard();
  assert(dashboard.station.requiredPoint.latitude == 0);
  assert(identical(dashboard.station.points.first,defaults.origin));
  assert(Dashboard.fromJson({}).station.points.length == 1);
  codecs.pointReads=0; codecs.pointWrites=0;
  final holder=Holder.fromJson({'envelope':{'point':{'latitude':1,'longitude':2}}});
  assert(holder.envelope.point.latitude==1);
  assert((holder.toJson()['envelope']! as Map)['point'] is Map);
  assert(codecs.pointReads==0 && codecs.pointWrites==0);
  ${serializer == DtoSerializer.freezed || serializer == DtoSerializer.dartMappable ? 'assert(read.copyWith(location:null).location == null);' : ''}
  ${version != '2_0' ? "assert(Place.fromJson({'latitude':1,'longitude':2}).toJson() is Map); assert(Place.fromJson(null).toJson() == null); assert(AnyPlace.fromJson({'latitude':1,'longitude':2}).asGeoPoint!.latitude == 1);" : ''}
  final tagged=TaggedPlace.fromJson({'kind':'${version == '2_0' ? 'TaggedPoint' : 'point'}','latitude':1,'longitude':2});
  assert(tagged is TaggedPlaceTaggedPoint);
  assert((tagged as TaggedPlaceTaggedPoint).value.point.latitude==1);
  assert(tagged.toJson()['kind']=='${version == '2_0' ? 'TaggedPoint' : 'point'}');
  final calls=<Uri>[];
  Object reply(Uri uri, String? body) {
    calls.add(uri);
    if (uri.path=='/point') {
      final json=jsonDecode(body!) as Map;
      assert(json['latitude']==1 && json['longitude']==2);
      return {'latitude':3,'longitude':4};
    }
    if (uri.path=='/station') return requiredWire;
    if (uri.path=='/search') {
      assert(uri.queryParameters['point[latitude]']=='1.0');
      assert(uri.queryParameters['point[longitude]']=='2.0');
      return {'latitude':3,'longitude':4};
    }
    throw StateError('Unexpected URL: \$uri');
  }
  ${http ? "final transport=MockClient((request) async=>http.Response(jsonEncode(reply(request.url,request.body)),200,headers:{'content-type':'application/json'})); final api=Api(transport,baseUrl:Uri.parse('https://example.test'));" : "final transport=Dio(BaseOptions(baseUrl:'https://example.test')); transport.httpClientAdapter=Adapter(reply); final api=Api(transport);"}
  final GeoPoint point=${call('echoPoint', 'body:defaults.east', 'EchoPoint')};
  assert(point.latitude==3 && point.longitude==4);
  final station=${call('getStation', '', 'GetStation')};
  assert(identical(station.location,defaults.origin));
  ${version != '2_0' ? 'assert((${call('search', 'point:defaults.east', 'Search')}).latitude==3);' : ''}
  assert(calls.length==${version == '2_0' ? 2 : 3});
  transport.${http ? 'close()' : 'close(force:true)'};
}
${http ? '' : '''
class Adapter implements HttpClientAdapter {
  Adapter(this.reply);
  final Object Function(Uri,String?) reply;
  @override Future<ResponseBody> fetch(RequestOptions options,Stream<Uint8List>? stream,Future<void>? cancel) async {
    final body=stream==null?null:utf8.decode(await stream.expand((b)=>b).toList());
    return ResponseBody.fromString(jsonEncode(reply(options.uri,body)),200,headers:{'content-type':['application/json']});
  }
  @override void close({bool force=false}) {}
}
'''}
''';
}
