/// Defines collections wrapping type
enum UniversalCollections {
  /// Map collection
  map,

  /// List collection
  list,

  /// Nullable Map collection
  nullableMap,

  /// Nullable List collection
  nullableList;

  /// Creates a [UniversalCollections]
  const UniversalCollections();

  /// Returns String representation of collection
  String get collectionsString {
    return switch (this) {
      UniversalCollections.list || UniversalCollections.nullableList => 'List<',
      UniversalCollections.map ||
      UniversalCollections.nullableMap =>
        'Map<String, '
    };
  }

  String get questionMark {
    return switch (this) {
      UniversalCollections.nullableList ||
      UniversalCollections.nullableMap =>
        '?',
      UniversalCollections.list || UniversalCollections.map => ''
    };
  }
}
