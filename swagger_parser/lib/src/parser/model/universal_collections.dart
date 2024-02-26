enum UniversalCollections {
  map,
  list;

  String get collectionsString {
    return switch (this) {
      UniversalCollections.list => 'List<',
      UniversalCollections.map => 'Map<String, '
    };
  }
}
