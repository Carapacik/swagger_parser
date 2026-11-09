import 'package:swagger_parser/src/config/generation_config.dart';
import 'package:swagger_parser/src/dart/dart_generation_model.dart';
import 'package:swagger_parser/src/generation/generation_exception.dart';
import 'package:swagger_parser/src/output/generated_file.dart';
import 'package:swagger_parser/src/output/generation_result.dart';
import 'package:swagger_parser/src/planning/dart_output_planner.dart';
import 'package:swagger_parser/src/planning/generation_plan.dart';
import 'package:swagger_parser/src/rendering/dart_source_renderer.dart';

/// Generates formatted Dart libraries from a [DartGenerationModel].
final class const DartGenerator({
  /// Selects output paths and file order.
  final DartOutputPlanner planner = const DartOutputPlanner(),

  /// Produces formatted Dart source for each planned file.
  final DartSourceRenderer renderer = const DartSourceRenderer(),
}) {
  /// Uses [planner] to select files and [renderer] to emit source.
  this;

  /// Renders [model] as formatted Dart files in output path order.
  GenerationResult generate(
    DartGenerationModel model, {
    GenerationConfig config = const GenerationConfig(),
  }) {
    final GenerationPlan plan = planner.plan(model);
    try {
      renderer.validatePlan(plan);
      final List<GeneratedFile> files = [
        ...plan.files.map((file) => renderer.render(file, config)),
        ...renderer.renderAdditionalFiles(plan, config),
      ]..sort((a, b) => a.relativePath.compareTo(b.relativePath));
      return GenerationResult(files: files, diagnostics: model.diagnostics);
    } on GenerationException catch (e) {
      throw GenerationException(
        e.message,
        diagnostics: [...model.diagnostics, ...e.diagnostics],
      );
    }
  }
}
