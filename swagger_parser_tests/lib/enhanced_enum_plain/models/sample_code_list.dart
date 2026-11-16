import 'sample_code.dart';

class SampleCodeList {
  const SampleCodeList({
    required this.sampleCodes,
    this.additionalProperties = const {},
  });

  factory SampleCodeList.fromJson(Map<String, Object?> json) => SampleCodeList(
    sampleCodes: (json["sampleCodes"] as List<Object?>)
        .map((item) => SampleCode.fromJson(item))
        .toList(),
    additionalProperties: {
      for (final entry in json.entries)
        if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    },
  );

  final List<SampleCode> sampleCodes;

  static const _knownKeys = <String>{"sampleCodes"};

  final Map<String, Object?> additionalProperties;

  Map<String, Object?> toJson() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    "sampleCodes": this.sampleCodes.map((item) => item.toJson()).toList(),
  };
}
