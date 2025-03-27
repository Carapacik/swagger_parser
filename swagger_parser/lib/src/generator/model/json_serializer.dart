/// Used for select json serializer for dto
enum JsonSerializer {
  /// https://pub.dev/packages/json_serializable
  jsonSerializable('json_serializable'),

  /// https://pub.dev/packages/freezed
  freezed('freezed'),
  freezed3('freezed', 3),

  /// https://pub.dev/packages/dart_mappable
  dartMappable('dart_mappable');

  /// Constructor
  const JsonSerializer(this.packageName, [this.packageMajorVersion]);

  /// Returns [JsonSerializer] from string
  factory JsonSerializer.fromString(String value) => values.firstWhere(
        (e) => e.packageName == value,
        orElse: () => throw ArgumentError(
          "'$value' must be contained in ${JsonSerializer.values.map((e) => e.packageName)}",
        ),
      );

  /// Package name
  final String packageName;

  /// Major version of the package
  final int? packageMajorVersion;
}
