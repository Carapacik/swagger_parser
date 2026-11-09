/// Selects outbound operations. Named schemas remain available.
final class const OperationFilterConfig({
  /// Path patterns to include. Null includes all; an empty list includes none.
  final List<String>? includePaths,

  /// Path patterns to exclude. Exclusions take priority over inclusions.
  final List<String> excludePaths = const [],

  /// Exact tags to include. Null includes all; an empty list includes none.
  final List<String>? includeTags,

  /// Exact tags to exclude. Checks all operation tags, with case preserved.
  final List<String> excludeTags = const [],
}) {
  /// Combines path and tag includes with AND. Entries within each list use OR.
  ///
  /// Paths start with `/`. `*` matches one non-empty segment. `**` matches
  /// zero or more segments. Wildcards must occupy a complete segment.
  /// The mapper rejects invalid patterns with a `GenerationException`.
  this;

  /// Reports whether a pattern uses a leading slash and whole-segment globs.
  static bool isValidPathPattern(String pattern) =>
      pattern.startsWith('/') &&
      pattern
          .split('/')
          .every(
            (segment) =>
                !segment.contains('*') || segment == '*' || segment == '**',
          );
}
