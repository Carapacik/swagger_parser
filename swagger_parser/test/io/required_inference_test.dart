@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('projects required fields without changing source schemas', () async {
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      final bool modern = version == 'v3_1' || version == 'v3_2';
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final infer in [false, true]) {
          for (final records in [false, true]) {
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              final mapper = _Mapper();
              final SchemaSource source = await const FileSchemaSourceLoader()
                  .loadPath('test/fixtures/required_inference/$version.$ext');
              final GenerationResult result =
                  await SwaggerParserRunner(mapper: mapper).generate(
                    source,
                    loader: const FileSchemaSourceLoader(),
                    config: GenerationConfig(
                      serializer: serializer,
                      inferMissingRequired: infer,
                      usePresenceRecords: records,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final Map<String, DartDtoModel> dtos = {
                for (final dto in mapper.model.libraries.expand((l) => l.dtos))
                  dto.name: dto,
              };
              Set<String> required(String name) => dtos[name]!.fields
                  .where((f) => f.isRequired)
                  .map((f) => f.wireName!)
                  .toSet();
              expect(required('Station'), infer ? {'id', 'refValue'} : isEmpty);
              expect(
                required('Empty'),
                infer && !modern ? {'id', 'refValue'} : isEmpty,
              );
              expect(required('Partial'), {'name'});
              expect(required('Base'), infer ? {'base'} : isEmpty);
              expect(
                required('AllMissing'),
                infer ? {'first', 'second'} : isEmpty,
              );
              expect(
                required('AllEmpty'),
                infer && !modern ? {'base', 'extra'} : isEmpty,
              );
              expect(
                required('AllParentEmpty'),
                infer && !modern ? {'base', 'extra'} : isEmpty,
              );
              expect(required('AllPartial'), {'first'});
              expect(required('Nested'), infer ? {'child'} : isEmpty);
              expect(required('RequiredChild'), {'value'});
              final inferred = {'composed', 'plain', 'Code', 'code'};
              expect(required('SiblingMissing'), infer ? inferred : isEmpty);
              expect(required('SiblingDirect'), required('SiblingMissing'));
              expect(required('SiblingExplicit'), {
                'nullable_id',
                'Code',
                'required_default',
              });
              expect(required('SiblingReduced'), {'nullable_id'});
              if (modern) {
                expect(required('SiblingEmpty'), isEmpty);
              }
              for (final dtoName in [
                'SiblingMissing',
                'SiblingDirect',
                'SiblingExplicit',
                'SiblingReduced',
                if (modern) 'SiblingEmpty',
              ]) {
                final DartDtoModel dto = dtos[dtoName]!;
                final Map<String, DartFieldModel> fields = {
                  for (final field in dto.fields) field.wireName!: field,
                };
                expect(
                  fields.keys,
                  unorderedEquals([
                    'composed',
                    'plain',
                    'Code',
                    'code',
                    'nullable_id',
                    'nullable_ref',
                    'enabled',
                    'ref_default',
                    'required_default',
                  ]),
                );
                expect(dto.fields.map((f) => f.name).toSet(), hasLength(9));
                final DartFieldModel plain = fields['plain']!;
                expect(plain.acceptsNull, isFalse);
                expect(plain.type.symbol, 'bool');
                expect(plain.type.isNullable, !plain.isRequired);
                expect(plain.tracksPresence, isFalse);
                expect(fields['enabled']!.defaultExpression, 'true');
                expect(fields['nullable_id']!.acceptsNull, isTrue);
                expect(
                  fields['nullable_id']!.tracksPresence,
                  records && !fields['nullable_id']!.isRequired,
                );
                expect(fields['nullable_ref']!.tracksPresence, records);
                expect(
                  fields['required_default']!.defaultExpression,
                  dtoName == 'SiblingExplicit' ? isNull : '7',
                );
              }
              final DartFieldModel name = dtos['Station']!.fields.singleWhere(
                (f) => f.name == 'name',
              );
              expect(name.tracksPresence, records);
              expect(name.type.symbol, 'String');
              expect(name.type.isNullable, true);
              expect(
                dtos['Station']!.fields
                    .singleWhere((f) => f.name == 'enabled')
                    .defaultExpression,
                'true',
              );
              final DartClientOperation op = mapper.model.libraries
                  .expand((l) => l.operations)
                  .singleWhere((op) => op.name == 'getStation');
              expect(op.parameters.single.isRequired, false);
              expect(
                mapper.model.libraries
                    .expand((l) => l.operations)
                    .singleWhere((op) => op.name == 'updateStation')
                    .body!
                    .isRequired,
                false,
              );
              if (version == 'v3_1' || version == 'v3_2') {
                expect(required('Modern'), infer ? {'restricted'} : isEmpty);
              }
              final ApiSchema original =
                  mapper.api.schemas[mapper.api.namedSchemas['Station']]!;
              expect(original.requiredProperties, isEmpty);
              expect(
                original.definition.value! as Map,
                isNot(contains('required')),
              );
            }
          }
        }
      }
    }
  });

  test('keeps legacy empty-required validation', () async {
    for (final version in ['v2', 'v3_0']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/required_inference/${version}_invalid_empty.$ext',
            );
        await expectLater(
          const SwaggerParserRunner().generate(source),
          throwsA(isA<OpenApiException>()),
        );
      }
    }
  });

  test('rejects case-mismatched required names in closed objects', () async {
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/required_inference/${version}_invalid_case.$ext',
            );
        for (final DtoSerializer serializer in DtoSerializer.values) {
          await expectLater(
            const SwaggerParserRunner().generate(
              source,
              config: GenerationConfig(serializer: serializer),
            ),
            throwsA(
              isA<GenerationException>()
                  .having(
                    (e) => e.message,
                    'message',
                    contains('undeclared or conflicting required properties'),
                  )
                  .having(
                    (e) => e.diagnostics.single.sourceUri,
                    'URI',
                    source.uri,
                  )
                  .having(
                    (e) => e.diagnostics.single.documentPath,
                    'pointer',
                    version == 'v2'
                        ? '/definitions/Invalid'
                        : '/components/schemas/Invalid',
                  ),
            ),
          );
        }
      }
    }
  });

  test('loads defaults and per-input overrides from JSON and YAML', () async {
    expect(const GenerationConfig().inferMissingRequired, false);
    expect(const GenerationConfig().usePresenceRecords, false);
    for (final ext in ['json', 'yaml']) {
      final CliConfig defaults = await CliConfig.load(
        configPath: 'test/fixtures/required_inference/config_default.$ext',
      );
      expect(defaults.generation.inferMissingRequired, false);
      expect(defaults.generation.usePresenceRecords, false);
      final CliConfig disabled = await CliConfig.load(
        configPath: 'test/fixtures/required_inference/config_false.$ext',
      );
      expect(disabled.generation.inferMissingRequired, false);
      expect(disabled.generation.usePresenceRecords, true);
      final List<CliConfig> inputs = await CliConfig.loadAll(
        configPath: 'test/fixtures/required_inference/config_inputs.$ext',
      );
      expect(inputs.map((c) => c.generation.inferMissingRequired), [
        false,
        true,
      ]);
      expect(inputs.map((c) => c.generation.usePresenceRecords), [true, false]);
      await expectLater(
        CliConfig.load(
          configPath:
              'test/fixtures/required_inference/config_invalid_records.$ext',
        ),
        throwsA(isA<FormatException>()),
      );
      await expectLater(
        CliConfig.load(
          configPath: 'test/fixtures/required_inference/config_invalid.$ext',
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });
}

final class _Mapper() implements DartModelMapper {
  late ApiDefinition api;
  late DartGenerationModel model;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) {
    this.api = api;
    final Map<ReferenceLocation, JsonValue> before = {
      for (final entry in api.schemas.entries)
        entry.key: entry.value.definition,
    };
    model = const DartModelMapper().map(api, config);
    expect({
      for (final entry in api.schemas.entries)
        entry.key: entry.value.definition,
    }, before);
    return model;
  }
}
