import 'package:dart_mappable/dart_mappable.dart';

import 'sample_code.dart';

part 'sample_code_list.mapper.dart';

@MappableClass(
  hook: _WireCodec(SampleCodeList._fromWire),
  generateMethods: GenerateMethods.all & ~GenerateMethods.encode,
)
class SampleCodeList with SampleCodeListMappable implements _WireObject {
  const SampleCodeList({
    required this.sampleCodes,
    this.additionalProperties = const {},
  });

  factory SampleCodeList._fromWire(Map<String, Object?> json) => SampleCodeList(
    sampleCodes: (json["sampleCodes"] as List<Object?>)
        .map((item) => SampleCode.fromJson(item))
        .toList(),
    additionalProperties: {
      for (final entry in json.entries)
        if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    },
  );

  factory SampleCodeList.fromJson(Map<String, Object?> json) =>
      SampleCodeListMapper.fromMap(json);

  final List<SampleCode> sampleCodes;

  static const _knownKeys = <String>{"sampleCodes"};

  final Map<String, Object?> additionalProperties;

  Map<String, Object?> _toWire() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    "sampleCodes": this.sampleCodes.map((item) => item.toJson()).toList(),
  };

  Map<String, Object?> toJson() => toMap();

  Map<String, Object?> toMap() =>
      SampleCodeListMapper.ensureInitialized().encodeMap<SampleCodeList>(this);
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
