import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

import 'package:swagger_parser/src/config/generation_config.dart';
import 'package:swagger_parser/src/dart/dart_code_builder.dart';
import 'package:swagger_parser/src/output/generated_file.dart';
import 'package:swagger_parser/src/planning/generation_plan.dart';

/// Emits and formats Dart source in memory.
class const DartSourceRenderer({
  /// Builds the syntax tree before formatting.
  final DartCodeBuilder codeBuilder = const DefaultDartCodeBuilder(),
}) {
  /// Uses [codeBuilder] to build each library before formatting.
  this;

  /// Checks the file plan before rendering starts.
  void validatePlan(GenerationPlan plan) {}

  /// Renders extra files after the planned libraries. Empty by default.
  /// Paths must be unique across both sets of files.
  Iterable<GeneratedFile> renderAdditionalFiles(
    GenerationPlan plan,
    GenerationConfig config,
  ) => const [];

  /// Formats a library with the selected output width.
  String formatSource(String source, GenerationConfig config) => DartFormatter(
    languageVersion: Version(3, 13, 0),
    pageWidth: config.pageWidth,
  ).format(source);

  /// Renders one planned file with the specified formatting options.
  GeneratedFile render(PlannedDartFile file, GenerationConfig config) {
    if (config.pageWidth <= 0) {
      throw ArgumentError.value(
        config.pageWidth,
        'pageWidth',
        'Must be positive',
      );
    }
    final Library library = switch (codeBuilder) {
      final DefaultDartCodeBuilder builder => builder.build(
        file.model,
        httpClient: config.httpClient,
        serializer: config.serializer,
        bodyPositional: config.bodyPositional,
        decodeResponsesInBackground: config.decodeResponsesInBackground,
        originalHttpResponse:
            config.originalHttpResponse &&
            config.responseMode == ResponseMode.firstSuccess,
      ),
      final DartCodeBuilder builder => builder.build(file.model),
    };
    // Each file has a fresh allocator, so imports cannot leak across runs.
    final source = library
        .accept(
          DartEmitter.scoped(useNullSafetySyntax: true, orderDirectives: true),
        )
        .toString();
    return GeneratedFile(
      relativePath: file.relativePath,
      content: formatSource(source, config),
    );
  }
}
