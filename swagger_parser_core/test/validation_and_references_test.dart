import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

const parser = OpenApiParser();
const resolver = OpenApiReferenceResolver();
const validator = OpenApiValidator();

final class _Loader() implements DocumentLoader {
  final calls = <Uri>[];
  @override
  Future<SchemaSource> load(Uri uri) async {
    calls.add(uri);
    final String name = switch (uri.toString()) {
      'https://stations.example/paths.yaml' => 'paths.yaml',
      'https://stations.example/peers.yaml' => 'peers.yaml',
      'https://stations.example/deploy/api/parts/routes.json' => 'routes.json',
      'https://stations.example/deploy/api/models/reading.json' =>
        'reading.json',
      _ => throw StateError('Unexpected URI: $uri'),
    };
    return SchemaSource(await readInput('references/$name'), uri: uri);
  }
}

void main() {
  final Uri root = Uri.parse(
    'https://stations.example/deploy/source/stations.yaml',
  );
  final Uri reading = Uri.parse(
    'https://stations.example/deploy/api/models/reading.json',
  );
  late OpenApiDocument document;
  setUpAll(() async {
    document = parser.parse(
      SchemaSource.yaml(await readInput('references/stations.yaml'), uri: root),
    );
  });

  test(
    'resolves physical locations, canonical bases, cycles, and dynamic scope',
    () async {
      final loader = _Loader();
      final Map<String, Object?> before = document.toJson();
      final ReferenceGraph graph = await resolver.resolve(
        document,
        sourceUri: root,
        loader: loader,
      );
      expect(document.toJson(), before);
      expect(
        loader.calls,
        unorderedEquals([
          reading,
          Uri.parse('https://stations.example/deploy/api/parts/routes.json'),
        ]),
      );
      ReferenceLocation at(String pointer) =>
          (documentUri: root, pointer: pointer);
      const station = '/components/schemas/Station';
      final ReferenceTarget internal = graph.targetFor(
        at('$station/properties/level/\$ref'),
      )!;
      expect(internal.location, at('$station/\$defs/level ~1~0'));
      expect(internal.value, {'type': 'integer'});
      final ResolvedReference external =
          graph.references[at('$station/properties/reading/\$ref')]!;
      expect(external.uri, reading.replace(fragment: 'reading'));
      expect(external.target.location, (documentUri: reading, pointer: ''));
      expect(
        external.target.baseUri,
        Uri.parse('https://schemas.example/reading'),
      );
      expect(
        graph.targetFor((
          documentUri: reading,
          pointer: r'/properties/previous/$ref',
        ))!.location,
        external.target.location,
      );
      expect(
        graph.targetFor((
          documentUri: reading,
          pointer: r'/properties/station/$ref',
        ))!.location,
        at(station),
      );
      final ReferenceLocation dynamicSource = at(
        '$station/properties/children/items/\$dynamicRef',
      );
      expect(graph.targetFor(dynamicSource)!.location, at(station));
      final Uri stationResource = root.resolve('../api/schemas/station');
      expect(
        graph.schemaResources[at('$station/properties/children/items')],
        stationResource,
      );
      expect(
        graph.dynamicAnchors[(stationResource, 'node')]!.location,
        at(station),
      );
      expect(
        graph
            .targetFor(
              dynamicSource,
              dynamicScope: [root.resolve('../api/schemas/detailed')],
            )!
            .location,
        at('/components/schemas/DetailedStation'),
      );
      expect(
        graph
            .targetFor(
              at(
                '/paths/~1stations~1{id}/get/responses/200/links/next/operationRef',
              ),
            )!
            .location,
        at('/paths/~1stations~1{id}/get'),
      );
      expect(
        (internal.value! as Map<String, Object?>).clear,
        throwsUnsupportedError,
      );
      expect(graph.references.clear, throwsUnsupportedError);
      expect(validator.validate(document).diagnostics, isEmpty);
    },
  );

  test('keeps caches local to each resolution', () async {
    final loader = _Loader();
    await Future.wait([
      for (var i = 0; i < 2; i++)
        resolver.resolve(document, sourceUri: root, loader: loader),
    ]);
    expect(loader.calls.where((uri) => uri == reading), hasLength(2));
  });

  test('reports missing loaders at the referring field', () async {
    await expectLater(
      resolver.resolve(document, sourceUri: root),
      throwsA(
        isA<ReferenceResolutionException>()
            .having((e) => e.code, 'code', 'missingLoader')
            .having((e) => e.sourceUri, 'source URI', root)
            .having((e) => e.documentPath, 'pointer', r'/paths/~1archive/$ref'),
      ),
    );
  });

  test('defers malformed parameter URIs to the resolver', () async {
    final String text = await readInput('references/invalid_paths.yaml');
    final OpenApiDocument doc = parser.parse(
      SchemaSource.yaml(
        text.replaceFirst(
          '#/components/parameters/Id',
          '#/components/parameters/%QQ',
        ),
      ),
    );
    expect(validator.validate(doc).diagnostics, isNotEmpty);
    await expectLater(
      resolver.resolve(doc),
      throwsA(
        isA<ReferenceResolutionException>()
            .having((error) => error.code, 'code', 'invalidReference')
            .having(
              (error) => error.documentPath,
              'pointer',
              r'/paths/~1stations~1{id}/parameters/0/$ref',
            ),
      ),
    );
  });

  test(
    'requires an absolute base to load a relative external reference',
    () async {
      final loader = _Loader();
      await expectLater(
        resolver.resolve(document, loader: loader),
        throwsA(
          isA<ReferenceResolutionException>().having(
            (error) => error.code,
            'code',
            'missingBaseUri',
          ),
        ),
      );
      expect(loader.calls, isEmpty);
    },
  );

  test('reports the loader cause', () async {
    await expectLater(
      resolver.resolve(
        document,
        sourceUri: Uri.parse('https://elsewhere.example/input'),
        loader: _Loader(),
      ),
      throwsA(
        isA<ReferenceResolutionException>()
            .having((e) => e.code, 'code', 'loadFailed')
            .having((e) => e.cause, 'cause', isA<StateError>()),
      ),
    );
  });

  test(
    'reports document rules with stable codes and escaped pointers',
    () async {
      final ValidationReport result = validator.validate(
        parser.parse(
          SchemaSource.yaml(await readInput('references/invalid_paths.yaml')),
        ),
      );
      expect(result.hasErrors, isTrue);
      expect(
        result.diagnostics.map((d) => (d.code, d.documentPath)),
        unorderedEquals([
          ('duplicateTag', '/tags/3/name'),
          ('missingPathParameter', '/paths/~1sensors~1{sensor}/get'),
          ('unknownTagParent', '/tags/2/parent'),
          ('cyclicTagParent', '/tags/1/parent'),
          ('duplicatePathTemplate', '/paths/~1stations~1{name}'),
          (
            'duplicateOperationId',
            '/paths/~1stations~1{name}/additionalOperations/REPORT/operationId',
          ),
          (
            'missingPathParameter',
            '/paths/~1stations~1{name}/additionalOperations/REPORT',
          ),
          (
            'unusedPathParameter',
            '/paths/~1stations~1{name}/additionalOperations/REPORT/parameters/0/name',
          ),
        ]),
      );
    },
  );

  for (final file in [
    'swagger_v2',
    'open_api_v3_0',
    'open_api_v3_1',
    'open_api_v3_2',
  ]) {
    test('resolves the complete $file fixture', () async {
      final source = SchemaSource.json(await readInput('parsing/$file.json'));
      final ReferenceGraph graph = await resolver.resolve(
        parser.parse(source),
        sourceUri: Uri.parse('https://stations.example/$file.json'),
        loader: _Loader(),
      );
      expect(graph.references, isNotEmpty);
      for (final ResolvedReference target in graph.references.values) {
        expect(target.target.location.documentUri, isNotNull);
      }
    });
  }

  test('resolves in-memory documents without a retrieval URI', () async {
    final source = SchemaSource.json(
      await readInput('parsing/open_api_v3_2.json'),
    );
    final ReferenceGraph graph = await resolver.resolve(parser.parse(source));
    expect(
      graph.targetFor((
        documentUri: null,
        pointer: r'/components/mediaTypes/LiveReadings/$ref',
      ))!.location,
      (documentUri: null, pointer: '/components/mediaTypes/EventStream'),
    );
  });

  test('finds a canonical ID declared in a later external document', () async {
    final Map<String, Object?> data = document.toJson();
    final components = data['components']! as Map<String, Object?>;
    components['schemas'] = {
      'Canonical': {r'$ref': 'https://schemas.example/reading'},
      ...components['schemas']! as Map<String, Object?>,
    };
    data['paths'] = <String, Object?>{};
    final loader = _Loader();
    final ReferenceGraph graph = await resolver.resolve(
      parser.parse(SchemaSource.json(jsonEncode(data))),
      sourceUri: root,
      loader: loader,
    );
    expect(
      graph
          .targetFor((
            documentUri: root,
            pointer: r'/components/schemas/Canonical/$ref',
          ))!
          .location
          .documentUri,
      reading,
    );
    expect(loader.calls.toSet(), hasLength(loader.calls.length));
  });

  test('rejects duplicate schema IDs at their declaration', () async {
    final Map<String, Object?> data = document.toJson();
    (data['components']! as Map<String, Object?>)['schemas'] = {
      'First': {r'$id': 'same'},
      'Second': {r'$id': 'same'},
    };
    await expectLater(
      resolver.resolve(
        parser.parse(SchemaSource.json(jsonEncode(data))),
        sourceUri: root,
      ),
      throwsA(
        isA<ReferenceResolutionException>()
            .having((e) => e.code, 'code', 'duplicateIdentifier')
            .having(
              (e) => e.documentPath,
              'pointer',
              r'/components/schemas/Second/$id',
            ),
      ),
    );
  });

  for (final (reference, code) in [
    ('#/components/schemas/Missing', 'missingTarget'),
    ('#/components/mediaTypes/Station', 'invalidTarget'),
    ('#/components/schemas/~2', 'invalidReference'),
    ('#%FF', 'invalidReference'),
    ('bad path', 'invalidReference'),
  ]) {
    test('reports $code for $reference', () async {
      final Map<String, Object?> data = document.toJson();
      final components = data['components']! as Map<String, Object?>;
      data['paths'] = <String, Object?>{};
      components['schemas'] = {
        'Bad': {r'$ref': reference},
      };
      components['mediaTypes'] = {'Station': <String, Object?>{}};
      final OpenApiDocument doc = parser.parse(
        SchemaSource.json(jsonEncode(data)),
      );
      await expectLater(
        resolver.resolve(doc, sourceUri: root),
        throwsA(
          isA<ReferenceResolutionException>()
              .having((e) => e.code, 'code', code)
              .having(
                (e) => e.documentPath,
                'pointer',
                r'/components/schemas/Bad/$ref',
              ),
        ),
      );
    });
  }
}
