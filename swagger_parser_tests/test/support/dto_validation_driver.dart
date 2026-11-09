/// Checks constraint errors against the current JSON representation.
String dtoValidationDriver(
  String folder,
  String version, {
  required bool records,
}) {
  final bool modern = version == 'v3_1' || version == 'v3_2';
  return '''
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  const valid = {'name': 'NORTH', 'capacity': 5, 'nullableName': null};
  Set<(String, String)> failures(api.Station value) => {
    for (final e in value.validate()) (e.path, e.keyword),
  };
  test('reports all field errors with escaped JSON Pointer paths', () {
    final dto = api.Station.fromJson({...valid,
      'name': '', 'capacity': -1, 'step': 0.31, 'values': [1, 1.0],
      'details': {'code': ''}, 'lines': [{'code': 'x'}],
      'labels': {'a/b~c': 'x'}, 'a/b~c': 0, 'validate': '',
      'external': 'x', 'tree': {'label': 'ok', 'children': [{'label': ''}]},
    });
    final List<api.DtoValidationError2> errors = dto.validate();
    expect(failures(dto), containsAll({
      ('/name', 'minLength'), ('/name', 'pattern'), ('/capacity', 'minimum'),
      ('/step', 'multipleOf'), ('/values', 'uniqueItems'),
      ('/details/code', 'minLength'), ('/lines/0/code', 'minLength'),
      ('/labels/a~1b~0c', 'minLength'), ('/a~1b~0c', 'minimum'),
      ('/validate', 'minLength'), ('/external', 'minLength'),
      ('/tree/children/0/label', 'minLength'),
    }));
    expect(errors.every((e) => e.message.isNotEmpty), true);
    expect(() => errors.clear(), throwsUnsupportedError);
    expect(dto.toJson()['capacity'], -1);
  });
  test('checks bounds and preserves valid nulls and optional values', () {
    expect(api.Station.fromJson(valid).validate(), isEmpty);
    expect(api.Station.fromJson({...valid, 'optionalName': null}).validate(), isEmpty);
    expect(api.Station(name: 'OK', capacity: 1, nullableName: null,
      optionalName: ${records ? '(value: null)' : 'null'}).validate(), isEmpty);
    expect(api.Station.fromJson({...valid, 'values': [0.1, 0.2], 'step': 0.3,
      'details': {'code': 'AB'}, 'external': 'AB'}).validate(), isEmpty);
    expect(failures(api.Station.fromJson({...valid, 'name': 'LONGER', 'capacity': 11,
      'values': [1,2,3,4], 'labels': {'a':'ok','b':'ok','c':'ok'}})),
      containsAll({('/name','maxLength'),('/capacity','maximum'),('/values','maxItems'),('/labels','maxProperties')}));
    expect(failures(api.Station.fromJson({...valid, 'values': [], 'labels': <String, Object?>{}, 'name': '😀'})),
      containsAll({('/values','minItems'),('/labels','minProperties'),('/name','minLength')}));
    expect(api.Price.fromJson(0).validate().map((e) => (e.path,e.keyword)), contains(('', 'exclusiveMinimum')));
    expect(api.Price.fromJson(100).validate().map((e) => e.keyword), contains('exclusiveMaximum'));
    expect(api.Price.fromJson(1).validate(), isEmpty);
    expect(api.Status.ready.validate(), isEmpty);
    expect(api.OpenRequired.fromJson(<String, Object?>{}).validate().map((e) => (e.path,e.keyword)), contains(('/token','required')));
    expect(api.OpenRequired.fromJson({'token':1}).validate(), isEmpty);
    expect(api.Combined.fromJson({'code':'x', 'count':0}).validate().map((e) => (e.path,e.keyword)),
      containsAll({('/code','minLength'),('/count','minimum')}));
  });
  test('compares unique objects by their JSON values', () {
    final value = api.Objects.fromJson([{'a':1,'b':2},{'b':2,'a':1.0}]);
    expect(value.validate().map((e) => (e.path,e.keyword)), contains(('', 'uniqueItems')));
    expect(api.Objects.fromJson([{'a':1},{'a':'1'}]).validate(), isEmpty);
  });
  ${version == 'v2' ? '' : """
  test('checks unions with the same constraint predicates', () {
    final api.Choice invalid = api.ChoiceText(code: '');
    expect(invalid.validate().map((e) => (e.path,e.keyword)),
      containsAll({('', 'oneOf'), ('/code', 'minLength')}));
    expect(api.Choice.fromJson({'code':'OK'}).validate(), isEmpty);
    expect(api.Either.fromJson('OK').validate(), isEmpty);
  });
  """}
  ${!modern ? '' : """
  test('checks contains counts and tuple schemas', () {
    expect(api.Matching.fromJson([3]).validate().map((e) => e.keyword), contains('minContains'));
    expect(api.Matching.fromJson([3,4,5,6]).validate().map((e) => e.keyword), contains('maxContains'));
    expect(api.Matching.fromJson([1,3,4]).validate(), isEmpty);
    expect(api.Tuple.fromJson(['OK',2]).validate(), isEmpty);
    expect(api.FalseItems.fromJson([]).validate(), isEmpty);
  });
  """}
}
''';
}
