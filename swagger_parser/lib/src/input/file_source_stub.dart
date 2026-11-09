/// Throws [UnsupportedError] on platforms without Dart I/O.
Uri fileUri(String path) =>
    throw UnsupportedError('File input requires Dart I/O.');

/// Throws [UnsupportedError] on platforms without Dart I/O.
Future<List<int>> readFile(Uri uri) async =>
    throw UnsupportedError('File input requires Dart I/O.');
