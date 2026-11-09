import 'dart:io';

/// Returns the absolute file URI for a local path.
Uri fileUri(String path) => File(path).absolute.uri;

/// Reads the bytes at a local file URI.
Future<List<int>> readFile(Uri uri) => File.fromUri(uri).readAsBytes();
