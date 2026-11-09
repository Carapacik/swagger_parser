@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test('$version separates Path Item metadata from operations', () async {
      for (final ext in ['json', 'yaml']) {
        const loader = FileSchemaSourceLoader();
        final SchemaSource source = await loader.loadPath(
          'test/fixtures/extraction/path_metadata/$version.$ext',
        );
        final OpenApiDocument document = const OpenApiParser().parse(source);
        final ReferenceGraph graph = await const OpenApiReferenceResolver()
            .resolve(document, sourceUri: source.uri, loader: loader);
        expect(
          const ResolvedOperationValidator()
              .validate(document, graph)
              .diagnostics,
          isEmpty,
        );
        final ApiDefinition api = const ApiDefinitionExtractor().extract(
          document,
          graph,
        );
        expect(api.operations, hasLength(6));
        for (final id in ['readItems', 'readRemote']) {
          final ApiOperation op = api.operations.singleWhere(
            (o) => o.operationId == id,
          );
          expect(op.parameters.map((p) => (p.name, p.location, p.isRequired)), [
            ('id', 'path', true),
            ('limit', 'query', true),
            ('id', 'header', false),
          ]);
          expect(api.schemas[op.parameters[1].schema]!.types, {'integer'});
          expect(op.security.map((s) => s.value), [
            {'token': []},
          ]);
          if (version != 'v2') {
            expect(op.servers.single.value, {'url': 'https://operation.test'});
          }
        }
        final ApiOperation post = api.operations.singleWhere(
          (o) => o.operationId == 'saveItems',
        );
        expect(post.security, isEmpty);
        if (version != 'v2') {
          expect(post.servers.single.value, {'url': 'https://path.test'});
        }
        final ApiOperation root = api.operations.singleWhere(
          (o) => o.operationId == 'readRoot',
        );
        expect(root.security.map((s) => s.value), [
          {'token': []},
        ]);
        if (version != 'v2') {
          expect(root.servers.single.value, {'url': 'https://root.test'});
        }
        expect(
          api.operations
              .singleWhere((o) => o.operationId == 'readAlternative')
              .security
              .map((s) => s.value),
          [
            {'token': []},
            {'other': []},
          ],
        );
        final paths = document.toJson()['paths']! as Map<String, Object?>;
        final item = paths['/items/{id}']! as Map<String, Object?>;
        expect(item['x-label'], 'metadata');
        expect(item['x-config'], {'enabled': true, 'count': 2});
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                source,
                loader: loader,
                config: GenerationConfig(httpClient: backend),
              );
          expect(result.diagnostics, isEmpty);
          final String code = result.files.map((f) => f.content).join();
          for (final id in [
            'readItems',
            'saveItems',
            'readRemote',
            'saveRemote',
            'readRoot',
            'readAlternative',
          ]) {
            expect(code, contains('$id('));
          }
          expect(code, isNot(contains('Future<void> xLabel(')));
          expect(code, contains('openapi.security'));
        }
      }
    });
  }
}
