@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> _generate(
  String stem,
  String ext,
  DtoSerializer serializer,
) async => await const SwaggerParserRunner().generate(
  await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/x_nullable/$stem.$ext',
  ),
  config: GenerationConfig(usePresenceRecords: true, serializer: serializer),
);

void main() {
  test(
    'preserves extensions and reference targets during extraction',
    () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/x_nullable/nullable_v2_0.$ext');
        final document =
            const OpenApiParser().parse(source) as SwaggerV2Document;
        final Map<String, Object?> before = document.toJson();
        final SwaggerV2Schema payload = document.definitions!['Payload']!;
        expect(
          payload.properties!['name']!.extensions['x-nullable']!.value,
          true,
        );
        final ReferenceGraph graph = await const OpenApiReferenceResolver()
            .resolve(document, sourceUri: source.uri);
        final ApiDefinition api = const ApiDefinitionExtractor().extract(
          document,
          graph,
        );
        final ApiSchema schema = api.schemas.entries
            .singleWhere(
              (e) => e.key.pointer == '/definitions/Payload/properties/name',
            )
            .value;
        expect(schema.types, {'string', 'null'});
        final ApiSchema original = api.schemas.entries
            .singleWhere((e) => e.key.pointer == '/definitions/Station')
            .value;
        expect(original.types, {'object'});
        expect(document.toJson(), before);
      }
    },
  );

  test('renders paired x-nullable fixtures for every serializer', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      final GenerationResult json = await _generate(
        'nullable_v2_0',
        'json',
        serializer,
      );
      final GenerationResult yaml = await _generate(
        'nullable_v2_0',
        'yaml',
        serializer,
      );
      expect(json.diagnostics, isEmpty);
      expect(
        {for (final f in json.files) f.relativePath: f.content},
        {for (final f in yaml.files) f.relativePath: f.content},
      );
      final String source = json.files.map((f) => f.content).join();
      expect(source, contains('String? name'));
      expect(source, contains('Station? station'));
      expect(source, contains('NullableStation narrowed'));
      expect(source, contains('List<String?> items'));
      expect(source, contains('List<String>? list'));
      expect(source, contains('({String? value})? note'));
    }
  });

  test('keeps requiredness independent of x-nullable', () async {
    for (final ext in ['json', 'yaml']) {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/x_nullable/nullable_v2_0.$ext',
      );
      final OpenApiDocument document = const OpenApiParser().parse(source);
      final ReferenceGraph graph = await const OpenApiReferenceResolver()
          .resolve(document, sourceUri: source.uri);
      final ApiDefinition api = const ApiDefinitionExtractor().extract(
        document,
        graph,
      );
      final DartGenerationModel model = const DartModelMapper().map(
        api,
        const GenerationConfig(usePresenceRecords: true),
      );
      final DartDtoModel dto = model.libraries
          .expand((l) => l.dtos)
          .singleWhere((d) => d.name == 'Payload');
      final Map<String?, DartFieldModel> fields = {
        for (final field in dto.fields) field.wireName: field,
      };
      for (final key in ['name', 'strict', 'absent']) {
        expect(fields[key]!.isRequired, isTrue);
      }
      for (final key in ['note', 'label', 'optional_strict']) {
        expect(fields[key]!.isRequired, isFalse);
      }
      expect(fields['name']!.acceptsNull, isTrue);
      expect(fields['strict']!.acceptsNull, isFalse);
      expect(fields['absent']!.acceptsNull, isFalse);
      expect(fields['note']!.tracksPresence, isTrue);
      expect(fields['label']!.tracksPresence, isFalse);
      expect(fields['label']!.defaultValue!.value, 'North');
      expect(fields['optional_strict']!.acceptsNull, isFalse);
    }
  });

  test('ignores x-nullable in OpenAPI 3.x', () async {
    for (final version in ['3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final GenerationResult result = await _generate(
          'ignored_v$version',
          ext,
          DtoSerializer.plain,
        );
        final String source = result.files.map((f) => f.content).join();
        expect(source, contains('final String name;'));
        expect(source, isNot(contains('String? name')));
      }
    }
  });

  test('rejects non-boolean Swagger x-nullable values', () async {
    for (final stem in ['invalid_string', 'invalid_null']) {
      for (final ext in ['json', 'yaml']) {
        await expectLater(
          _generate(stem, ext, DtoSerializer.plain),
          throwsA(isA<GenerationException>()),
        );
      }
    }
  });
}
