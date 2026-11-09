@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _naming = NamingConfig(
  replaceRules: [
    NameReplacementRule(
      target: NamingTarget.enumValues,
      pattern: '^LEGACY_',
      replacement: '',
    ),
  ],
);

Future<SchemaSource> _load(String stem, String ext) =>
    const FileSchemaSourceLoader().loadPath(
      'test/fixtures/enum_names/$stem.$ext',
    );

Future<GenerationResult> _generate(
  String stem,
  String ext,
  DtoSerializer serializer,
) async => await const SwaggerParserRunner().generate(
  await _load(stem, ext),
  config: GenerationConfig(serializer: serializer, naming: _naming),
);

Future<GenerationResult> _invalid(
  String name,
  String version,
  String ext,
) async {
  final SchemaSource source = await _load('invalid_v$version', ext);
  final Map<String, Object?> document = const OpenApiParser()
      .parse(source)
      .toJson();
  final schemas =
      (document['definitions'] ??
              (document['components']! as Map<String, Object?>)['schemas'])!
          as Map<String, Object?>;
  final Object? selected = schemas[name];
  expect(selected, isNotNull);
  schemas
    ..clear()
    ..['Invalid'] = selected;
  return await const SwaggerParserRunner().generate(
    SchemaSource.json(jsonEncode(document), uri: source.uri),
    config: const GenerationConfig(naming: _naming),
  );
}

void main() {
  test('renders enum labels from JSON and YAML in all families', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        final GenerationResult json = await _generate(
          'names_v$version',
          'json',
          serializer,
        );
        final GenerationResult yaml = await _generate(
          'names_v$version',
          'yaml',
          serializer,
        );
        expect(json.diagnostics, isEmpty);
        expect(yaml.diagnostics, isEmpty);
        expect(
          {for (final f in json.files) f.relativePath: f.content},
          {for (final f in yaml.files) f.relativePath: f.content},
        );
      }
    }
  });

  test('allocates safe names without changing wire values', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await _load('names_v$version', ext);
        final OpenApiDocument document = const OpenApiParser().parse(source);
        final Map<String, Object?> before = document.toJson();
        final ReferenceGraph graph = await const OpenApiReferenceResolver()
            .resolve(document, sourceUri: source.uri);
        final ApiDefinition api = const ApiDefinitionExtractor().extract(
          document,
          graph,
        );
        final DartGenerationModel model = const DartModelMapper().map(
          api,
          const GenerationConfig(naming: _naming),
        );
        final Map<String, Map<String, Object>> enums = {
          for (final library in model.libraries)
            for (final value in library.enums) value.name: value.values,
        };
        expect(enums['Status'], {'pending': 0, 'active': 1, 'disabled': 2});
        expect(enums['Mode'], {'queued': 'q', 'running': 'r', 'stopped': 's'});
        expect(enums['Priority'], {'preferredLow': 10, 'preferredHigh': 20});
        expect(enums['IgnoredLabels'], {'selected': 'ok'});
        expect(enums['Fallback'], {'field0': 0, 'field1': 1});
        expect(enums['Special'], {
          'default2': 'a',
          'values2': 'b',
          'inProgress': 'c',
          'inProgress2': 'd',
          'field123start': 'e',
          'spacedName': 'line\n"\$quote',
        });
        expect(enums['Replacement'], {'ready': 'wire'});
        expect(enums['Flag'], {'enabled': true, 'disabled': false});
        expect(enums['Fraction'], {'low': 1.5, 'high': 2.5});
        expect(enums['NullableChoice'], {'first': 'first', 'last': 'last'});
        expect(document.toJson(), before);
      }
    }
  });

  test('rejects malformed selected enum labels with a source path', () async {
    const errors = {
      'short': 'x-enumNames',
      'long': 'x-enum-varnames',
      'not_list': 'x-enumNames',
      'not_string': 'x-enum-varnames/1',
      'empty': 'x-enumNames/1',
      'blank': 'x-enum-varnames/1',
      'priority': 'x-enumNames',
      'null_slot': 'x-enumNames/1',
    };
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        for (final MapEntry<String, String> error in errors.entries) {
          await expectLater(
            _invalid(error.key, version, ext),
            throwsA(
              isA<GenerationException>()
                  .having(
                    (e) => e.diagnostics.single.documentPath,
                    'path',
                    endsWith('/Invalid/${error.value}'),
                  )
                  .having(
                    (e) => e.diagnostics.single.sourceUri.toString(),
                    'source',
                    endsWith('invalid_v$version.$ext'),
                  ),
            ),
          );
        }
      }
    }
  });

  test('keeps the original enum index when const narrows the values', () async {
    for (final version in ['3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final GenerationResult result = await _generate(
          'names_v$version',
          ext,
          DtoSerializer.plain,
        );
        expect(
          result.files.map((f) => f.content).join(),
          contains('chosen(1)'),
        );
      }
    }
  });
}
