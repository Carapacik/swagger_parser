@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('maps scalar fixtures across versions and serializers', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      final CliConfig cli = await CliConfig.load(
        configPath: 'test/fixtures/type_mappings/config_v$version.yaml',
      );
      expect(cli.generation.typeMappings, hasLength(7));
      for (final DtoSerializer serializer in DtoSerializer.values) {
        Map<String, String>? expected;
        for (final ext in ['json', 'yaml']) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await const FileSchemaSourceLoader().loadPath(
                  'test/fixtures/type_mappings/mapped_v$version.$ext',
                ),
                config: GenerationConfig(
                  serializer: serializer,
                  typeMappings: cli.generation.typeMappings,
                ),
              );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final f in result.files) f.relativePath: f.content,
          };
          expected ??= files;
          expect(files, expected);
          expect(
            files.keys.any((p) => p.endsWith('/station_id.dart')),
            isFalse,
          );
          expect(
            files['exports.dart'],
            contains('package:swagger_parser_tests/custom_types.dart'),
          );
          final String source = files.values.join();
          expect(source, contains('mapped1.StationId'));
          expect(source, contains('mapped2.stationIdFromJson'));
          expect(source, contains('mapped2.externalIdFromJson'));
        }
      }
    }
  });
  test('resolves exact selectors by document identity', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final prefix = version == '2_0'
            ? '/definitions/'
            : '/components/schemas/';
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/type_mappings/entry_v$version.$ext');
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(
              source,
              loader: const FileSchemaSourceLoader(),
              config: GenerationConfig(
                typeMappings: [
                  mapping(
                    schema:
                        'external_v$version.$ext#$prefix'
                        'StationId',
                  ),
                ],
              ),
            );
        final String code = result.files.map((f) => f.content).join();
        expect(code, contains('mapped1.DomainId'));
        expect(code, contains('class StationId'));
        expect(code, isNot(contains('class DomainId')));
      }
    }
  });

  test('rejects invalid selectors, symbols, and imports', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final prefix = version == '2_0'
            ? '#/definitions/'
            : '#/components/schemas/';
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/type_mappings/mapped_v$version.$ext');
        final TypeMapping exact = mapping(schema: '${prefix}StationId');
        for (final rules in <List<TypeMapping>>[
          [exact, exact],
          [mapping(schema: '${prefix}Missing')],
          [
            mapping(
              schema: '${prefix}StationId',
              type: 'string',
              format: 'station-id',
            ),
          ],
          [mapping(type: 'object', format: 'station-id')],
          [mapping(type: 'string')],
          [mapping(schema: 'StationId')],
          [mapping(type: 'string', format: 'station-id', dartType: '_Private')],
          [mapping(type: 'string', format: 'station-id', dartType: 'Api')],
          [
            mapping(
              type: 'string',
              format: 'station-id',
              importUrl: '../domain.dart',
            ),
          ],
          [mapping(type: 'string', format: 'station-id', fromJson: 'make()')],
          [mapping(type: 'string', format: 'station-id', fromJson: 'class')],
          [
            exact,
            mapping(
              type: 'string',
              format: 'station-id',
              importUrl: 'package:other/domain.dart',
            ),
          ],
        ]) {
          await expectLater(
            const SwaggerParserRunner().generate(
              source,
              config: GenerationConfig(typeMappings: rules),
            ),
            throwsA(isA<GenerationException>()),
          );
        }
      }
    }
  });

  test(
    'keeps empty mappings compatible and preserves external names',
    () async {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/type_mappings/mapped_v3_2.yaml',
      );
      final GenerationResult original = await const SwaggerParserRunner()
          .generate(source);
      expect(
        original.files.map((f) => f.content).join(),
        isNot(contains('custom_types.dart')),
      );
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            source,
            config: GenerationConfig(
              naming: const NamingConfig(
                replaceRules: [
                  NameReplacementRule(
                    target: NamingTarget.models,
                    pattern: 'Domain',
                    replacement: 'Changed',
                  ),
                ],
              ),
              typeMappings: [mapping(schema: '#/components/schemas/StationId')],
            ),
          );
      final String code = result.files.map((f) => f.content).join();
      expect(code, contains('mapped1.DomainId'));
      expect(code, isNot(contains('ChangedId')));
      expect(
        result.files
            .singleWhere((f) => f.relativePath == 'exports.dart')
            .content,
        isNot(contains('codecs.dart')),
      );
    },
  );
}

TypeMapping mapping({
  String? schema,
  String? type,
  String? format,
  String dartType = 'DomainId',
  String importUrl = 'package:app/domain.dart',
  String fromJson = 'readId',
}) => TypeMapping(
  schema: schema,
  type: type,
  format: format,
  dartType: dartType,
  importUrl: importUrl,
  codec: TypeMappingCodec(
    importUrl: 'package:app/codecs.dart',
    fromJson: fromJson,
    toJson: 'writeId',
  ),
);
