import 'package:swagger_parser/src/dart/dart_generation_model.dart';
import 'package:swagger_parser/src/output/generated_file.dart';
import 'package:swagger_parser/src/planning/generation_plan.dart';

/// Checks output paths and sorts files before rendering.
final class const DartOutputPlanner() {
  /// Creates the planner for relative Dart output paths.
  this;

  /// Validates output paths and sorts files by relative path.
  GenerationPlan plan(DartGenerationModel model) {
    final paths = <String>{};
    final files = <PlannedDartFile>[];
    for (final DartLibraryModel library in model.libraries) {
      validateOutputPath(library.relativePath);
      if (!library.relativePath.endsWith('.dart')) {
        throw ArgumentError('Expected a .dart output: ${library.relativePath}');
      }
      if (!paths.add(library.relativePath)) {
        throw ArgumentError('Duplicate output path: ${library.relativePath}');
      }
      files.add(PlannedDartFile(model: library));
    }
    files.sort((a, b) => a.relativePath.compareTo(b.relativePath));
    return GenerationPlan(files);
  }
}
