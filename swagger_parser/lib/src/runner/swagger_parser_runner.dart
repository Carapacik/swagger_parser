import 'package:swagger_parser/src/config/generation_config.dart';
import 'package:swagger_parser/src/dart/dart_generation_model.dart';
import 'package:swagger_parser/src/dart/dart_model_mapper.dart';
import 'package:swagger_parser/src/extraction/api_definition.dart';
import 'package:swagger_parser/src/extraction/api_definition_extractor.dart';
import 'package:swagger_parser/src/generation/dart_generator.dart';
import 'package:swagger_parser/src/generation/generation_exception.dart';
import 'package:swagger_parser/src/output/generation_result.dart';
import 'package:swagger_parser_core/swagger_parser_core.dart';

/// Runs the configured OpenAPI processing stages and generates Dart files.
final class const SwaggerParserRunner({
  /// Maps the API definition to Dart declarations.
  final DartModelMapper mapper = const DartModelMapper(),

  /// Converts the document and reference graph into an API definition.
  final ApiDefinitionExtractor extractor = const ApiDefinitionExtractor(),

  /// Reads the input into a version-specific document.
  final OpenApiParser parser = const OpenApiParser(),

  /// Checks the document before extraction.
  final OpenApiValidator validator = const OpenApiValidator(),

  /// Resolves references for extraction.
  final OpenApiReferenceResolver resolver = const OpenApiReferenceResolver(),

  /// Checks effective operations after reference resolution.
  final ResolvedOperationValidator resolvedValidator =
      const ResolvedOperationValidator(),

  /// Optional transformation applied after initial validation.
  final OpenApiNormalizer? normalizer,

  /// Renders the mapped declarations into files.
  final DartGenerator generator = const DartGenerator(),
}) {
  /// Runs the supplied stages in parse-to-generation order.
  this;

  /// Parses [source] and generates Dart files.
  /// [parseConfig] applies to the entry document and external references.
  ///
  /// Throws [GenerationException] if validation or normalization fails.
  Future<GenerationResult> generate(
    SchemaSource source, {
    GenerationConfig config = const GenerationConfig(),
    ParseConfig? parseConfig,
    DocumentLoader? loader,
  }) async {
    final (
      OpenApiDocument document,
      ReferenceGraph references,
      List<Diagnostic> diagnostics,
    ) = await _validate(
      source,
      parseConfig,
      loader,
    );
    final ApiDefinition api = extractor.extract(document, references);
    final DartGenerationModel model = mapper.map(api, config);
    final GenerationResult result;
    try {
      result = generator.generate(model, config: config);
    } on GenerationException catch (e) {
      throw GenerationException(
        e.message,
        diagnostics: [...diagnostics, ...e.diagnostics],
      );
    }
    return GenerationResult(
      files: result.files,
      diagnostics: [...diagnostics, ...result.diagnostics],
    );
  }

  /// Validates the document and its resolved operations.
  /// [parseConfig] applies to the entry document and external references.
  ///
  /// Returns diagnostics on success. Throws the same validation and reference
  /// errors as [generate].
  Future<List<Diagnostic>> validate(
    SchemaSource source, {
    ParseConfig? parseConfig,
    DocumentLoader? loader,
  }) async {
    final (_, _, List<Diagnostic> diagnostics) = await _validate(
      source,
      parseConfig,
      loader,
    );
    return diagnostics;
  }

  Future<(OpenApiDocument, ReferenceGraph, List<Diagnostic>)> _validate(
    SchemaSource source,
    ParseConfig? parseConfig,
    DocumentLoader? loader,
  ) async {
    OpenApiDocument document = parser.parse(source, config: parseConfig);
    final diagnostics = <Diagnostic>[];
    void check(ValidationReport report) {
      diagnostics.addAll(report.diagnostics);
      if (report.hasErrors) {
        throw GenerationException(
          'OpenAPI document validation failed.',
          diagnostics: diagnostics,
        );
      }
    }

    check(validator.validate(document));
    if (normalizer case final normalizer?) {
      final OpenApiDocument normalized = normalizer.normalize(document);
      if (identical(document, normalized) ||
          document.runtimeType != normalized.runtimeType ||
          document.version.family != normalized.version.family ||
          document.version.value != normalized.version.value) {
        throw GenerationException(
          'Normalization must return a new document of the same type and version.',
        );
      }
      document = normalized;
      check(validator.validate(document));
    }
    final ReferenceGraph references = await resolver.resolve(
      document,
      sourceUri: source.uri,
      config: parseConfig,
      loader: loader,
    );
    check(resolvedValidator.validate(document, references));
    return (document, references, List<Diagnostic>.unmodifiable(diagnostics));
  }
}
