enum StringCode {
  padded("0007", label: "padded-sample"),
  plain("7", label: "plain-sample");

  const StringCode(String this.wireValue, {required String this.label});

  factory StringCode.fromJson(Object? json) {
    if (json is! String) {
      throw ArgumentError.value(json, "StringCode");
    }
    return values.firstWhere(
      (item) => item.wireValue == json,
      orElse: () => throw ArgumentError.value(json, "StringCode"),
    );
  }

  final String wireValue;

  final String label;

  String toJson() => wireValue;

  static StringCode? tryFromJson(Object? json) {
    if (json is! String) return null;
    for (final value in values) {
      if (value.wireValue == json) return value;
    }
    return null;
  }
}
