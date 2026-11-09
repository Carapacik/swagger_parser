import 'package:swagger_parser/src/output/generated_file.dart';
import 'package:swagger_parser_core/swagger_parser_core.dart';

/// Generated files and diagnostics from one run.
final class GenerationResult({
  required Iterable<GeneratedFile> files,
  Iterable<Diagnostic> diagnostics = const [],
}) {
  /// Collects files and diagnostics. Each output path must be unique.
  this {
    final paths = <String>{};
    for (final GeneratedFile file in this.files) {
      if (!paths.add(file.relativePath)) {
        throw ArgumentError('Duplicate generated path: ${file.relativePath}');
      }
    }
  }

  /// Files in output order.
  final List<GeneratedFile> files = List.unmodifiable(files);

  /// Diagnostics collected during processing.
  final List<Diagnostic> diagnostics = List.unmodifiable(diagnostics);
}
