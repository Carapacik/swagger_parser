@TestOn('vm')
library;

import 'dart:collection';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

Future<GenerationResult> _generate(
  String name,
  DtoSerializer serializer,
) async {
  final SchemaSource source = await _loader.loadPath(
    'test/fixtures/reference_siblings/$name',
  );
  return await const SwaggerParserRunner().generate(
    source,
    config: GenerationConfig(serializer: serializer),
  );
}

void main() {
  test(
    'maps shared union branches within a bounded number of schema reads',
    () async {
      Map<String, String>? baseline;
      for (final format in ['json', 'yaml']) {
        final SchemaSource source = await _loader.loadPath(
          'test/fixtures/schema_graphs/shared_unions/graph.$format',
        );
        final OpenApiDocument document = const OpenApiParser().parse(source);
        final ReferenceGraph graph = await const OpenApiReferenceResolver()
            .resolve(document, sourceUri: source.uri, loader: _loader);
        final ApiDefinition api = const ApiDefinitionExtractor().extract(
          document,
          graph,
        );
        final counted = _CountedDefinition(api);
        final DartGenerationModel model = const DartModelMapper().map(
          counted,
          const GenerationConfig(),
        );
        final GenerationResult result = const DartGenerator().generate(model);
        expect(result.diagnostics, isEmpty);
        final Map<String, String> files = {
          for (final file in result.files) file.relativePath: file.content,
        };
        baseline ??= files;
        expect(files, baseline);
        expect(files, hasLength(28));
        expect(files['models/envelope.dart'], contains('Layer23 typed'));
        expect(files['models/envelope.dart'], contains('Layer23 untyped'));
      }
    },
  );

  for (final version in ['v3_1', 'v3_2']) {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      test('$version keeps a union when a reference has a matching type '
          'with ${serializer.name}', () async {
        Map<String, String>? baseline;
        for (final format in ['json', 'yaml']) {
          final GenerationResult result = await _generate(
            'object_union_$version.$format',
            serializer,
          );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final file in result.files) file.relativePath: file.content,
          };
          baseline ??= files;
          expect(files, baseline);
          // The sibling `type: object` repeats what every union member says.
          // It does not wrap the union in a generated object.
          final String envelope = files['models/envelope.dart']!;
          expect(envelope, contains('Frame frame'));
          expect(envelope, contains('FrameAliasChain alias'));
          expect(envelope, contains('ExclusiveAlias exclusive'));
          expect(envelope, contains('NestedFrame nested'));
          expect(files.keys, contains('default_client/models/frame.dart'));
          final String client = files['default_client/api_client.dart']!;
          expect(client, contains('Future<models.Frame> getFrame('));
          expect(client, contains('Future<models.FrameAliasChain> getAlias('));
          expect(
            client,
            contains('Future<models.ExclusiveAlias> getExclusive('),
          );
          expect(client, contains('Future<models.NestedFrame> getNested('));
          // A sibling `type: object` beside an object reference stays valid.
          expect(client, contains('Future<A> getObject('));
        }
      });
    }

    test('$version keeps the intersection when the sibling type narrows '
        'the union', () async {
      for (final format in ['json', 'yaml']) {
        await expectLater(
          _generate('mixed_union_$version.$format', DtoSerializer.plain),
          throwsA(
            isA<GenerationException>().having(
              (e) => e.message,
              'message',
              contains('Expected object branches in allOf.'),
            ),
          ),
        );
      }
    });

    for (final kind in ['open', 'cyclic']) {
      test(
        '$version does not infer a matching type from a $kind union',
        () async {
          for (final format in ['json', 'yaml']) {
            await expectLater(
              _generate('${kind}_union_$version.$format', DtoSerializer.plain),
              throwsA(
                isA<GenerationException>().having(
                  (e) => e.diagnostics.single.code,
                  'code',
                  'unsupportedDartSchema',
                ),
              ),
            );
          }
        },
      );
    }
  }
}

// Fail on excessive work instead of depending on the speed of the CI machine.
final class _BoundedSchemaMap(super.map)
    extends MapView<ReferenceLocation, ApiSchema> {
  var _reads = 0;

  @override
  ApiSchema? operator [](Object? key) {
    if (++_reads > 20000) {
      throw StateError('Schema mapping exceeded 20000 index reads.');
    }
    return super[key];
  }
}

final class _CountedDefinition(ApiDefinition api) extends ApiDefinition {
  this
    : super(
        title: api.title,
        apiVersion: api.apiVersion,
        specVersion: api.specVersion,
        sourceUri: api.sourceUri,
        namedSchemas: api.namedSchemas,
        dynamicAnchors: api.dynamicAnchors,
      );
  final Map<ReferenceLocation, ApiSchema> _schemas = _BoundedSchemaMap(
    api.schemas,
  );

  @override
  Map<ReferenceLocation, ApiSchema> get schemas => _schemas;
}
