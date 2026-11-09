import 'package:swagger_parser_core/src/source/source_location.dart';

/// An input failure with optional source coordinates.
class const OpenApiException(
  /// Human-readable diagnostic message.
  final String message, {

  /// URI of the source document, when available.
  final Uri? sourceUri,

  /// JSON Pointer to the affected value.
  final String? documentPath,

  /// Underlying error, when available.
  final Object? cause,

  /// Line, column, and offset when the decoder can locate the error.
  final SourceLocation? location,
}) implements Exception {
  /// Records an input failure and its available source coordinates.
  this;

  @override
  String toString() =>
      'OpenApiException: $message'
      '${sourceUri == null ? '' : ' ($sourceUri)'}'
      '${documentPath == null ? '' : ' at $documentPath'}'
      '${location == null ? '' : ' (${location!.line}:${location!.column})'}';
}

/// A syntax or structural error in the input document.
final class const SchemaParseException(
  super.message, {
  super.sourceUri,
  super.documentPath,
  super.cause,
  super.location,
}) extends OpenApiException {
  /// Records a decoding or structural error at its source position.
  this;
}

/// The declared specification version has no parser.
final class const UnsupportedOpenApiVersionException(
  super.message, {
  super.sourceUri,
  super.documentPath,
  super.location,
}) extends OpenApiException {
  /// Records the unsupported version error at the version field.
  this;
}

/// A reference, resource identifier, or external document could not be resolved.
final class const ReferenceResolutionException(
  /// Stable identifier for the resolution failure.
  final String code,
  super.message, {
  super.sourceUri,
  super.documentPath,
  super.cause,
}) extends OpenApiException {
  /// Records the source field and the underlying load or format error.
  this;
}
