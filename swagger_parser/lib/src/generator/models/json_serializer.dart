import 'package:collection/collection.dart';

enum JsonSerializer {
  json_serializable,

  freezed;

  /// Returns [JsonSerializer] from string
  static JsonSerializer? fromString(String string) => values.firstWhereOrNull(
        (e) => e.name == string,
      );
}
