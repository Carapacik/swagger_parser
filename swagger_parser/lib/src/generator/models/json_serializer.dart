import 'package:collection/collection.dart';

/// Used for select json serializer for dto
enum JsonSerializer {
  /// https://pub.dev/packages/json_serializable
  jsonSerializable('json_serializable'),

  /// https://pub.dev/packages/freezed
  freezed('freezed'),

  /// https://pub.dev/packages/dart_mappable
  dartMappable('dart_mappable');

  /// Constructor
  const JsonSerializer(this.packageName);

  /// Package name
  final String packageName;

  /// Returns [JsonSerializer] from string
  static JsonSerializer? fromString(String value) => values.firstWhereOrNull(
        (e) => e.packageName == value,
      );
}
