/// Defines collections wrapping type
enum UniversalCollections {
  /// Map collection
  map,

  /// List collection
  list;

  /// Creates a [UniversalCollections]
  const UniversalCollections();

  /// Returns String representation of collection
  String get collectionsString {
    return switch (this) {
      UniversalCollections.list => 'List<',
      UniversalCollections.map => 'Map<String, '
    };
  }
}
