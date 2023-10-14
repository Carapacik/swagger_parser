import 'package:collection/collection.dart';

/// Enum for choosing schema source
enum PreferSchemaSource {
  /// Prefer remote schema from url
  url,

  /// Prefer local schema from file
  path;

  /// Returns [PreferSchemaSource] from string
  static PreferSchemaSource? fromString(String string) =>
      values.firstWhereOrNull(
        (e) => e.name == string,
      );
}
