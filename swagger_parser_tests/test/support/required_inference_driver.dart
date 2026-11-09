/// Checks required projection, nullable APIs, and JSON round trips.
String requiredInferenceDriver(
  String folder,
  String version, {
  required bool infer,
  required bool records,
}) {
  final bool modern = version == 'v3_1' || version == 'v3_2';
  return '''
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  const payload = {'id': 's', 'refValue': 'r'};
  const expected = {...payload, 'enabled': true, 'refDefault': 5, 'externalDefault': 'Outside'};
  test('infers only missing non-nullable fields without defaults', () {
    final dto = api.Station.fromJson(payload);
    expect(dto.id, 's');
    expect(dto.refValue${infer ? '' : '?'}.value, 'r');
    expect(dto.toJson(), expected);
    ${infer ? "expect(() => api.Station.fromJson({}), throwsA(anything));" : "expect(api.Station.fromJson({}).toJson(), {'enabled': true, 'refDefault': 5, 'externalDefault': 'Outside'});"}
    expect(() => api.Station.fromJson({...payload, 'id': null}), throwsA(anything));
    expect(() => api.Station.fromJson({...payload, 'enabled': null}), throwsA(anything));
    expect(api.Station.fromJson({...payload, 'enabled': false}).enabled, false);
    expect(() => api.Partial.fromJson({}), throwsA(anything));
    expect(api.Partial.fromJson({'name': null}).toJson(), {'name': null, 'enabled': true, 'refDefault': 5, 'externalDefault': 'Outside'});
  });
  test('keeps the selected nullable API in constructors and codecs', () {
    final dto = api.Station(id: 's', refValue: const api.Text('r'));
    expect(dto.name, null);
    expect(dto.toJson(), expected);
    final empty = api.Station(id: 's', refValue: const api.Text('r'), name: ${records ? '(value: null)' : 'null'});
    expect(empty.toJson(), {...expected, ${records ? "'name': null," : ''}});
    final named = api.Station(id: 's', refValue: const api.Text('r'), name: ${records ? "(value: 'North')" : "'North'"});
    expect(named.toJson()['name'], 'North');
    final decoded = api.Station.fromJson({...payload, 'name': null});
    expect(decoded.name, ${records ? '(value: null)' : 'null'});
    expect(decoded.toJson(), {...expected, ${records ? "'name': null," : ''}});
    final refNull = api.Station.fromJson({...payload, 'refNullable': null});
    expect(refNull.toJson(), {...expected, ${records ? "'refNullable': null," : ''}});
  });
  test('applies direction before required inference', () {
    expect(api.Directional\$Response.fromJson({'id': 's'}).toJson(), {'id': 's'});
    ${version == 'v2' ? r"expect(api.Directional$Request.fromJson({'id': 's'}).toJson(), isEmpty);" : r"expect(api.Directional$Request.fromJson({'id': 's', 'secret': 'key'}).toJson(), {'secret': 'key'});"}
    ${infer ? r"expect(() => api.Directional$Response.fromJson({}), throwsA(anything));" : r"expect(api.Directional$Response.fromJson({}).toJson(), isEmpty);"}
  });
  test('respects required declarations across allOf without changing the base', () {
    ${infer ? "expect(() => api.Base.fromJson({}), throwsA(anything)); expect(() => api.AllMissing.fromJson({}), throwsA(anything));" : "expect(api.Base.fromJson({}).toJson(), isEmpty); expect(api.AllMissing.fromJson({}).toJson(), isEmpty);"}
    expect(api.AllMissing.fromJson({'first': 'a', 'second': 2}).toJson(), {'first': 'a', 'second': 2});
    expect(() => api.AllPartial.fromJson({}), throwsA(anything));
    expect(api.AllPartial.fromJson({'first': 'a'}).toJson(), {'first': 'a'});
    ${modern || !infer ? """
    expect(api.Empty.fromJson({}).toJson(), {'enabled': true, 'refDefault': 5, 'externalDefault': 'Outside'});
    expect(api.AllEmpty.fromJson({}).toJson(), isEmpty);
    expect(api.AllParentEmpty.fromJson({}).toJson(), isEmpty);
    """ : """
    expect(() => api.Empty.fromJson({}), throwsA(anything));
    expect(() => api.AllEmpty.fromJson({}), throwsA(anything));
    expect(() => api.AllParentEmpty.fromJson({}), throwsA(anything));
    """}
  });
  const siblingDefaults = {'enabled': true, 'ref_default': 5, 'required_default': 7};
  const siblingValues = {'composed': {'value': 'nested'}, 'plain': false, 'Code': 'upper', 'code': 'lower'};
  test('keeps sibling presence independent from a composed property', () {
    expect(api.SiblingMissing.fromJson(siblingValues).toJson(), {...siblingValues, ...siblingDefaults});
    expect(api.SiblingDirect.fromJson(siblingValues).toJson(), {...siblingValues, ...siblingDefaults});
    ${infer ? """
    expect(() => api.SiblingMissing.fromJson({}), throwsA(anything));
    expect(() => api.SiblingDirect.fromJson({}), throwsA(anything));
    for (final key in siblingValues.keys) {
      final missing = Map<String, Object?>.of(siblingValues)..remove(key);
      expect(() => api.SiblingMissing.fromJson(missing), throwsA(anything));
      expect(() => api.SiblingDirect.fromJson(missing), throwsA(anything));
    }
    """ : """
    expect(api.SiblingMissing().toJson(), siblingDefaults);
    expect(api.SiblingMissing.fromJson({}).toJson(), siblingDefaults);
    expect(api.SiblingDirect.fromJson({}).toJson(), siblingDefaults);
    """}
    for (final key in [...siblingValues.keys, ...siblingDefaults.keys]) {
      expect(() => api.SiblingMissing.fromJson({...siblingValues, key: null}), throwsA(anything));
      expect(() => api.SiblingDirect.fromJson({...siblingValues, key: null}), throwsA(anything));
    }
    expect(() => api.SiblingMissing.fromJson({...siblingValues, 'composed': {}}), throwsA(anything));
    expect(() => api.SiblingDirect.fromJson({...siblingValues, 'composed': {}}), throwsA(anything));
    final withNulls = {...siblingValues, 'nullable_id': null, 'nullable_ref': null};
    expect(api.SiblingMissing.fromJson(withNulls).toJson(), {...siblingValues, ...siblingDefaults, ${records ? "'nullable_id': null, 'nullable_ref': null," : ''}});
  });
  test('uses exact required names and retains required nullable values', () {
    const required = {'nullable_id': null, 'Code': 'upper', 'required_default': 9};
    final output = {...siblingDefaults, ...required};
    expect(api.SiblingExplicit(nullableId: null, code: 'upper', requiredDefault: 9).toJson(), output);
    expect(api.SiblingExplicit.fromJson(required).toJson(), output);
    for (final key in required.keys) {
      final missing = Map<String, Object?>.of(required)..remove(key);
      expect(() => api.SiblingExplicit.fromJson(missing), throwsA(anything));
    }
    expect(() => api.SiblingExplicit.fromJson({'nullable_id': null, 'code': 'wrong case', 'required_default': 9}), throwsA(anything));
    for (final key in ['Code', 'code', 'plain', 'composed', 'enabled', 'ref_default', 'required_default']) {
      expect(() => api.SiblingExplicit.fromJson({...required, key: null}), throwsA(anything));
    }
    for (final flag in [false, true]) {
      final json = {...required, ...siblingValues, 'plain': flag, 'enabled': flag, 'nullable_id': 'id', 'nullable_ref': 'ref'};
      expect(api.SiblingExplicit.fromJson(json).toJson(), {...siblingDefaults, ...json});
    }
    expect(() => api.SiblingExplicit.fromJson({...required, 'composed': {}}), throwsA(anything));
    expect(api.SiblingExplicit.fromJson({...required, 'nullable_ref': null}).toJson(), {...output, ${records ? "'nullable_ref': null," : ''}});
  });
  test('makes removed required members optional without accepting null', () {
    expect(api.SiblingReduced(nullableId: null).toJson(), {...siblingDefaults, 'nullable_id': null});
    expect(api.SiblingReduced.fromJson({'nullable_id': null}).toJson(), {...siblingDefaults, 'nullable_id': null});
    expect(() => api.SiblingReduced.fromJson({}), throwsA(anything));
    for (final key in ['Code', 'code', 'plain', 'composed', 'required_default']) {
      expect(() => api.SiblingReduced.fromJson({'nullable_id': null, key: null}), throwsA(anything));
    }
    final json = {...siblingValues, 'nullable_id': null, 'required_default': 0, 'enabled': false, 'ref_default': 0};
    expect(api.SiblingReduced.fromJson(json).toJson(), json);
  });
  ${modern ? """
  test('keeps explicit empty required lists independent from nested required', () {
    expect(api.SiblingEmpty().toJson(), siblingDefaults);
    expect(api.SiblingEmpty.fromJson({}).toJson(), siblingDefaults);
    expect(api.SiblingEmpty.fromJson(siblingValues).toJson(), {...siblingValues, ...siblingDefaults});
    for (final key in siblingValues.keys) {
      expect(() => api.SiblingEmpty.fromJson({key: null}), throwsA(anything));
    }
    expect(() => api.SiblingEmpty.fromJson({'composed': {}}), throwsA(anything));
    expect(api.SiblingEmpty.fromJson({'nullable_id': null, 'nullable_ref': null}).toJson(), {...siblingDefaults, ${records ? "'nullable_id': null, 'nullable_ref': null," : ''}});
  });
  """ : ''}
  ${version == 'v2' ? '' : """
  test('uses the same required projection for union matching and decoding', () {
    ${infer ? "expect(api.Choice.fromJson({'a': 'a'}).toJson(), {'a': 'a'});" : "expect(() => api.Choice.fromJson({'a': 'a'}), throwsA(anything));"}
    expect(() => api.ExplicitChoice.fromJson({'tag': 't', 'a': 'a'}), throwsA(anything));
    expect(() => api.Choice.fromJson({}), throwsA(anything));
    expect(() => api.Choice.fromJson({'a': 'a', 'b': 'b'}), throwsA(anything));
  });
  """}
}
''';
}
