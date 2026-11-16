import 'package:json_annotation/json_annotation.dart';

import 'sample_code.dart';
import 'string_code.dart';

part 'sample_record.g.dart';

@JsonSerializable(
  explicitToJson: true,
  includeIfNull: true,
  disallowUnrecognizedKeys: false,
)
class SampleRecord {
  const SampleRecord({
    required this.code,
    required this.stringCode,
    required this.optionalCode,
    this.nullableCodes,
    this.nestedNullableCodes,
    this.nullableCodeMap,
    this.additionalProperties = const {},
  });

  factory SampleRecord.fromJson(Map<String, Object?> json) =>
      _$SampleRecordFromJson(json);

  @JsonKey(
    required: true,
    disallowNullValue: true,
    fromJson: SampleRecord._read_code,
    toJson: SampleRecord._write_code,
  )
  final SampleCode code;

  @JsonKey(
    required: true,
    disallowNullValue: true,
    fromJson: SampleRecord._read_stringCode,
    toJson: SampleRecord._write_stringCode,
  )
  final StringCode stringCode;

  @JsonKey(
    required: true,
    fromJson: SampleRecord._read_optionalCode,
    toJson: SampleRecord._write_optionalCode,
  )
  final SampleCode? optionalCode;

  @JsonKey(
    disallowNullValue: true,
    includeIfNull: false,
    fromJson: SampleRecord._read_nullableCodes,
    toJson: SampleRecord._write_nullableCodes,
  )
  final List<SampleCode?>? nullableCodes;

  @JsonKey(
    disallowNullValue: true,
    includeIfNull: false,
    fromJson: SampleRecord._read_nestedNullableCodes,
    toJson: SampleRecord._write_nestedNullableCodes,
  )
  final List<List<SampleCode?>>? nestedNullableCodes;

  @JsonKey(
    disallowNullValue: true,
    includeIfNull: false,
    fromJson: SampleRecord._read_nullableCodeMap,
    toJson: SampleRecord._write_nullableCodeMap,
  )
  final Map<String, SampleCode?>? nullableCodeMap;

  static const _knownKeys = <String>{
    "code",
    "stringCode",
    "optionalCode",
    "nullableCodes",
    "nestedNullableCodes",
    "nullableCodeMap",
  };

  @JsonKey(
    readValue: SampleRecord._extras,
    fromJson: SampleRecord._readExtras,
    includeToJson: false,
  )
  final Map<String, Object?> additionalProperties;

  static SampleCode _read_code(Object? value) => SampleCode.fromJson(value);

  static Object? _write_code(SampleCode value) => value.toJson();

  static StringCode _read_stringCode(Object? value) =>
      StringCode.fromJson(value);

  static Object? _write_stringCode(StringCode value) => value.toJson();

  static SampleCode? _read_optionalCode(Object? value) =>
      value == null ? null : SampleCode.tryFromJson(value);

  static Object? _write_optionalCode(SampleCode? value) => value?.toJson();

  static List<SampleCode?>? _read_nullableCodes(Object? value) => value == null
      ? null
      : (value as List<Object?>)
            .map((item) => item == null ? null : SampleCode.tryFromJson(item))
            .toList();

  static Object? _write_nullableCodes(List<SampleCode?>? value) =>
      value?.map((item) => item?.toJson()).toList();

  static List<List<SampleCode?>>? _read_nestedNullableCodes(Object? value) =>
      value == null
      ? null
      : (value as List<Object?>)
            .map(
              (item) => (item as List<Object?>)
                  .map(
                    (item) =>
                        item == null ? null : SampleCode.tryFromJson(item),
                  )
                  .toList(),
            )
            .toList();

  static Object? _write_nestedNullableCodes(List<List<SampleCode?>>? value) =>
      value
          ?.map((item) => item.map((item) => item?.toJson()).toList())
          .toList();

  static Map<String, SampleCode?>? _read_nullableCodeMap(Object? value) =>
      value == null
      ? null
      : (value as Map<String, Object?>).map(
          (key, item) =>
              MapEntry(key, item == null ? null : SampleCode.tryFromJson(item)),
        );

  static Object? _write_nullableCodeMap(Map<String, SampleCode?>? value) =>
      value?.map((key, item) => MapEntry(key, item?.toJson()));

  static Object? _extras(Map map, String _) => {
    for (final entry in map.entries)
      if (!_knownKeys.contains(entry.key)) entry.key as String: entry.value,
  };

  static Map<String, Object?> _readExtras(Object? value) =>
      (value as Map<String, Object?>).map((key, item) => MapEntry(key, item));

  Map<String, Object?> toJson() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    ..._$SampleRecordToJson(this),
  };
}
