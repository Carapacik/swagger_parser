import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/editor_config.dart';
import 'package:swagger_parser_pages/src/generation_archive.dart';
import 'package:swagger_parser_pages/src/template_input.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';

/// Browser-safe parsing, generation, and ZIP output.
final class EditorServices() {
  /// Creates the browser integration.
  this;

  /// Reads the entry document. Does not retrieve external references.
  OpenApiDocument parse(String source, ParseConfig config) =>
      const OpenApiParser().parse(SchemaSource(source), config: config);

  /// Generates the editor schema. External files and network refs are not loaded.
  /// Invalid config or schemas fail without a partial download.
  Future<GenerationArchive> generate(
    String source,
    EditorConfig config, {
    String? templates,
  }) async {
    final TemplateInput? input = templates == null
        ? null
        : TemplateInput.parse(templates);
    final PipelineConfig settings = config.pipelineConfig;
    final GenerationResult result =
        await createRunner(
          normalize: settings.normalize,
          templates: input?.overrides ?? const {},
          files: input?.files ?? const [],
        ).generate(
          SchemaSource(source),
          config: settings.generation,
          parseConfig: settings.parse,
        );
    return GenerationArchive.fromResult(
      result,
      templates == null ? 'swagger_parser.zip' : 'swagger_parser_templates.zip',
    );
  }

  /// Creates the shared runner with optional in-memory template overrides.
  SwaggerParserRunner createRunner({
    Map<String, String> templates = const {},
    List<TemplateFile> files = const [],
    NormalizeConfig normalize = const NormalizeConfig(),
  }) => SwaggerParserRunner(
    normalizer: normalize.explicitParameterSerialization
        ? OpenApiNormalizer(config: normalize)
        : null,
    generator: DartGenerator(
      renderer: MustacheSourceRenderer(templates, files: files),
    ),
  );
}
