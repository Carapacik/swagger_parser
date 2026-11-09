String scalarWireValuesDriver(String scenario, String folder, String wire) =>
    '''
import 'dart:convert';
import 'package:test/test.dart';
import '$folder/api.dart';

void main() {
  final wire = jsonDecode(r\'''$wire\''') as Map<String, dynamic>;
  ${switch (scenario) {
      'dates' => '''
  test('keeps calendar strings, aliases, defaults, and containers', () {
    final value = Schedule.fromJson(wire);
    expect(value.day.toJson(), '2024-02-29');
    expect(value.direct, '2024-03-01');
    expect(jsonDecode(jsonEncode(value.toJson())), wire);
    final missing = Schedule.fromJson({'dates': <Object?>[], 'by_name': <String,Object?>{}});
    expect(missing.day.toJson(), '2024-02-29');
    expect(missing.direct, '2024-03-01');
    expect(Schedule(dates: [], byName: {}).toJson(), missing.toJson());
    expect(jsonEncode(value.toJson()), isNot(contains('T00:00')));
  });
''',
      'int64' => r'''
  test('preserves int64 policy and exact decimal-string mappings', () {
    const js = identical(1, 1.0);
    final decimals = (wire['decimals'] as List).cast<String>();
    for (final digits in decimals) {
      final decoded = jsonDecode('{' + '"value":$digits,"alias":$digits,"values":[$digits],"exact":"$digits"}') as Map<String,dynamic>;
      final model = Numbers.fromJson(decoded);
      final int value = model.value;
      final exact = BigInt.parse(digits);
      expect(model.exact, exact);
      expect(model.alias.toJson(), value);
      final encoded = jsonDecode(jsonEncode(model.toJson())) as Map<String,dynamic>;
      expect(encoded['value'], isA<num>());
      expect(encoded['alias'], value);
      expect(encoded['values'], [value]);
      expect(encoded['exact'], digits);
      if (js && digits == '9007199254740993') {
        expect(BigInt.from(value), BigInt.parse('9007199254740992'));
      } else if (js && digits == '9223372036854775807') {
        expect(BigInt.from(value), BigInt.parse('9223372036854775808'));
      } else {
        expect(BigInt.from(value), exact);
      }
    }
  });
''',
      'discriminator_keys' => '''
  test('retains snake_case and protected keys in nested variants', () {
    final value = Container.fromJson(wire);
    expect(value.entry, isA<Rail>());
    expect(value.entries.last, isA<Bus>());
    final rail = value.entry as Rail;
    expect(rail.isActive, isTrue);
    expect(rail.fileName, 'north.bin');
    expect(rail.toJson()['class'], 'first');
    expect(value.byName['bus'], isA<Bus>());
    final encoded = jsonDecode(jsonEncode(value.toJson()));
    expect(encoded, wire);
    final source = jsonEncode(encoded);
    expect(source, isNot(contains('isActive')));
    expect(source, isNot(contains('fileName')));
    expect(source, isNot(contains('class2')));
    expect(source, isNot(contains('switch2')));
  });
''',
      _ => throw ArgumentError.value(scenario),
    }}
}
''';
