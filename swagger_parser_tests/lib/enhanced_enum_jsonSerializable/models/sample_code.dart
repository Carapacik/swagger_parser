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
