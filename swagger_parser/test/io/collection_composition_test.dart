@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

Future<Map<String, String>> _generate(
  SchemaSource source, {
  bool validators = true,
}) async {
  final GenerationResult result = await const SwaggerParserRunner().generate(
    source,
    loader: _loader,
    config: GenerationConfig(generateValidators: validators),
  );
  expect(result.diagnostics, isEmpty);
  return {for (final file in result.files) file.relativePath: file.content};
}

Future<SchemaSource> _source(String path) =>
    _loader.loadPath('test/fixtures/$path');

Map<String, Object?> _schemas(Map<String, Object?> doc) =>
    (doc['definitions'] ??
            (doc['components']! as Map<String, Object?>)['schemas'])!
        as Map<String, Object?>;

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test(
      '$version preserves recursive maps and nested collection types',
      () async {
        final Map<String, String> json = await _generate(
          await _source('collections/$version.json'),
        );
        expect(
          await _generate(await _source('collections/$version.yaml')),
          json,
        );
        final String source = json.values.join();
        expect(source, contains('Map<String, List<String>> strings'));
        expect(source, contains('Map<String, List<String>>? nullableMap'));
        expect(source, contains('Map<String, List<String>?> nullableLists'));
        expect(source, contains('Map<String, List<String?>> nullableItems'));
        expect(source, isNot(contains('Object.fromJson')));
        expect(json.keys, isNot(contains('models/errors.dart')));
        expect(
          RegExp("import '([^']+)';")
              .allMatches(json['models/collection_root.dart']!)
              .map((match) => match[1]),
          unorderedEquals([
            '../dto_validation_error.dart',
            'collection_root_free_values_value.dart',
            'collision_value.dart',
            'collision_value2.dart',
            'service_status_chain.dart',
          ]),
        );
        final Map<String, String> allOf = await _generate(
          await _source('composition/all_of/$version.json'),
        );
        expect(
          await _generate(await _source('composition/all_of/$version.yaml')),
          allOf,
        );
        final String main = allOf['models/main.dart']!;
        for (final field in ['propA', 'propB', 'propC', 'propMain']) {
          expect(main, contains('final String $field'));
        }
        expect(RegExp(r'final int count\b').allMatches(main), hasLength(1));
        expect(allOf.values.join(), contains('Future<Pet> savePet('));
      },
    );
    for (final ext in ['json', 'yaml']) {
      test(
        '$version $ext keeps source schemas and declaration-order semantics',
        () async {
          final SchemaSource source = await _source(
            'composition/all_of/$version.$ext',
          );
          final OpenApiDocument document = const OpenApiParser().parse(source);
          final String snapshot = jsonEncode(document.toJson());
          final ReferenceGraph graph = await const OpenApiReferenceResolver()
              .resolve(document, sourceUri: source.uri, loader: _loader);
          final ApiDefinition api = const ApiDefinitionExtractor().extract(
            document,
            graph,
          );
          final Map<ReferenceLocation, Object?> before = {
            for (final entry in api.schemas.entries)
              entry.key: entry.value.definition.value,
          };
          final DartGenerationModel model = const DartModelMapper().map(
            api,
            const GenerationConfig(generateValidators: true),
          );
          for (final name in ['Main', 'Repeated', 'Pet', 'Tracker', 'Event']) {
            final DartDtoModel dto = model.libraries
                .expand((library) => library.dtos)
                .singleWhere((dto) => dto.name == name);
            expect(dto.fields.every((field) => field.isRequired), isTrue);
            expect(
              dto.fields.map((field) => field.wireName).toSet(),
              hasLength(dto.fields.length),
            );
          }
          expect(jsonEncode(document.toJson()), snapshot);
          expect({
            for (final entry in api.schemas.entries)
              entry.key: entry.value.definition.value,
          }, before);
          final Map<String, Object?> reversed = document.toJson();
          final Map<String, Object?> models = _schemas(reversed);
          final List<MapEntry<String, Object?>> entries = models.entries
              .toList()
              .reversed
              .toList();
          models
            ..clear()
            ..addEntries(entries);
          final Map<String, String> original = await _generate(
            source,
            validators: false,
          );
          final Map<String, String> reordered = await _generate(
            SchemaSource.json(jsonEncode(reversed), uri: source.uri),
            validators: false,
          );
          // A reference diamond must not depend on named-schema declaration order.
          expect(reordered['models/main.dart'], original['models/main.dart']);
        },
      );
      for (final selected in [
        ['Conflict'],
        ['NumberConflict'],
        ['ExternalConflict'],
        ['A', 'B'],
        ['ExternalCycle'],
        if (version == 'v3_1' || version == 'v3_2') ['ScalarUnionConflict'],
      ]) {
        test(
          '$version $ext rejects ${selected.first} with a source diagnostic',
          () async {
            final SchemaSource source = await _source(
              'composition/all_of/invalid_$version.$ext',
            );
            final Map<String, Object?> document = const OpenApiParser()
                .parse(source)
                .toJson();
            _schemas(document).removeWhere((key, _) => !selected.contains(key));
            await expectLater(
              _generate(
                SchemaSource.json(jsonEncode(document), uri: source.uri),
              ),
              throwsA(
                isA<GenerationException>()
                    .having(
                      (e) => e.diagnostics,
                      'diagnostic count',
                      isNotEmpty,
                    )
                    .having(
                      (e) => e.diagnostics,
                      'diagnostics',
                      everyElement(
                        isA<Diagnostic>()
                            .having((d) => d.sourceUri, 'URI', isNotNull)
                            .having(
                              (d) => d.documentPath,
                              'path',
                              startsWith('/'),
                            )
                            .having(
                              (d) => d.message,
                              'message',
                              contains(switch (selected.first) {
                                'A' || 'ExternalCycle' => 'cycle',
                                'ScalarUnionConflict' =>
                                  'Expected a single Dart value type.',
                                _ => 'Conflicting allOf property',
                              }),
                            ),
                      ),
                    ),
              ),
            );
          },
        );
      }
    }
  }
}
