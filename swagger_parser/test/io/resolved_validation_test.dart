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
