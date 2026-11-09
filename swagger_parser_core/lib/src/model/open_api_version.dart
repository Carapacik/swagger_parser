/// The specification family that defines a document's structure.
enum OpenApiFamily() {
  /// Swagger 2.0 documents.
  swaggerV2,

  /// OpenAPI 3.0.x documents.
  v30,

  /// OpenAPI 3.1.x documents.
  v31,

  /// OpenAPI 3.2.x documents.
  v32,
}

/// Feature family and the exact version declared in the source document.
final class const OpenApiVersion({
  /// The major or minor specification family used for parsing.
  required final OpenApiFamily family,

  /// Exact version string from `swagger` or `openapi`.
  required final String value,
}) {
  /// Pairs the parsed family with the original version string.
  this;
}
