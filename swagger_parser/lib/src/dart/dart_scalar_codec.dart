part of 'dart_generation_model.dart';

/// Resolved imports, wire type, and predicates for a mapped schema.
final class DartScalarCodec({
  /// Public Dart type name without an import prefix.
  required final String dartType,

  /// Dart type of the non-null JSON value.
  required final String wireType,

  /// Type import URI.
  required final String typeImport,

  /// Type import prefix.
  required final String typePrefix,

  /// Codec import URI.
  required final String codecImport,

  /// Codec import prefix.
  required final String codecPrefix,

  /// Public decoder function.
  required final String fromJson,

  /// Public encoder function.
  required final String toJson,

  /// Private adapter stem, unique within the generation result.
  required final String adapter,

  /// Raw JSON predicate.
  required final String matcher,

  /// Predicates required by [matcher].
  required final List<DartSchemaMatcher> matchers,

  /// Supported parameter expansion for an object. Null disables expansion.
  final DartParameterObjectShape? parameterObjectShape,

  /// Constant representations of schema defaults.
  final List<DartMappedDefault> defaults = const [],

  /// Non-null enum or const values. Empty means no finite set.
  final List<Object> allowedValues = const [],
}) {
  /// Stores one schema use and its codec.
  this;
}

/// An allocated constant expression for one mapped JSON default.
final class const DartMappedDefault(
  /// Immutable JSON value.
  final JsonValue value,

  /// Qualified Dart constant identifier.
  final String expression,
) {
  /// Stores the wire value and its constant expression.
  this;
}
