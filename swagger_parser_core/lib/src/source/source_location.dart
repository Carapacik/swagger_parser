/// One-based line/column and zero-based UTF-16 offset in the source text.
final class const SourceLocation({
  /// One-based line number.
  required final int line,

  /// One-based column number.
  required final int column,

  /// Zero-based UTF-16 offset.
  required final int offset,
}) {
  /// Pairs a line and column with an offset into the source text.
  this;
}
