import 'package:swagger_parser/src/dart/dart_generation_model.dart';

/// The ordered files to render.
final class GenerationPlan(Iterable<PlannedDartFile> files) {
  /// Keeps files in the supplied output order.
  this;

  /// Files in output order.
  final List<PlannedDartFile> files = List.unmodifiable(files);
}

/// A Dart library scheduled for output.
final class const PlannedDartFile({
  /// Declarations for this output file.
  required final DartLibraryModel model,
}) {
  /// Uses the output path declared by [model].
  this;

  /// Output path relative to the generation root.
  String get relativePath => model.relativePath;
}
