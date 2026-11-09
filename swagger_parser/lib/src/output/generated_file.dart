/// A file the caller can write to disk or add to an archive.
final class GeneratedFile({
  /// Relative POSIX path within the output directory or archive.
  required final String relativePath,

  /// Source text for this output file.
  required final String content,
}) {
  /// Pairs source text with a validated relative path.
  this {
    validateOutputPath(relativePath);
  }
}

/// Rejects paths that cannot safely represent an output within an archive.
void validateOutputPath(String path) {
  final List<String> segments = path.split('/');
  if (path.contains(r'\') ||
      path.contains(':') ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(path) ||
      segments.any(
        (segment) => segment.isEmpty || segment == '.' || segment == '..',
      )) {
    throw ArgumentError.value(
      path,
      'relativePath',
      'Expected a relative POSIX path',
    );
  }
}
