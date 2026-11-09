/// Checks boolean values, constrained enums, and unchanged union branches.
String booleanEnumsDriver(String folder, String version, String value) {
  final bool modern = version == 'v3_1' || version == 'v3_2';
  return '''
import 'dart:convert';
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  final input = jsonDecode(r\'''$value\''') as Map<String, dynamic>;
  ${modern ? "input.addAll({'constTrue': true, 'constFalse': false});" : ''}
  test('uses bool fields, collections, defaults, and named wrappers', () {
    final settings = api.Settings.fromJson(input);
    final bool enabled = settings.enabled;
    final bool reversed = settings.reversed;
    final bool inferred = settings.inferred;
    final bool? nullable = settings.nullable;
    final List<bool> flags = settings.flags;
    final Map<String, bool> byName = settings.byName;
    expect(enabled, true);
    expect(reversed, false);
    expect(inferred, true);
    expect(nullable, null);
    expect(flags, [true, false]);
    expect(byName, {'a': true, 'b': false});
    expect(settings.defaulted, false);
    expect(settings.notNullable, true);
    expect(() => api.Settings.fromJson({...input, 'notNullable': null}), throwsA(anything));
    expect(settings.optional, null);
    expect(settings.named.value, false);
    expect(api.Flag.fromJson(true).value, true);
    expect(api.NullableFlag.fromJson(null).value, null);
    expect(() => api.Flag.fromJson(null), throwsA(anything));
    expect(() => api.Flag.fromJson('true'), throwsA(anything));
    expect(settings.namedCases, api.SettingsNamedCases.enabled);
    expect(settings.varNames, api.SettingsVarNames.off);
    expect(settings.bothNames, api.SettingsBothNames.yes);
    expect(settings.toJson(), {...input, 'defaulted': false});
    expect(api.Settings.fromJson({...input, 'enabled': false, 'reversed': true}).enabled, false);
  });
  test('preserves missing, null, and false', () {
    for (final Object? value in [null, false, true]) {
      final settings = api.Settings.fromJson({...input, 'optional': value, 'nullable': value, 'defaulted': value});
      expect(settings.optional, (value: value));
      expect(settings.nullable, value);
      expect(settings.defaulted, value);
      expect(settings.toJson(), {...input, 'optional': value, 'nullable': value, 'defaulted': value});
    }
  });
  test('rejects values outside constrained enums', () {
    for (final Object? value in [null, 'true', 1]) {
      expect(() => api.Settings.fromJson({...input, 'enabled': value}), throwsA(anything));
    }
    expect(() => api.Settings.fromJson({...input, 'onlyTrue': false}), throwsA(anything));
    expect(() => api.Settings.fromJson({...input, 'onlyFalse': true}), throwsA(anything));
    ${modern ? """
    expect(() => api.Settings.fromJson({...input, 'constTrue': false}), throwsA(anything));
    expect(() => api.Settings.fromJson({...input, 'constFalse': true}), throwsA(anything));
    """ : ''}
  });
  ${version != 'v2' ? """
  test('keeps union branches and their constraints', () {
    expect(api.TrueOrNull.fromJson(true).toJson(), true);
    expect(api.TrueOrNull.fromJson(null).toJson(), null);
    expect(() => api.TrueOrNull.fromJson(false), throwsA(anything));
    expect(() => api.TrueOrNull.fromJson(1), throwsA(anything));
    expect(api.OneBoolean.fromJson(false).toJson(), false);
    expect(() => api.OneBoolean.fromJson(true), throwsA(anything));
    expect(api.AnyBoolean.fromJson(true).toJson(), true);
    expect(api.AnyBoolean.fromJson(false).toJson(), false);
    expect(api.AnyBoolean.fromJson('other').toJson(), 'other');
    ${modern ? """
    expect(() => api.TrueOrNull.fromJson('true'), throwsA(anything));
    expect(api.ConstChoice.fromJson(true).toJson(), true);
    expect(api.ConstChoice.fromJson(false).toJson(), false);
    expect(() => api.ConstChoice.fromJson(null), throwsA(anything));
    """ : ''}
  });
  """ : ''}
}
''';
}
