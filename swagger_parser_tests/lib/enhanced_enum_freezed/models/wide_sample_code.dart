enum WideSampleCode {
  field303(
    303,
    property0: 0,
    property1: 1,
    property2: 2,
    property3: 3,
    property4: 4,
    property5: 5,
    property6: 6,
    property7: 7,
    property8: 8,
    property9: 9,
    property10: 10,
    property11: 11,
    property12: 12,
    property13: 13,
    property14: 14,
    property15: 15,
    property16: 16,
    property17: 17,
    property18: 18,
  );

  const WideSampleCode(
    int this.wireValue, {
    required int this.property0,
    required int this.property1,
    required int this.property2,
    required int this.property3,
    required int this.property4,
    required int this.property5,
    required int this.property6,
    required int this.property7,
    required int this.property8,
    required int this.property9,
    required int this.property10,
    required int this.property11,
    required int this.property12,
    required int this.property13,
    required int this.property14,
    required int this.property15,
    required int this.property16,
    required int this.property17,
    required int this.property18,
  });

  factory WideSampleCode.fromJson(Object? json) {
    if (json is! int) {
      throw ArgumentError.value(json, "WideSampleCode");
    }
    return values.firstWhere(
      (item) => item.wireValue == json,
      orElse: () => throw ArgumentError.value(json, "WideSampleCode"),
    );
  }

  final int wireValue;

  final int property0;

  final int property1;

  final int property2;

  final int property3;

  final int property4;

  final int property5;

  final int property6;

  final int property7;

  final int property8;

  final int property9;

  final int property10;

  final int property11;

  final int property12;

  final int property13;

  final int property14;

  final int property15;

  final int property16;

  final int property17;

  final int property18;

  int toJson() => wireValue;

  static WideSampleCode? tryFromJson(Object? json) {
    if (json is! int) return null;
    for (final value in values) {
      if (value.wireValue == json) return value;
    }
    return null;
  }
}
