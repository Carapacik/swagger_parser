import 'package:collection/collection.dart';

enum JsonSerializer {
  jsonSerializable('json_serializable'),
  freezed('freezed'),
  dartMappable('dart_mappable');

  const JsonSerializer(this.name);

  final String name;

  /// Returns [JsonSerializer] from string
  static JsonSerializer? fromString(String string) => values.firstWhereOrNull(
        (e) => e.name == string,
      );
}
