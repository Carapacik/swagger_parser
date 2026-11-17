import 'package:swagger_parser/swagger_parser.dart';

/// Checks scalar assignments, integer literals, and unknown-value bounds.
String enumValueTypesDriver(String folder, UnknownValueMode mode) {
  final preserve = mode == UnknownValueMode.preserve;
  final suffix = preserve ? 'Value' : '';
  return '''
import 'dart:convert';
import 'package:test/test.dart';
import '$folder/api.dart' as api;

void main() {
  test('assigns enum fields and JSON results to their scalar types', () {
    final String role = api.Role$suffix.admin.value;
    final String roleJson = api.Role.admin.toJson();
    final int level = api.Level$suffix.low.value;
    final int levelJson = api.Level.low.toJson();
    final int integral = api.Integral$suffix.thousand.value;
    final int integralJson = api.Integral.fromJson(1000.0).toJson();
    final num whole = api.WholeNumber$suffix.low.value;
    final num wholeJson = api.WholeNumber.high.toJson();
    final num fraction = api.Fraction$suffix.high.value;
    final num fractionJson = api.Fraction.high.toJson();
    final bool flag = api.Flag$suffix.enabled.value;
    final bool flagJson = api.Flag.disabled.toJson();
    final ${preserve ? 'Object' : 'String'} inferredText = api.InferredText$suffix.first.value;
    final ${preserve ? 'Object' : 'String'} inferredTextJson = api.InferredText.first.toJson();
    final ${preserve ? 'Object' : 'int'} inferredInteger = api.InferredInteger$suffix.low.value;
    final ${preserve ? 'Object' : 'int'} inferredIntegerJson = api.InferredInteger.low.toJson();
    final ${preserve ? 'Object' : 'num'} inferredNumber = api.InferredNumber$suffix.high.value;
    final ${preserve ? 'Object' : 'num'} inferredNumberJson = api.InferredNumber.high.toJson();
    final ${preserve ? 'Object' : 'int'} inferredIntegral = api.InferredIntegral$suffix.thousand.value;
    final ${preserve ? 'Object' : 'int'} inferredIntegralJson = api.InferredIntegral.thousand.toJson();
    final Object mixed = api.Mixed$suffix.number.value;
    final Object mixedJson = api.Mixed.text.toJson();
    final num numeric = api.Numeric$suffix.high.value;
    final num numericJson = api.Numeric.low.toJson();
    final String nullable = api.Nullable$suffix.yes.value;
    final String nullableJson = api.Nullable.yes.toJson();
    expect([role, roleJson], ['admin', 'admin']);
    expect([level, levelJson], [1, 1]);
    expect([integral, integralJson], [1000, 1000]);
    expect([whole, wholeJson, fraction, fractionJson], [1, 2, 2.5, 2.5]);
    expect([flag, flagJson], [true, false]);
    expect([inferredText, inferredTextJson], ['first', 'first']);
    expect([inferredInteger, inferredIntegerJson], [1, 1]);
    expect([inferredNumber, inferredNumberJson], [2.5, 2.5]);
    expect([inferredIntegral, inferredIntegralJson], [1000, 1000]);
    expect([mixed, mixedJson], [1, 'one']);
    expect([numeric, numericJson], [2.5, 1]);
    expect([nullable, nullableJson], ['yes', 'yes']);
    expect(() => api.Level.fromJson('1'), throwsA(anything));
    expect(() => api.Integral.fromJson(1000.5), throwsA(anything));
    expect(() => api.Role.fromJson(1), throwsA(anything));
  });
  test('keeps nullable fields separate from non-null enum cases', () {
    final dto = api.Thing.fromJson({'role': 'admin', 'level': 1, 'nullable': null});
    final String role = dto.role.toJson();
    final int level = dto.level.toJson();
    expect([role, level, dto.nullable], ['admin', 1, null]);
    expect(jsonDecode(jsonEncode(dto)), {'role': 'admin', 'level': 1, 'nullable': null});
    final populated = api.Thing.fromJson({'role': 'staff', 'level': 2, 'nullable': 'yes'});
    final String? nullable = populated.nullable?.toJson();
    expect(nullable, 'yes');
  });
  test('retains the configured unknown-value behavior', () {
    ${preserve ? '''
    final String role = api.Role.fromJson('guest').toJson();
    final int integral = api.Integral.fromJson(2000.0).toJson();
    final num whole = api.WholeNumber.fromJson(2.5).toJson();
    final Object inferred = api.InferredInteger.fromJson('new type').toJson();
    expect([role, integral, whole, inferred], ['guest', 2000, 2.5, 'new type']);
    ''' : '''
    expect(() => api.Role.fromJson('guest'), throwsA(anything));
    expect(() => api.Integral.fromJson(2000), throwsA(anything));
    expect(() => api.WholeNumber.fromJson(2.5), throwsA(anything));
    expect(() => api.InferredInteger.fromJson('new type'), throwsA(anything));
    '''}
  });
}
''';
}
