class Problem {
  const Problem({required this.detail, this.additionalProperties = const {}});

  factory Problem.fromJson(Map<String, Object?> json) => Problem(
    detail: json["detail"] as String,
    additionalProperties: {
      for (final entry in json.entries)
        if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    },
  );

  final String detail;

  static const _knownKeys = <String>{"detail"};

  final Map<String, Object?> additionalProperties;

  Map<String, Object?> toJson() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    "detail": this.detail,
  };
}
