import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'passes the normalized document and source URI through the pipeline',
    () async {
      final stages = _Stages();
      final GenerationResult result = await stages
          .runner(normalize: true)
          .generate(
            SchemaSource('{}', uri: Uri.parse('https://example.com/api.yaml')),
          );
      expect(stages.calls, [
        'parse',
        'validate:original',
        'normalize',
        'validate:normalized',
        'resolve:normalized',
        'extract:normalized',
        'map',
      ]);
      expect(stages.sourceUri, Uri.parse('https://example.com/api.yaml'));
      expect(result.files.single.content, contains('class User'));
    },
  );

  test(
    'stops before reference loading or generation on validation errors',
    () async {
      final stages = _Stages(invalid: true);
      await expectLater(
        stages.runner().generate(const SchemaSource('{}')),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.diagnostics.single.code,
            'diagnostic code',
            'invalid',
          ),
        ),
      );
      expect(stages.calls, ['parse', 'validate:original']);
    },
  );
  test('passes the default resolution graph to the extractor', () async {
    final stages = _Stages();
    final runner = SwaggerParserRunner(extractor: stages, mapper: stages);
    const source = SchemaSource.yaml(r"""
openapi: 3.0.4
info: {title: Stations, version: '1'}
paths: {}
components:
  schemas:
    Identity: {type: integer}
    StationId: {$ref: '#/components/schemas/Identity'}
""");
    await runner.generate(source);
    final ReferenceTarget? target = stages.extractedGraph!.targetFor((
      documentUri: null,
      pointer: r'/components/schemas/StationId/$ref',
    ));
    expect(target!.location.pointer, '/components/schemas/Identity');
    expect(stages.calls, ['extract:Stations', 'map']);
  });
}

final class _Stages({final bool invalid = false})
    extends OpenApiParser
    implements
        OpenApiValidator,
        OpenApiNormalizer,
        OpenApiReferenceResolver,
        ApiDefinitionExtractor,
        DartModelMapper {
  final calls = <String>[];
  Uri? sourceUri;
  ReferenceGraph? extractedGraph;

  SwaggerParserRunner runner({bool normalize = false}) => SwaggerParserRunner(
    parser: this,
    validator: this,
    normalizer: normalize ? this : null,
    resolver: this,
    extractor: this,
    mapper: this,
  );

  @override
  OpenApiDocument parseDocument(
    SchemaSource source, {
    required ParseConfig config,
  }) {
    calls.add('parse');
    return _document('original');
  }

  @override
  ValidationReport validate(OpenApiDocument document) {
    calls.add('validate:${(document as OpenApiV30Document).info.title}');
    return ValidationReport([
      if (invalid)
        const Diagnostic(
          code: 'invalid',
          message: 'Invalid input.',
          severity: DiagnosticSeverity.error,
        ),
    ]);
  }

  @override
  T normalize<T extends OpenApiDocument>(T document) {
    calls.add('normalize');
    return _document('normalized') as T;
  }

  @override
  Future<ReferenceGraph> resolve(
    OpenApiDocument document, {
    Uri? sourceUri,
    DocumentLoader? loader,
    ParseConfig? config,
  }) async {
    calls.add('resolve:${(document as OpenApiV30Document).info.title}');
    this.sourceUri = sourceUri;
    return const ReferenceGraph.empty();
  }

  @override
  ApiDefinition extract(OpenApiDocument document, ReferenceGraph references) {
    extractedGraph = references;
    calls.add('extract:${(document as OpenApiV30Document).info.title}');
    return ApiDefinition(
      title: 'Example',
      apiVersion: '1',
      specVersion: document.version,
    );
  }

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) {
    calls.add('map');
    return DartGenerationModel(
      libraries: [
        DartLibraryModel(
          relativePath: 'user.dart',
          dtos: [DartDtoModel(name: 'User')],
        ),
      ],
    );
  }
}

OpenApiV30Document _document(String title) => OpenApiV30Document(
  info: OpenApiV30Info(title: title, version: '1'),
  paths: OpenApiV30Paths(entries: const {}),
);
