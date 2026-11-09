@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'maps complete boolean enums without changing constrained types',
    () async {
      for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          for (final UnknownValueMode unknown in UnknownValueMode.values) {
            Map<String, String>? baseline;
            for (final extension in ['json', 'yaml']) {
              final mapper = _Mapper();
              final SchemaSource source = await const FileSchemaSourceLoader()
                  .loadPath(
                    'test/fixtures/enum_values/booleans/$version.$extension',
                  );
              final GenerationResult result =
                  await SwaggerParserRunner(mapper: mapper).generate(
                    source,
                    config: GenerationConfig(
                      usePresenceRecords: true,
                      serializer: serializer,
                      unknownEnumValues: unknown,
                      applyParameterDefaults: true,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final List<DartLibraryModel> libraries = mapper.model.libraries;
              final DartDtoModel settings = libraries
                  .expand((library) => library.dtos)
                  .singleWhere((dto) => dto.name == 'Settings');
              final Map<String, DartFieldModel> fields = {
                for (final field in settings.fields) field.wireName!: field,
              };
              for (final field in [
                'enabled',
                'reversed',
                'inferred',
                'nullable',
                'optional',
                'defaulted',
              ]) {
                expect(
                  fields[field]!.type.symbol,
                  'bool',
                  reason: '$version $serializer $field',
                );
              }
              expect(fields['enabled']!.type.isNullable, false);
              expect(fields['nullable']!.type.isNullable, true);
              expect(fields['notNullable']!.type.symbol, 'bool');
              expect(fields['notNullable']!.type.isNullable, false);
              expect(fields['optional']!.tracksPresence, true);
              expect(fields['defaulted']!.defaultExpression, 'false');
              expect(fields['flags']!.type.typeArguments.single.symbol, 'bool');
              expect(fields['byName']!.type.typeArguments.last.symbol, 'bool');
              expect(fields['named']!.type.symbol, 'Flag');
              final Map<String, DartValueModel> values = {
                for (final value in libraries.expand(
                  (library) => library.values,
                ))
                  value.name: value,
              };
              expect(values['Flag']!.type.symbol, 'bool');
              expect(values['Flag']!.type.isNullable, false);
              expect(values['NullableFlag']!.type.isNullable, true);
              final Map<String, DartEnumModel> enums = {
                for (final value in libraries.expand(
                  (library) => library.enums,
                ))
                  value.name: value,
              };
              expect(enums, isNot(contains('Flag')));
              expect(enums[fields['onlyTrue']!.type.symbol]!.values.values, [
                true,
              ]);
              expect(enums[fields['onlyFalse']!.type.symbol]!.values.values, [
                false,
              ]);
              expect(enums[fields['namedCases']!.type.symbol]!.values, {
                'enabled': true,
                'disabled': false,
              });
              expect(enums[fields['varNames']!.type.symbol]!.values, {
                'on2': true,
                'off': false,
              });
              expect(enums[fields['bothNames']!.type.symbol]!.values, {
                'yes': true,
                'no': false,
              });
              expect(enums[fields['mixed']!.type.symbol]!.values.values, [
                true,
                false,
                'unknown',
              ]);
              final DartClientOperation op = libraries
                  .expand((library) => library.operations)
                  .single;
              expect(op.parameters.single.type.symbol, 'bool');
              expect(op.parameters.single.defaultValue!.expression, 'true');
              if (version != 'v2') {
                expect(
                  libraries
                      .expand((library) => library.structuralUnions)
                      .map((union) => union.name),
                  containsAll(['TrueOrNull', 'AnyBoolean']),
                );
              }
              if (version == 'v3_1' || version == 'v3_2') {
                expect(enums[fields['constTrue']!.type.symbol]!.values.values, [
                  true,
                ]);
                expect(
                  enums[fields['constFalse']!.type.symbol]!.values.values,
                  [false],
                );
                expect(
                  libraries
                      .expand((library) => library.structuralUnions)
                      .map((union) => union.name),
                  contains('ConstChoice'),
                );
              }
            }
          }
        }
      }
    },
  );

  test('validates explicit boolean enum names before simplification', () async {
    for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final name in ['invalid_names', 'invalid_varnames']) {
        for (final extension in ['json', 'yaml']) {
          final SchemaSource
          source = await const FileSchemaSourceLoader().loadPath(
            'test/fixtures/enum_values/booleans/${version}_$name.$extension',
          );
          await expectLater(
            const SwaggerParserRunner().generate(source),
            throwsA(isA<GenerationException>()),
          );
        }
      }
    }
  });
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
