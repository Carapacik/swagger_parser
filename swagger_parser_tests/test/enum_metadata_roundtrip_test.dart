import 'package:dart_mappable/dart_mappable.dart' as mappable;
import 'package:swagger_parser_tests/enhanced_enum_dartMappable/models/bool_code.dart'
    as mapped;
import 'package:swagger_parser_tests/enhanced_enum_dartMappable/models/sample_code.dart'
    as mapped;
import 'package:swagger_parser_tests/enhanced_enum_dartMappable/models/sample_code_list.dart'
    as mapped;
import 'package:swagger_parser_tests/enhanced_enum_dartMappable/models/sample_record.dart'
    as mapped;
import 'package:swagger_parser_tests/enhanced_enum_dartMappable/models/string_code.dart'
    as mapped;
import 'package:swagger_parser_tests/enhanced_enum_dartMappable/models/wide_sample_code.dart'
    as mapped;
import 'package:swagger_parser_tests/enhanced_enum_freezed/models/bool_code.dart'
    as freezed;
import 'package:swagger_parser_tests/enhanced_enum_freezed/models/sample_code.dart';
import 'package:swagger_parser_tests/enhanced_enum_freezed/models/sample_code_list.dart';
import 'package:swagger_parser_tests/enhanced_enum_freezed/models/sample_record.dart';
import 'package:swagger_parser_tests/enhanced_enum_freezed/models/string_code.dart';
import 'package:swagger_parser_tests/enhanced_enum_freezed/models/wide_sample_code.dart';
import 'package:swagger_parser_tests/enhanced_enum_jsonSerializable/models/bool_code.dart'
    as json_serializable;
import 'package:swagger_parser_tests/enhanced_enum_jsonSerializable/models/sample_code.dart'
    as json_serializable;
import 'package:swagger_parser_tests/enhanced_enum_jsonSerializable/models/sample_code_list.dart'
    as json_serializable;
import 'package:swagger_parser_tests/enhanced_enum_jsonSerializable/models/sample_record.dart'
    as json_serializable;
import 'package:swagger_parser_tests/enhanced_enum_jsonSerializable/models/string_code.dart'
    as json_serializable;
import 'package:swagger_parser_tests/enhanced_enum_jsonSerializable/models/wide_sample_code.dart'
    as json_serializable;
import 'package:swagger_parser_tests/enhanced_enum_plain/models/bool_code.dart'
    as plain;
import 'package:swagger_parser_tests/enhanced_enum_plain/models/sample_code.dart'
    as plain;
import 'package:swagger_parser_tests/enhanced_enum_plain/models/sample_code_list.dart'
    as plain;
import 'package:swagger_parser_tests/enhanced_enum_plain/models/sample_record.dart'
    as plain;
import 'package:swagger_parser_tests/enhanced_enum_plain/models/string_code.dart'
    as plain;
import 'package:swagger_parser_tests/enhanced_enum_plain/models/wide_sample_code.dart'
    as plain;
import 'package:test/test.dart';

