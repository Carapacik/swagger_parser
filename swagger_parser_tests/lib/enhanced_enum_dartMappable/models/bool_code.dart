import 'package:dart_mappable/dart_mappable.dart';

enum BoolCode {
  enabled(true, weight: 1.0, selectable: true),
  disabled(false, weight: 1.5, selectable: false);

  const BoolCode(
    bool this.wireValue, {
    required double this.weight,
    required bool this.selectable,
  });

  factory BoolCode.fromJson(Object? json) {
    if (json is! bool) {
      throw ArgumentError.value(json, "BoolCode");
    }
    return values.firstWhere(
      (item) => item.wireValue == json,
      orElse: () => throw ArgumentError.value(json, "BoolCode"),
    );
  }

  final bool wireValue;

  final double weight;

  final bool selectable;

  bool toJson() => wireValue;

  static BoolCode? tryFromJson(Object? json) {
    if (json is! bool) return null;
    for (final value in values) {
      if (value.wireValue == json) return value;
    }
    return null;
  }
}

class BoolCodeMapper extends EnumMapper<BoolCode> {
  BoolCodeMapper._();

  static BoolCodeMapper? _instance;
  static BoolCodeMapper ensureInitialized() {
    if (_instance == null) {
      MapperContainer.globals.use(_instance = BoolCodeMapper._());
    }
    return _instance!;
  }

  static BoolCode fromValue(dynamic value) {
    ensureInitialized();
    return MapperContainer.globals.fromValue(value);
  }

  @override
  BoolCode decode(dynamic value) => BoolCode.fromJson(value);

  @override
  dynamic encode(BoolCode self) => self.wireValue;
}

extension BoolCodeMapperExtension on BoolCode {
  dynamic toValue() {
    BoolCodeMapper.ensureInitialized();
    return MapperContainer.globals.toValue<BoolCode>(this);
  }
}
