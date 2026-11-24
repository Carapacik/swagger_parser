@TestOn('vm')
library;

import 'dart:isolate';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('applies per-call parse settings to external documents', () async {
    final Uri package = (await Isolate.resolvePackageUri(
      Uri.parse('package:swagger_parser/swagger_parser.dart'),
    ))!;
    const loader = FileSchemaSourceLoader();
    final SchemaSource entry = await loader.load(
      package.resolve('../test/fixtures/cli/parse_entry.yaml'),
    );
    const strict = ParseConfig(unknownFields: UnknownFieldPolicy.reject);
    const runner = SwaggerParserRunner(
      resolver: OpenApiReferenceResolver(config: strict),
    );
    final Matcher rejectsExtra = throwsA(
      isA<ReferenceResolutionException>().having(
        (e) => e.cause,
        'external error',
        isA<SchemaParseException>().having(
          (e) => e.documentPath,
          'path',
          '/info/extra',
        ),
      ),
    );
    await expectLater(runner.validate(entry, loader: loader), rejectsExtra);
    await runner.generate(
      entry,
      loader: loader,
      parseConfig: const ParseConfig(),
    );
    await expectLater(runner.generate(entry, loader: loader), rejectsExtra);
    await expectLater(
      const SwaggerParserRunner().validate(
        entry,
        loader: loader,
        parseConfig: strict,
      ),
      rejectsExtra,
    );
  });

  test('locates recoverable flags in referenced parameters', () async {
    final Uri uri = Uri.parse('file:///api.yaml');
    final Uri external = uri.resolve('params.yaml');
    const runner = SwaggerParserRunner();
    final SchemaSource fixture = await const FileSchemaSourceLoader().loadPath(
      'test/fixtures/parameter_styles/path_allow_reserved.yaml',
    );
    final String input = fixture.content.replaceFirst('3.0.0', '3.1.2');
    final int start = input.indexOf('        - name:');
    final int end = input.indexOf('      responses:', start);
    for (final complete in [false, true]) {
      final pointer = complete ? '/components/parameters/Item' : '/Item';
      final source = SchemaSource.yaml(
        input.replaceRange(
          start,
          end,
          "        - \$ref: 'params.yaml#$pointer'\n",
        ),
        uri: uri,
      );
      const parameter =
          'name: id\nin: path\nrequired: true\nallowReserved: true\nschema:\n  type: string';
      final indent = complete ? '      ' : '  ';
      final String text = [
        if (complete) ...[
          'openapi: 3.1.2',
          'info:',
          '  title: Items',
          "  version: '1'",
          'paths: {}',
          'components:',
          '  parameters:',
          '    Item:',
        ] else
          'Item:',
        for (final line in parameter.split('\n')) '$indent$line',
      ].join('\n');
      final loader = _ParameterLoader(text);
      final GenerationResult result = await runner.generate(
        source,
        loader: loader,
      );
      final Diagnostic warning = result.diagnostics.single;
      expect(warning.severity, DiagnosticSeverity.warning);
      expect(warning.documentPath, '$pointer/allowReserved');
      expect(warning.sourceUri, external);
      expect(warning.location?.line, complete ? 12 : 5);
      expect(
        result.files.any((file) => file.content.contains('getItem(')),
        isTrue,
      );
      final TypeMatcher<SchemaParseException> invalid =
          isA<SchemaParseException>().having(
            (e) => e.documentPath,
            'field',
            '$pointer/allowReserved',
          );
      await expectLater(
        runner.validate(source, loader: loader),
        throwsA(
          complete
              ? isA<ReferenceResolutionException>().having(
                  (e) => e.cause,
                  'external error',
                  invalid,
                )
              : invalid,
        ),
      );
    }
  });

  test('stops before extraction on an invalid external Path Item', () async {
    final Uri? library = await Isolate.resolvePackageUri(
      Uri.parse('package:swagger_parser_core/swagger_parser_core.dart'),
    );
    final Uri fixture = library!.resolve(
      '../test/fixtures/validation/swagger_v2.json',
    );
    const loader = FileSchemaSourceLoader();
    final SchemaSource source = await loader.load(fixture);
    final stages = _UnexpectedStages();
    final runner = SwaggerParserRunner(extractor: stages, mapper: stages);
    await expectLater(
      runner.generate(source, loader: loader),
      throwsA(
        isA<GenerationException>().having(
          (error) => error.diagnostics.map((d) => (d.code, d.sourceUri)),
          'diagnostics',
          unorderedEquals([
            (
              'missingPathParameter',
              fixture.resolve('../references/paths.yaml'),
            ),
            ('duplicateOperationId', fixture),
          ]),
        ),
      ),
    );
  });
}

final class _UnexpectedStages()
    implements ApiDefinitionExtractor, DartModelMapper {
  @override
  ApiDefinition extract(OpenApiDocument document, ReferenceGraph references) =>
      fail('Extraction ran after a validation error.');

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      fail('Mapping ran after a validation error.');
}

final class _ParameterLoader(final String text) implements DocumentLoader {
  @override
  Future<SchemaSource> load(Uri uri) async => SchemaSource.yaml(text);
}
