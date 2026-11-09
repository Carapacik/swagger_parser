import 'package:swagger_parser_core/swagger_parser_core.dart';

/// A generation failure and its diagnostics.
final class GenerationException(
  /// Human-readable diagnostic message.
  final String message, {
  Iterable<Diagnostic> diagnostics = const [],
}) implements Exception {
  /// Records a failure with the diagnostics available at that point.
  this;

  /// Diagnostics collected during processing.
  final List<Diagnostic> diagnostics = List.unmodifiable(diagnostics);

  @override
  String toString() => 'GenerationException: $message';
}
