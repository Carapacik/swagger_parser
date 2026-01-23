/// Checks if the given [path] matches any of the provided [patterns].
/// Supports wildcard patterns:
/// - * matches any characters except forward slashes (one path segment)
/// - ** matches any characters including forward slashes
///
/// Some examples:
/// - 'some/concrete/path/{id}' matches 'some/concrete/path/{id}'
/// - `/users/*/update` matches `/users/{id}/update`
/// - `/another/wildcard/*` matches `/another/wildcard/path`
/// - `/another/wildcard/**` matches `/another/wildcard/long/path`
/// - `path/**/parts` matches `path/with/several/parts`
bool matchesPathPattern(String path, List<String> patterns) {
  const doubleStarStart = '__DOUBLE_STAR_START__';
  const doubleStarEnd = '__DOUBLE_STAR_END__';
  for (final pattern in patterns) {
    final processedPattern = pattern
        // Replace /** with end marker (to distinguish from single star)
        .replaceAll(
          '/**',
          doubleStarEnd,
        )
        // Replace ** with start marker (to distinguish from single star)
        .replaceAll(
          '**',
          doubleStarStart,
        );

    // Escape all regex special characters
    var escapedPattern = RegExp.escape(
      processedPattern,
    )
        // Replace end marker of double star with .*
        .replaceAll(
          doubleStarEnd,
          '.*',
        )
        // Replace with optional trailing slash with any (0+) characters
        .replaceAll(
          doubleStarStart,
          '(?:/.*)?',
        )
        // Replace * with one or more characters except /
        .replaceAll(
          r'\*',
          '([^/]+)',
        );

    // Special handling for patterns starting with * (but not **)
    // If pattern starts with *, but not with **, and path starts with /, add / at the beginning
    if (pattern.startsWith('*') &&
        !pattern.startsWith('**') &&
        path.startsWith('/')) {
      escapedPattern = '/$escapedPattern';
    }

    final regex = RegExp('^$escapedPattern\$');
    if (regex.hasMatch(path)) {
      return true;
    }
  }
  return false;
}
