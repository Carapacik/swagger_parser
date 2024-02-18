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
  const JsonSerializer(this.value);

  /// Package name
  final String value;

  /// Returns [JsonSerializer] from string
  static JsonSerializer? fromString(String value) => values.firstWhereOrNull(
        (e) => e.value == value,
      );
}