void main() {
  test('Freezed round-trips enhanced enum values and metadata', () {
    final record = SampleRecord.fromJson({
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });

    expect(record.code, SampleCode.firstKind);
    expect(record.code.category, 'sample-a');
    expect(record.code.order, 10);
    expect(record.code.wireValue, 101);
    expect(record.optionalCode, SampleCode.secondKind);
    expect(record.stringCode, StringCode.padded);
    expect(record.stringCode.wireValue, '0007');
    expect(record.stringCode.label, 'padded-sample');
    expect(record.toJson(), {
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(WideSampleCode.field303.property18, 18);
  });

  test('plain serializer round-trips enhanced enums', () {
    final record = plain.SampleRecord.fromJson({
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(record.code, plain.SampleCode.firstKind);
    expect(record.code.category, 'sample-a');
    expect(record.code.order, 10);
    expect(record.toJson(), {
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(plain.WideSampleCode.field303.property18, 18);
  });

  test('json_serializable round-trips enhanced enums', () {
    final record = json_serializable.SampleRecord.fromJson({
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(record.code, json_serializable.SampleCode.firstKind);
    expect(record.code.category, 'sample-a');
    expect(record.code.order, 10);
    expect(record.toJson(), {
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(json_serializable.WideSampleCode.field303.property18, 18);
  });

  test('dart_mappable round-trips enhanced enums', () {
    final record = mapped.SampleRecord.fromJson({
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(record.code, mapped.SampleCode.firstKind);
    expect(record.code.category, 'sample-a');
    expect(record.code.order, 10);
    expect(record.toJson(), {
      'code': 101,
      'stringCode': '0007',
      'optionalCode': 202,
    });
    expect(mapped.WideSampleCode.field303.property18, 18);
  });

  test('dart_mappable direct mapper validates integer wire values', () {
    expect(mapped.SampleCodeMapper.fromValue(101), mapped.SampleCode.firstKind);
    expect(
      mapped.SampleCodeMapper.fromValue(202),
      mapped.SampleCode.secondKind,
    );
    // Fractional values stay doubles on web; integral doubles become ints there.
    expect(
      () => mapped.SampleCodeMapper.fromValue(101.5),
      throwsA(isA<mappable.MapperException>()),
    );
    expect(
      () => mapped.SampleCodeMapper.fromValue(909),
      throwsA(isA<mappable.MapperException>()),
    );
  });

  test('unknown non-nullable IDs throw instead of being retained', () {
    final data = {'code': 909, 'stringCode': '0007', 'optionalCode': null};
    expect(() => SampleRecord.fromJson(data), throwsA(anything));
    expect(() => plain.SampleRecord.fromJson(data), throwsA(anything));
    expect(
      () => json_serializable.SampleRecord.fromJson(data),
      throwsA(anything),
    );
    expect(() => mapped.SampleRecord.fromJson(data), throwsA(anything));
  });

  test('nullable unknown IDs become null across serializers', () {
    final data = {'code': 101, 'stringCode': '0007', 'optionalCode': 909};
    expect(SampleRecord.fromJson(data).optionalCode, isNull);
    expect(plain.SampleRecord.fromJson(data).optionalCode, isNull);
    expect(json_serializable.SampleRecord.fromJson(data).optionalCode, isNull);
    expect(mapped.SampleRecord.fromJson(data).optionalCode, isNull);
  });

  test('leading-zero strings remain distinct and unknown strings throw', () {
    expect(mapped.StringCode.fromJson('0007'), mapped.StringCode.padded);
    expect(
      json_serializable.StringCode.fromJson('7'),
      json_serializable.StringCode.plain,
    );
    expect(plain.StringCode.padded, isNot(plain.StringCode.plain));
    expect(() => mapped.StringCode.fromJson('009'), throwsA(anything));
    expect(StringCode.fromJson('0007'), StringCode.padded);
    expect(StringCode.fromJson('7'), StringCode.plain);
    expect(StringCode.padded, isNot(StringCode.plain));
    expect(() => StringCode.fromJson('009'), throwsA(anything));
  });

  test('unknown IDs in collections throw instead of being retained', () {
    final data = {
      'sampleCodes': [101, 909],
    };
    expect(() => SampleCodeList.fromJson(data), throwsA(anything));
    expect(() => plain.SampleCodeList.fromJson(data), throwsA(anything));
    expect(
      () => json_serializable.SampleCodeList.fromJson(data),
      throwsA(anything),
    );
    expect(() => mapped.SampleCodeList.fromJson(data), throwsA(anything));
  });

  test('nullable collection items decode unknown IDs across serializers', () {
    final data = {
      'code': 101,
      'stringCode': '0007',
      'optionalCode': null,
      'nullableCodes': [101, 909],
      'nestedNullableCodes': [
        [202, 909],
      ],
      'nullableCodeMap': {'known': 101, 'unknown': 909},
    };
    final freezed = SampleRecord.fromJson(data);
    expect(freezed.nullableCodes, [SampleCode.firstKind, null]);
    expect(freezed.nullableCodes!.first!.category, 'sample-a');
    expect(freezed.nestedNullableCodes, [
      [SampleCode.secondKind, null],
    ]);
    expect(freezed.nullableCodeMap, {
      'known': SampleCode.firstKind,
      'unknown': null,
    });
    expect(freezed.toJson()['nullableCodes'], [101, null]);
    expect(freezed.toJson()['nestedNullableCodes'], [
      [202, null],
    ]);
    expect(freezed.toJson()['nullableCodeMap'], {
      'known': 101,
      'unknown': null,
    });

    final plainRecord = plain.SampleRecord.fromJson(data);
    expect(plainRecord.nullableCodes, [plain.SampleCode.firstKind, null]);
    expect(plainRecord.nullableCodes!.first!.category, 'sample-a');
    expect(plainRecord.nestedNullableCodes, [
      [plain.SampleCode.secondKind, null],
    ]);
    expect(plainRecord.nullableCodeMap, {
      'known': plain.SampleCode.firstKind,
      'unknown': null,
    });
    expect(plainRecord.toJson()['nullableCodes'], [101, null]);
    expect(plainRecord.toJson()['nestedNullableCodes'], [
      [202, null],
    ]);
    expect(plainRecord.toJson()['nullableCodeMap'], {
      'known': 101,
      'unknown': null,
    });

    final jsonRecord = json_serializable.SampleRecord.fromJson(data);
    expect(jsonRecord.nullableCodes, [
      json_serializable.SampleCode.firstKind,
      null,
    ]);
    expect(jsonRecord.nullableCodes!.first!.category, 'sample-a');
    expect(jsonRecord.nestedNullableCodes, [
      [json_serializable.SampleCode.secondKind, null],
    ]);
    expect(jsonRecord.nullableCodeMap, {
      'known': json_serializable.SampleCode.firstKind,
      'unknown': null,
    });
    expect(jsonRecord.toJson()['nullableCodes'], [101, null]);
    expect(jsonRecord.toJson()['nestedNullableCodes'], [
      [202, null],
    ]);
    expect(jsonRecord.toJson()['nullableCodeMap'], {
      'known': 101,
      'unknown': null,
    });

    final mappedRecord = mapped.SampleRecord.fromJson(data);
    expect(mappedRecord.nullableCodes, [mapped.SampleCode.firstKind, null]);
    expect(mappedRecord.nullableCodes!.first!.category, 'sample-a');
    expect(mappedRecord.nestedNullableCodes, [
      [mapped.SampleCode.secondKind, null],
    ]);
    expect(mappedRecord.nullableCodeMap, {
      'known': mapped.SampleCode.firstKind,
      'unknown': null,
    });
    expect(mappedRecord.toJson()['nullableCodes'], [101, null]);
    expect(mappedRecord.toJson()['nestedNullableCodes'], [
      [202, null],
    ]);
    expect(mappedRecord.toJson()['nullableCodeMap'], {
      'known': 101,
      'unknown': null,
    });
  });

  test('boolean wire values and typed metadata round-trip', () {
    final freezedValue = freezed.BoolCode.fromJson(true);
    expect(freezedValue, freezed.BoolCode.enabled);
    expect(freezedValue.weight, 1.0);
    expect(freezedValue.selectable, isTrue);
    expect(freezedValue.toJson(), isTrue);
    expect(() => freezed.BoolCode.fromJson('true'), throwsA(anything));
    expect(() => freezed.BoolCode.fromJson(1), throwsA(anything));
    expect(freezed.BoolCode.fromJson(false), freezed.BoolCode.disabled);

    final plainValue = plain.BoolCode.fromJson(true);
    expect(plainValue.weight, 1.0);
    expect(plainValue.toJson(), isTrue);
    expect(() => plain.BoolCode.fromJson('true'), throwsA(anything));

    final jsonValue = json_serializable.BoolCode.fromJson(true);
    expect(jsonValue.selectable, isTrue);
    expect(jsonValue.toJson(), isTrue);
    expect(() => json_serializable.BoolCode.fromJson(1), throwsA(anything));

    final mappedValue = mapped.BoolCode.fromJson(true);
    expect(mappedValue.weight, 1.0);
    expect(mappedValue.toJson(), isTrue);
    expect(() => mapped.BoolCode.fromJson('true'), throwsA(anything));
  });

  test('integer enum codecs reject non-integer numeric IDs', () {
    // Fractional values stay doubles on web; integral doubles become ints there.
    final data = {'code': 101.5, 'stringCode': '0007', 'optionalCode': null};
    expect(() => SampleRecord.fromJson(data), throwsA(anything));
    expect(() => plain.SampleRecord.fromJson(data), throwsA(anything));
    expect(
      () => json_serializable.SampleRecord.fromJson(data),
      throwsA(anything),
    );
    expect(() => mapped.SampleRecord.fromJson(data), throwsA(anything));
  });
}
