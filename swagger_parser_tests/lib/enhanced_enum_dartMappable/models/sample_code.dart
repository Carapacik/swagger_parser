import 'package:dart_mappable/dart_mappable.dart';

enum SampleCode {
  firstKind(101, category: "sample-a", order: 10),
  secondKind(202, category: "sample-b", order: 20);

  const SampleCode(
    int this.wireValue, {
    required String this.category,
    required int this.order,
  });

  factory SampleCode.fromJson(Object? json) {
    if (json is! int) {
      throw ArgumentError.value(json, "SampleCode");
    }
    return values.firstWhere(
      (item) => item.wireValue == json,
      orElse: () => throw ArgumentError.value(json, "SampleCode"),
    );
  }

  final int wireValue;

  final String category;

  final int order;

  int toJson() => wireValue;

  static SampleCode? tryFromJson(Object? json) {
    if (json is! int) return null;
    for (final value in values) {
      if (value.wireValue == json) return value;
    }
    return null;
  }
}

class SampleCodeMapper extends EnumMapper<SampleCode> {
  SampleCodeMapper._();

  static SampleCodeMapper? _instance;
  static SampleCodeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = SampleCodeMapper._());
    }
    return _instance!;
  }

  static SampleCode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  SampleCode decode(dynamic value) => SampleCode.fromJson(value);

  @override
  dynamic encode(SampleCode self) => self.wireValue;
}

extension SampleCodeMapperExtension on SampleCode {
  dynamic toValue() {
    SampleCodeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<SampleCode>(this);
  }
}
