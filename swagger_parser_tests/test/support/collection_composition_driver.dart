String collectionCompositionDriver(
  String folder,
  String group,
  String version,
  String values,
) =>
    '''
import 'dart:convert';
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  ${group == 'collections' ? """
  test('preserves recursive DTO maps, list layers, nulls, and typed extras', () {
    final json = jsonDecode(r'''$values''') as Map<String, dynamic>;
    final dto = api.CollectionRoot.fromJson(json);
    expect(jsonDecode(jsonEncode(dto)), json);
    expect(dto.validate(), isEmpty);
    expect(dto.chains['root']!.value.children!['next']!.meta!.code, 7);
    expect(dto.rows.single['r']!.value.name, 'root');
    expect(dto.deep.single['r']!.single.value.name, 'root');
    expect(dto.strings['errors'], ['one', 'two']);
    expect(dto.nullableMap, isNull);
    expect(dto.nullableLists['absent'], isNull);
    expect(dto.nullableItems['values'], [null, 'yes']);
    expect(dto.first.left, 'a');
    expect(dto.second.right, 2);
    expect(dto.first.toJson()['extra'], 'kept');
    expect(dto.second.toJson()['extra'], 3);
    expect(dto.first.runtimeType, isNot(dto.second.runtimeType));
  });
  """ : """
  test('intersects repeated scalar fields and keeps distinct wire keys', () {
    const json = {'prop_a':'a','prop_b':'b','prop_c':'c','prop_main':'main','count':5,'snake-key':'dash','snake_key':'underscore'};
    final dto = api.Main.fromJson(json);
    expect(jsonDecode(jsonEncode(dto)), json);
    expect(dto.validate(), isEmpty);
    expect(dto.count, 5);
    expect(dto.propA, 'a');
    expect(dto.propB, 'b');
    expect(dto.propC, 'c');
    expect(dto.propMain, 'main');
    expect(api.Main.fromJson({...json, 'count':0}).validate().map((e)=>(e.path,e.keyword)), contains(('/count','minimum')));
    expect(api.Main.fromJson({...json, 'count':11}).validate().map((e)=>(e.path,e.keyword)), contains(('/count','maximum')));
    final repeated = api.Repeated.fromJson({'code':'OK','rating':2});
    final int rating = repeated.rating;
    expect(rating, 2);
    expect(repeated.validate(), isEmpty);
    expect(api.ScalarDefaults().limit, 5);
    expect(api.ScalarDefaults.fromJson({}).limit, 5);
    expect(api.ScalarDefaults(limit: 0).validate().map((e)=>(e.path,e.keyword)), contains(('/limit','minimum')));
    expect(api.ScalarDefaults(limit: 11).validate().map((e)=>(e.path,e.keyword)), contains(('/limit','maximum')));
    expect(api.Repeated.fromJson({'code':'x','rating':2}).validate().map((e)=>(e.path,e.keyword)), contains(('/code','minLength')));
  });
  test('round trips nested inherited models and property recursion', () {
    const json = {'name':'pet', 'trackers':[{'id':'tracker','events':[{'id':'event','at':'now'}]}]};
    final pet = api.Pet.fromJson(json);
    expect(pet.trackers.single.events.single.at, 'now');
    expect(jsonDecode(jsonEncode(pet)), json);
    expect(pet.validate(), isEmpty);
    const tree = {'id':'parent','children':[{'id':'child'}]};
    expect(jsonDecode(jsonEncode(api.Recursive.fromJson(tree))), tree);
  });
  test('keeps single-branch wrappers and nullable intersections', () {
    const json = {'image':{'url':'image.png'}};
    final dto = api.ImageUse.fromJson(json);
    expect(jsonDecode(jsonEncode(dto)), json);
    expect(dto.validate(), isEmpty);
    expect(api.ImageUse.fromJson({'image':{'url':''}}).validate().map((e)=>(e.path,e.keyword)), contains(('/image/url','minLength')));
    expect(jsonDecode(jsonEncode(api.ImageFragment.fromJson({'url':'image.png'}))), {'url':'image.png'});
    expect(() => api.NullableIntersection.fromJson(null), throwsA(anything));
    expect(jsonDecode(jsonEncode(api.NullableIntersection.fromJson('value'))), 'value');
    expect(jsonDecode(jsonEncode(api.NullableBoth.fromJson(null))), isNull);
    ${version == 'v2' ? '' : """
    expect(jsonDecode(jsonEncode(api.OneNullable.fromJson(null))), isNull);
    expect(jsonDecode(jsonEncode(api.AnyNullable.fromJson(null))), isNull);
    expect(() => api.OneBranch.fromJson({'url':''}), throwsFormatException);
    expect(() => api.AnyBranch.fromJson({'url':''}), throwsFormatException);
    expect(jsonDecode(jsonEncode(api.OneBranch.fromJson({'url':'image.png'}))), {'url':'image.png'});
    expect(jsonDecode(jsonEncode(api.AnyBranch.fromJson({'url':'image.png'}))), {'url':'image.png'});
    """}
  });
  """}
}
''';
