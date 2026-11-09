class Station {
  const Station({
    required this.id,
    this.parent,
    this.additionalProperties = const {},
  });

  factory Station.fromJson(Map<String, Object?> json) => Station(
    id: json["id"] as String,
    parent: json.containsKey("parent")
        ? Station.fromJson(json["parent"] as Map<String, Object?>)
        : null,
    additionalProperties: {
      for (final entry in json.entries)
        if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    },
  );

  final String id;

  final Station? parent;

  static const _knownKeys = <String>{"id", "parent"};

  final Map<String, Object?> additionalProperties;

  Map<String, Object?> toJson() => {
    for (final entry in additionalProperties.entries)
      if (!_knownKeys.contains(entry.key)) entry.key: entry.value,
    "id": this.id,
    if (this.parent != null) "parent": this.parent?.toJson(),
  };
}
