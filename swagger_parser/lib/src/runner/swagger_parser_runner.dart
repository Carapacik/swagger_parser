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
  /// Calls [onValidationWarning] as it finds recoverable validation errors.
  /// The result also contains these warnings.
  /// Throws if a required reference, wire type, or operation is ambiguous.
  Future<GenerationResult> generate(
    SchemaSource source, {
    GenerationConfig config = const GenerationConfig(),
    ParseConfig? parseConfig,
    DocumentLoader? loader,
    void Function(Diagnostic)? onValidationWarning,
  }) async {
    final (
      OpenApiDocument document,
      ReferenceGraph references,
      List<Diagnostic> diagnostics,
    ) = await _validate(
      source,
      parseConfig,
      loader,
      generating: true,
      onValidationWarning: onValidationWarning,
    );
    final GenerationResult result;
    try {
      final ApiDefinition api = extractor.extract(document, references);
      final DartGenerationModel model = mapper.map(api, config);
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
  /// Returns diagnostics on success. Throws on validation or reference errors.
  Future<List<Diagnostic>> validate(
    SchemaSource source, {
    ParseConfig? parseConfig,
    DocumentLoader? loader,
  }) async {
    final (_, _, List<Diagnostic> diagnostics) = await _validate(
      source,
      parseConfig,
      loader,
      generating: false,
    );
    return diagnostics;
  }

  Future<(OpenApiDocument, ReferenceGraph, List<Diagnostic>)> _validate(
    SchemaSource source,
    ParseConfig? parseConfig,
    DocumentLoader? loader, {
    required bool generating,
    void Function(Diagnostic)? onValidationWarning,
  }) async {
    final diagnostics = <Diagnostic>[];
    final reported = <(String, Uri?, String?, String, DiagnosticSeverity)>{};
    void record(Diagnostic d) {
      if (!reported.add((
        d.code,
        d.sourceUri ?? source.uri,
        d.documentPath,
        d.message,
        d.severity,
      ))) {
        return;
      }
      diagnostics.add(d);
      if (d.severity == DiagnosticSeverity.warning) {
        onValidationWarning?.call(d);
      }
    }

    T read<T>(T Function() action) =>
        withParseWarnings(generating ? record : null, action);
    OpenApiDocument document = read(
      () => parser.parse(source, config: parseConfig),
    );
    void check(ValidationReport report) {
      var failed = false;
      for (final Diagnostic d in report.diagnostics) {
        final Uri? uri = d.sourceUri ?? source.uri;
        final DiagnosticSeverity severity =
            generating &&
                d.severity == DiagnosticSeverity.error &&
                const {
                  'duplicateTag',
                  'unknownTagParent',
                  'cyclicTagParent',
                  'duplicateOperationId',
                  'optionalPathParameter',
                }.contains(d.code)
            ? DiagnosticSeverity.warning
            : d.severity;
        failed |= severity == DiagnosticSeverity.error;
        record(
          Diagnostic(
            code: d.code,
            message: d.message,
            severity: severity,
            sourceUri: uri,
            documentPath: d.documentPath,
            location: d.location,
          ),
        );
      }
      if (failed) {
        throw GenerationException(
          'OpenAPI document validation failed.',
          diagnostics: diagnostics,
        );
      }
    }

    check(validator.validate(document));
    if (normalizer case final normalizer?) {
      final OpenApiDocument normalized = read(
        () => normalizer.normalize(document),
      );
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
    final ReferenceGraph references = await read(
      () => resolver.resolve(
        document,
        sourceUri: source.uri,
        config: parseConfig,
        loader: loader,
      ),
    );
    check(resolvedValidator.validate(document, references));
    return (document, references, List<Diagnostic>.unmodifiable(diagnostics));
  }
}
