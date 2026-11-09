@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'maps objects and const defaults across versions and serializers',
    () async {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final CliConfig config = await CliConfig.load(
              configPath: 'test/fixtures/object_mappings/config_v$version.$ext',
            );
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await const FileSchemaSourceLoader().loadPath(
                    'test/fixtures/object_mappings/objects_v$version.$ext',
                  ),
                  config: GenerationConfig(
                    serializer: serializer,
                    typeMappings: config.generation.typeMappings,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            expected ??= files;
            expect(files, expected);
            final String source = files.values.join();
            expect(source, contains('mapped1.GeoPoint'));
            expect(source, contains('mapped2.geoPointFromJson'));
            expect(source, contains('mapped3.origin'));
            expect(source, contains('mapped3.east'));
            expect(source, contains('mapped3.unknownStationId'));
            expect(source, isNot(contains('class GeoPoint')));
            expect(
              files['exports.dart'],
              isNot(contains('object_defaults.dart')),
            );
          }
        }
      }
    },
  );
  test('rejects directional objects, containers, and missing constant defaults', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      final prefix = version == '2_0'
          ? '#/definitions/'
          : '#/components/schemas/';
      for (final ext in ['json', 'yaml']) {
        for (final stem in [
          'directional',
          'nested_directional',
          'array',
          'default',
        ]) {
          final schema =
              '${prefix}Target${stem == 'default' ? '/properties/point' : ''}';
          final SchemaSource source = await const FileSchemaSourceLoader()
              .loadPath('test/fixtures/object_mappings/${stem}_v$version.$ext');
          await expectLater(
            const SwaggerParserRunner().generate(
              source,
              config: GenerationConfig(typeMappings: [objectRule(schema)]),
            ),
            throwsA(isA<GenerationException>()),
          );
        }
      }
    }
  });

  test(
    'checks constant identifiers, imports, and structural duplicates',
    () async {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/object_mappings/default_v3_2.yaml',
      );
      const schema = '#/components/schemas/Target/properties/point';
      for (final entries in <List<TypeMappingDefault>>[
        [
          const TypeMappingDefault(
            value: {'latitude': 3, 'longitude': 4},
            importUrl: 'package:app/defaults.dart',
            constant: 'GeoPoint()',
          ),
        ],
        [
          const TypeMappingDefault(
            value: {'latitude': 3, 'longitude': 4},
            importUrl: '../defaults.dart',
            constant: 'point',
          ),
        ],
        [
          const TypeMappingDefault(
            value: {'latitude': 3, 'longitude': 4},
            importUrl: 'package:app/defaults.dart',
            constant: '_private',
          ),
        ],
        [
          const TypeMappingDefault(
            value: {'latitude': 3, 'longitude': 4},
            importUrl: 'package:app/defaults.dart',
            constant: 'class',
          ),
        ],
        [
          const TypeMappingDefault(
            value: double.infinity,
            importUrl: 'package:app/defaults.dart',
            constant: 'point',
          ),
        ],
        [
          const TypeMappingDefault(
            value: {'latitude': 3, 'longitude': 4},
            importUrl: 'package:app/defaults.dart',
            constant: 'point',
          ),
          const TypeMappingDefault(
            value: {'longitude': 4, 'latitude': 3},
            importUrl: 'package:app/defaults.dart',
            constant: 'other',
          ),
        ],
      ]) {
        await expectLater(
          const SwaggerParserRunner().generate(
            source,
            config: GenerationConfig(
              typeMappings: [objectRule(schema, defaults: entries)],
            ),
          ),
          throwsA(isA<GenerationException>()),
        );
      }
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            source,
            config: GenerationConfig(
              typeMappings: [
                objectRule(
                  schema,
                  defaults: [
                    const TypeMappingDefault(
                      value: {'longitude': 4, 'latitude': 3},
                      importUrl: 'package:app/defaults.dart',
                      constant: 'point',
                    ),
                  ],
                ),
              ],
            ),
          );
      expect(
        result.files.map((f) => f.content).join(),
        contains('mapped3.point'),
      );
    },
  );
  test('rejects mapped polymorphic unions', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/object_mappings/objects_v$version.$ext');
        final prefix = version == '2_0'
            ? '#/definitions/'
            : '#/components/schemas/';
        await expectLater(
          const SwaggerParserRunner().generate(
            source,
            config: GenerationConfig(
              typeMappings: [objectRule('${prefix}TaggedPlace')],
            ),
          ),
          throwsA(isA<GenerationException>()),
        );
      }
    }
  });
}

TypeMapping objectRule(
  String schema, {
  List<TypeMappingDefault> defaults = const [],
}) => TypeMapping(
  schema: schema,
  dartType: 'GeoPoint',
  importUrl: 'package:app/domain.dart',
  codec: const TypeMappingCodec(
    importUrl: 'package:app/codecs.dart',
    fromJson: 'readPoint',
    toJson: 'writePoint',
  ),
  defaults: defaults,
);
