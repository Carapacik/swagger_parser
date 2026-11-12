import 'package:json_annotation/json_annotation.dart';

import 'sample_code.dart';

part 'sample_code_list.g.dart';

@JsonSerializable(
  explicitToJson: true,
  includeIfNull: true,
  disallowUnrecognizedKeys: false,
)
class SampleCodeList {
  const SampleCodeList({
    required this.sampleCodes,
    this.additionalProperties = const {},
  });

  factory SampleCodeList.fromJson(Map<String, Object?> json) =>
      _$SampleCodeListFromJson(json);

  @JsonKey(
    required: true,
    disallowNullValue: true,
    fromJson: SampleCodeList._read_sampleCodes,
    toJson: SampleCodeList._write_sampleCodes,
  )
  final List<SampleCode> sampleCodes;

  static const _knownKeys = <String>{"sampleCodes"};

  @JsonKey(
    readValue: SampleCodeList._extras,
    fromJson: SampleCodeList._readExtras,
    includeToJson: false,
  )
  final Map<String, Object?> additionalProperties;

  static List<SampleCode> _read_sampleCodes(Object? value) =>
      (value as List<Object?>)
          .map((item) => SampleCode.fromJson(item))
          .toList();

  static Object? _write_sampleCodes(List<SampleCode> value) =>
      value.map((item) => item.toJson()).toList();

  static Object? _extras(Map map, String _) => {
    for (final entry in map.entries)
      if (!_knownKeys.contains(entry.key)) entry.key as String: entry.value,
  };

  static Map<String, Object?> _readExtras(Object? value) =>
      (value as Map<String, Object?>).map((key, item) => MapEntry(key, item));

  Map<String, Object?> toJson() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    ..._$SampleCodeListToJson(this),
  };
}
