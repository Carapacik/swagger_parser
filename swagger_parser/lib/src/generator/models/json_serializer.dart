import 'package:collection/collection.dart';

/// Used for select json serializer for dto
enum JsonSerializer {
  /// {@nodoc}
  jsonSerializable('json_serializable'),

  /// {@nodoc}
  freezed('freezed'),

  /// {@nodoc}
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
