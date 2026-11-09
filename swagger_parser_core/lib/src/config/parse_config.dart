/// Controls source positions, unknown fields, and nesting depth.
final class const ParseConfig({
  /// Whether to record source coordinates for diagnostics.
  final bool captureSourceLocations = true,

  /// Policy for unknown keys on fixed-field objects. Extensions are exempt.
  final UnknownFieldPolicy unknownFields = UnknownFieldPolicy.preserve,

  /// Maximum nesting depth, including extensions. Must be positive.
  final int maxDepth = 128,
}) {
  /// Captures positions and preserves unknown fields by default.
  this;
}

/// How the parser handles unknown fields on fixed-field objects.
enum UnknownFieldPolicy() {
  /// Keep unknown fields for JSON export.
  preserve,

  /// Stop at the first unknown field.
  reject,
}
