import 'package:dart_mappable/dart_mappable.dart';

import 'sample_code.dart';
import 'string_code.dart';

part 'sample_record.mapper.dart';

@MappableClass(
  hook: _WireCodec(SampleRecord._fromWire),
  generateMethods: GenerateMethods.all & ~GenerateMethods.encode,
)
class SampleRecord with SampleRecordMappable implements _WireObject {
  const SampleRecord({
    required this.code,
    required this.stringCode,
    required this.optionalCode,
    this.nullableCodes,
    this.nestedNullableCodes,
    this.nullableCodeMap,
    this.additionalProperties = const {},
  });

  factory SampleRecord._fromWire(Map<String, Object?> json) {
    if (!json.containsKey("optionalCode")) {
      throw ArgumentError("Missing required property: optionalCode");
    }
    return SampleRecord(
      code: SampleCode.fromJson(json["code"]),
      stringCode: StringCode.fromJson(json["stringCode"]),
      optionalCode: json["optionalCode"] == null
          ? null
          : SampleCode.tryFromJson(json["optionalCode"]),
      nullableCodes: json.containsKey("nullableCodes")
          ? (json["nullableCodes"] as List<Object?>)
                .map(
                  (item) => item == null ? null : SampleCode.tryFromJson(item),
                )
                .toList()
          : null,
      nestedNullableCodes: json.containsKey("nestedNullableCodes")
          ? (json["nestedNullableCodes"] as List<Object?>)
                .map(
                  (item) => (item as List<Object?>)
                      .map(
                        (item) =>
                            item == null ? null : SampleCode.tryFromJson(item),
                      )
                      .toList(),
                )
                .toList()
          : null,
      nullableCodeMap: json.containsKey("nullableCodeMap")
          ? (json["nullableCodeMap"] as Map<String, Object?>).map(
              (key, item) => MapEntry(
                key,
                item == null ? null : SampleCode.tryFromJson(item),
              ),
            )
          : null,
      additionalProperties: {
        for (final entry in json.entries)
          if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  factory SampleRecord.fromJson(Map<String, Object?> json) =>
      SampleRecordMapper.fromMap(json);

  final SampleCode code;

  final StringCode stringCode;

  final SampleCode? optionalCode;

  final List<SampleCode?>? nullableCodes;

  final List<List<SampleCode?>>? nestedNullableCodes;

  final Map<String, SampleCode?>? nullableCodeMap;

  static const _knownKeys = <String>{
    "code",
    "stringCode",
    "optionalCode",
    "nullableCodes",
    "nestedNullableCodes",
    "nullableCodeMap",
  };

  final Map<String, Object?> additionalProperties;

  Map<String, Object?> _toWire() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    "code": this.code.toJson(),
    "stringCode": this.stringCode.toJson(),
    "optionalCode": this.optionalCode?.toJson(),
    if (this.nullableCodes != null)
      "nullableCodes": this.nullableCodes
          ?.map((item) => item?.toJson())
          .toList(),
    if (this.nestedNullableCodes != null)
      "nestedNullableCodes": this.nestedNullableCodes
          ?.map((item) => item.map((item) => item?.toJson()).toList())
          .toList(),
    if (this.nullableCodeMap != null)
      "nullableCodeMap": this.nullableCodeMap?.map(
        (key, item) => MapEntry(key, item?.toJson()),
      ),
  };

  Map<String, Object?> toJson() => toMap();

  Map<String, Object?> toMap() =>
      SampleRecordMapper.ensureInitialized().encodeMap<SampleRecord>(this);
}

abstract interface class _WireObject {
  Map<String, Object?> _toWire();
}

class _WireCodec extends MappingHook {
  const _WireCodec(this.read);
  final _WireObject Function(Map<String, Object?>) read;

  @override
  Object? beforeDecode(Object? value) => read(value as Map<String, Object?>);

  @override
  Object? beforeEncode(Object? value) => (value as _WireObject)._toWire();
}
