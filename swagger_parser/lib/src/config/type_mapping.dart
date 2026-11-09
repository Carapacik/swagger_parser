/// Replaces a scalar or object schema with an imported Dart type.
///
/// Select [schema] or an exact [type] and [format] pair.
/// Schema selectors take precedence. Duplicate selector/direction pairs fail.
final class const TypeMapping({
  /// Public Dart class name. Naming rules do not change this name.
  required final String dartType,

  /// Absolute package or Dart import URI for [dartType].
  required final String importUrl,

  /// Non-null JSON conversion functions.
  required final TypeMappingCodec codec,

  /// Mapping direction. Defaults to both.
  /// Specific directions override both for the same selector.
  final TypeMappingDirection direction = TypeMappingDirection.both,

  /// Constant representations of schema defaults. Empty by default.
  final List<TypeMappingDefault> defaults = const [],

  /// Schema URI resolved against the entry document.
  final String? schema,

  /// OpenAPI scalar type. Use with [format].
  final String? type,

  /// Exact OpenAPI format. Use with [type].
  final String? format,
}) {
  /// Defines a replacement. Object mappings require [schema].
  this;
}

/// Public synchronous functions that convert non-null JSON values.
final class const TypeMappingCodec({
  /// Absolute package or Dart import URI for both functions.
  required final String importUrl,

  /// Function from the JSON value to the custom Dart type.
  required final String fromJson,

  /// Function from the custom Dart type to the JSON value.
  required final String toJson,
}) {
  /// Defines a codec. Consumer analysis checks function signatures.
  this;
}

/// An imported constant for one JSON schema default.
final class const TypeMappingDefault({
  /// JSON value matched by structure. Object key order has no effect.
  required final Object? value,

  /// Absolute package or Dart import URI for [constant].
  required final String importUrl,

  /// Public top-level const identifier. Expressions are not accepted.
  required final String constant,
}) {
  /// Defines a constant. Consumer analysis checks its type and constness.
  this;
}

/// Selects the request or response use of a schema.
enum TypeMappingDirection() {
  /// Applies to both directions. Object shapes must match.
  both,

  /// Applies to request bodies and parameters.
  request,

  /// Applies to response payloads.
  response,
}
