import 'package:swagger_parser_core/src/source/source_location.dart';

/// The effect of a diagnostic on processing.
enum DiagnosticSeverity() {
  /// Reports information about processing.
  info,

  /// Flags an issue that permits processing to continue.
  warning,

  /// Flags a failure that prevents generation.
  error,
}

/// A diagnostic message with a code and optional source position.
final class const Diagnostic({
  /// Machine-readable diagnostic identifier.
  required final String code,

  /// Human-readable diagnostic message.
  required final String message,

  /// Impact of this diagnostic on processing.
  required final DiagnosticSeverity severity,

  /// URI of the source document, when available.
  final Uri? sourceUri,

  /// JSON Pointer into the source document, when available.
  final String? documentPath,

  /// Source coordinates when the decoder recorded a position.
  final SourceLocation? location,
}) {
  /// Records a message with its severity and source context.
  this;
}
