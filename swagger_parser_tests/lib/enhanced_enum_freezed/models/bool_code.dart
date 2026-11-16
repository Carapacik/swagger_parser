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
