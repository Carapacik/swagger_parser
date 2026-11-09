import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// ZIP output and generation diagnostics.
final class const GenerationArchive(
  /// ZIP bytes. File paths are relative to the generator output root.
  final Uint8List bytes,

  /// Download filename.
  final String name,

  /// Number of generated files.
  final int fileCount,

  /// Validation and generation messages.
  final List<String> diagnostics,
) {
  /// Collects the downloadable output.
  this;

  /// Encodes every generated file with its original path and UTF-8 content.
  factory fromResult(GenerationResult result, String name) {
    final archive = Archive();
    for (final GeneratedFile file in result.files) {
      archive.addFile(ArchiveFile.string(file.relativePath, file.content));
    }
    return GenerationArchive(
      Uint8List.fromList(ZipEncoder().encode(archive)),
      name,
      result.files.length,
      List.unmodifiable(result.diagnostics.map(formatDiagnostic)),
    );
  }
}

/// Formats a diagnostic with its schema pointer when available.
String formatDiagnostic(Diagnostic diagnostic) =>
    '${diagnostic.severity.name}: ${diagnostic.code}'
    '${diagnostic.documentPath == null ? '' : ' at ${diagnostic.documentPath}'}: '
    '${diagnostic.message}';
