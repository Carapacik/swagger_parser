// ignore_for_file: unintended_html_in_doc_comment

/// Defines collections wrapping type
enum UniversalCollections {
  /// List collection: List<T>
  list,

  /// List collection with nullable items: List<T?>
  listNullableItem,

  /// Nullable List collection: List<T>?
  nullableList,

  /// Nullable List collection with nullable items: List<T?>?
  nullableListNullableItem,

  /// Map collection: Map<String, T>
  map,

  /// Map collection with nullable values: Map<String, T?>
  mapNullableValue,

  /// Nullable Map collection: Map<String, T>?
  nullableMap,

  /// Nullable Map collection with nullable values: Map<String, T?>?
  nullableMapNullableValue;

  /// Returns String representation of collection prefix, e.g., "List<" or "Map<String, ".
  String get collectionPrefix => switch (this) {
        UniversalCollections.list ||
        UniversalCollections.listNullableItem ||
        UniversalCollections.nullableList ||
        UniversalCollections.nullableListNullableItem =>
          'List<',
        UniversalCollections.map ||
        UniversalCollections.mapNullableValue ||
        UniversalCollections.nullableMap ||
        UniversalCollections.nullableMapNullableValue =>
          'Map<String, ',
      };

  /// Returns question mark for the collection itself if it's nullable, otherwise empty string.
  /// E.g., for List<T>?, this returns "?".
  String get collectionSuffixQuestionMark => switch (this) {
        UniversalCollections.nullableList ||
        UniversalCollections.nullableListNullableItem ||
        UniversalCollections.nullableMap ||
        UniversalCollections.nullableMapNullableValue =>
          '?',
        _ => '',
      };

  /// Indicates if the items (for lists) or values (for maps) within the collection are nullable.
  /// E.g., for List<T?>, this returns true.
  bool get itemIsNullable => switch (this) {
        UniversalCollections.listNullableItem ||
        UniversalCollections.nullableListNullableItem ||
        UniversalCollections.mapNullableValue ||
        UniversalCollections.nullableMapNullableValue =>
          true,
        _ => false,
      };
}
