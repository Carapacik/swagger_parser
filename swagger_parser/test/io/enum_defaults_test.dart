@TestOn('vm')
library;

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

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    test('$version resolves enum defaults to declared members once', () async {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          for (final enabled in [false, true]) {
            Map<String, String>? baseline;
            for (final ext in ['json', 'yaml']) {
              final mapper = _Mapper();
              final GenerationResult result =
                  await SwaggerParserRunner(mapper: mapper).generate(
                    await const FileSchemaSourceLoader().loadPath(
                      'test/fixtures/enum_defaults/$version.$ext',
                    ),
                    config: GenerationConfig(
                      serializer: serializer,
                      httpClient: backend,
                      applyParameterDefaults: enabled,
                      naming: _naming,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final Map<String, DartEnumModel> enums = {
                for (final e in mapper.model.libraries.expand((l) => l.enums))
                  e.name: e,
              };
              final DartDtoModel dto = mapper.model.libraries
                  .expand((l) => l.dtos)
                  .singleWhere((d) => d.name == 'Settings');
              final Map<String, DartFieldModel> fields = {
                for (final f in dto.fields) f.wireName!: f,
              };
              expect(fields['unit']!.defaultExpression, 'Unit.celsius');
              expect(fields['sort']!.defaultExpression, 'Sort.asc');
              expect(
                fields['inlineState']!.defaultExpression,
                'SettingsInlineState.ready',
              );
              expect(fields['numeric']!.defaultExpression, 'Numeric.high');
              for (final DartFieldModel field in fields.values) {
                _declaredDefault(
                  enums,
                  field.type,
                  field.defaultValue?.value,
                  field.defaultExpression,
                );
              }
              final List<DartClientOperation> operations = mapper
                  .model
                  .libraries
                  .expand((l) => l.operations)
                  .toList();
              expect(
                operations.map((o) => o.name),
                containsAll([
                  'getDefaults',
                  'submitForm',
                  'submitMultipart',
                  'saveSettings',
                ]),
              );
              final DartClientOperation query = operations.singleWhere(
                (o) => o.name == 'getDefaults',
              );
              for (final DartClientParameter parameter in query.parameters) {
                expect(parameter.defaultValue != null, enabled);
                if (enabled) {
                  _declaredDefault(
                    enums,
                    parameter.type,
                    parameter.defaultValue!.value.value,
                    parameter.defaultValue!.expression,
                  );
                }
                if (parameter.wireName == 'inlineState') {
                  expect(
                    enums[parameter.type.symbol]!.values['ready'],
                    'success',
                  );
                }
                if (parameter.wireName == 'numeric') {
                  expect(enums[parameter.type.symbol]!.values['high'], 5);
                }
              }
              for (final DartFormField field
                  in operations
                      .where((o) => o.name.startsWith('submit'))
                      .expand((o) => o.body!.fields)) {
                expect(
                  field.defaultValue != null,
                  enabled && field.key != 'token',
                );
                if (enabled && field.defaultValue != null) {
                  _declaredDefault(
                    enums,
                    field.type,
                    field.defaultValue!.value.value,
                    field.defaultValue!.expression,
                  );
                }
                if (field.key == 'inlineState') {
                  expect(enums[field.type.symbol]!.values['ready'], 'success');
                }
                if (field.key == 'numeric') {
                  expect(enums[field.type.symbol]!.values['high'], 5);
                }
              }
              expect(
                files.values.join(),
                contains('/// Settings body.\n/// Keep enum wire values.'),
              );
              expect(
                files['default_client/api_client.dart'],
                contains('/// Save settings.\n  /// Keep enum wire values.'),
              );
              if (backend == HttpClientBackend.retrofit) {
                expect(
                  files['default_client/api_client.dart'],
                  contains('@Body() required Settings body'),
                );
              }
            }
          }
        }
      }
    });

    test(
      '$version rejects case-mismatched DTO and parameter defaults',
      () async {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          for (final ext in ['json', 'yaml']) {
            final SchemaSource dto = await const FileSchemaSourceLoader()
                .loadPath(
                  'test/fixtures/enum_defaults/${version}_invalid_dto.$ext',
                );
            await expectLater(
              const SwaggerParserRunner().generate(
                dto,
                config: GenerationConfig(serializer: serializer),
              ),
              throwsA(
                isA<GenerationException>().having(
                  (e) => e.message,
                  'message',
                  contains('Unknown enum value'),
                ),
              ),
            );
            final SchemaSource query = await const FileSchemaSourceLoader()
                .loadPath(
                  'test/fixtures/enum_defaults/${version}_invalid_query.$ext',
                );
            final GenerationResult omitted = await const SwaggerParserRunner()
                .generate(
                  query,
                  config: GenerationConfig(serializer: serializer),
                );
            expect(omitted.diagnostics, isEmpty);
            for (final HttpClientBackend backend in HttpClientBackend.values) {
              await expectLater(
                const SwaggerParserRunner().generate(
                  query,
                  config: GenerationConfig(
                    serializer: serializer,
                    httpClient: backend,
                    applyParameterDefaults: true,
                  ),
                ),
                throwsA(
                  isA<GenerationException>()
                      .having(
                        (e) => e.diagnostics.single.code,
                        'code',
                        'invalidParameterDefault',
                      )
                      .having(
                        (e) => e.diagnostics.single.sourceUri,
                        'URI',
                        query.uri,
                      )
                      .having(
                        (e) => e.diagnostics.single.documentPath,
                        'pointer',
                        version == 'v2'
                            ? '/paths/~1invalid/get/parameters/0'
                            : '/paths/~1invalid/get/parameters/0/schema',
                      ),
                ),
              );
            }
          }
        }
      },
    );
  }
}

void _declaredDefault(
  Map<String, DartEnumModel> enums,
  DartTypeReference type,
  Object? value,
  String? expression,
) {
  if (value == null || !enums.containsKey(type.symbol)) {
    return;
  }
  final String member = enums[type.symbol]!.values.entries
      .singleWhere((e) => e.value == value)
      .key;
  expect(expression, '${type.symbol}.$member');
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;
  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
