@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';
import 'package:test/test.dart';

Future<SchemaSource> fixtureSource(String name) =>
    const FileSchemaSourceLoader().loadPath(
      '../swagger_parser/test/fixtures/extraction/$name',
    );

SwaggerParserRunner withTemplates(Map<String, String> templates) =>
    SwaggerParserRunner(
      generator: DartGenerator(renderer: MustacheSourceRenderer(templates)),
    );

void main() {
  const runner = SwaggerParserRunner();
  final Map<String, String> passthrough = {
    for (final kind in ['api', 'exports', 'models', 'client', 'results'])
      kind: '{{defaultSource}}',
  };

  test(
    'preserves escaped enum literals and errors through templates',
    () async {
      for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await const FileSchemaSourceLoader()
              .loadPath(
                '../swagger_parser/test/fixtures/naming/contracts/$family.$ext',
              );
          for (final DtoSerializer serializer in DtoSerializer.values) {
            final config = GenerationConfig(serializer: serializer);
            final GenerationResult expected = await runner.generate(
              source,
              config: config,
            );
            final GenerationResult actual = await withTemplates(passthrough)
                .generate(source, config: config);
            expect(
              {for (final f in actual.files) f.relativePath: f.content},
              {for (final f in expected.files) f.relativePath: f.content},
            );
          }
        }
      }
    },
  );

  test(
    'exposes source docs and independent deprecation to templates',
    () async {
      for (final docs in [false, true]) {
        final GenerationResult result =
            await withTemplates(const {
              'default_client/models/station.dart':
                  '{{defaultSource}}\n'
                  '// model: {{library.documentation.Station.summary}} {{library.documentation.Station.deprecated}}\n'
                  '// field: {{library.fieldDocumentation.Station.id.description}} {{library.fieldDocumentation.Station.id.deprecated}}',
              'client':
                  '{{defaultSource}}\n'
                  '{{#library.operations}}{{#parameters}}'
                  '// parameter: {{wireName}} {{deprecated}}\n'
                  '{{/parameters}}{{/library.operations}}',
            }).generate(
              await const FileSchemaSourceLoader().loadPath(
                '../swagger_parser/test/fixtures/documentation/v3_2.yaml',
              ),
              config: GenerationConfig(generateDocs: docs),
            );
        final String source = result.files.map((f) => f.content).join('\n');
        expect(
          source,
          contains('// model: ${docs ? 'Station summary.' : ''} true'),
        );
        expect(
          source,
          contains('// field: ${docs ? 'Station identifier.' : ''} true'),
        );
        expect(source, contains('// parameter: limit true'));
      }
    },
  );

  test('exposes the approved defaults in template context', () async {
    const marker =
        '// v{{contractVersion}} {{options.rootApiClassName}} {{options.httpClient}} '
        '{{options.serializer}} {{options.responseMode}} {{options.generateDocs}} '
        '{{options.streamBinaryResponses}} {{options.pageWidth}}';
    final GenerationResult result = await withTemplates(const {
      'api': '{{defaultSource}}\n$marker',
    }).generate(await fixtureSource('open_api_v3_2.yaml'));
    expect(
      result.files.singleWhere((f) => f.relativePath == 'api.dart').content,
      contains('// v1 Api retrofit plain firstSuccess true false 80'),
    );
  });

  test('exposes filters and retains named models in templates', () async {
    final CliConfig config = await CliConfig.load(
      configPath:
          '../swagger_parser/test/fixtures/operation_filters/config.yaml',
    );
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      '../swagger_parser/test/fixtures/operation_filters/routes_v3_2.yaml',
    );
    final GenerationResult result = await withTemplates(const {
      'api': '''
{{defaultSource}}
// {{#options.operationFilters}}{{#includePaths}}{{.}} {{/includePaths}}{{#excludePaths}}{{.}} {{/excludePaths}}{{#includeTags}}{{.}} {{/includeTags}}{{#excludeTags}}{{.}} {{/excludeTags}}{{/options.operationFilters}}''',
    }).generate(source, config: config.generation);
    expect(
      result.files.singleWhere((f) => f.relativePath == 'api.dart').content,
      contains('// /stations/** /stations/private Public Internal'),
    );
    expect(
      result.files.map((f) => f.relativePath),
      contains('models/unused_enum.dart'),
    );
    expect(
      result.files.map((f) => f.relativePath),
      isNot(contains('internal/internal_client.dart')),
    );
  });

  test('exposes scalar mapping imports and codecs', () async {
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      '../swagger_parser/test/fixtures/type_mappings/mapped_v3_2.yaml',
    );
    final GenerationResult result =
        await withTemplates(const {
          'models': '{{defaultSource}}\n{{#library.dtos}}{{#fields}}{{#type.scalarCodec}}// {{dartType}} {{wireType}} {{typeImport}} {{fromJson}}\n{{/type.scalarCodec}}{{/fields}}{{/library.dtos}}',
          'api': '{{defaultSource}}\n{{#options.typeMappings}}// {{dartType}} {{codec.toJson}}\n{{/options.typeMappings}}',
        }).generate(
          source,
          config: const GenerationConfig(
            typeMappings: [
              TypeMapping(
                schema: '#/components/schemas/StationId',
                dartType: 'DomainId',
                importUrl: 'package:app/domain.dart',
                codec: TypeMappingCodec(
                  importUrl: 'package:app/codecs.dart',
                  fromJson: 'readId',
                  toJson: 'writeId',
                ),
              ),
            ],
          ),
        );
    expect(
      result.files.singleWhere((f) => f.relativePath == 'api.dart').content,
      contains('// DomainId writeId'),
    );
    expect(
      result.files
          .singleWhere((f) => f.relativePath.endsWith('/station.dart'))
          .content,
      contains('// DomainId String package:app/domain.dart readId'),
    );
  });

  test('exposes object codecs and constant imports', () async {
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      '../swagger_parser/test/fixtures/object_mappings/default_v3_2.yaml',
    );
    final GenerationResult result =
        await withTemplates(const {
          'models': '{{defaultSource}}\n{{#library.dtos}}{{#fields}}{{#type.scalarCodec}}// {{wireType}}{{#defaults}} {{expression}}{{/defaults}}\n{{/type.scalarCodec}}{{/fields}}{{/library.dtos}}',
          'api': '{{defaultSource}}\n{{#options.typeMappings}}{{#defaults}}// {{constant}} {{importUrl}}\n{{/defaults}}{{/options.typeMappings}}',
        }).generate(
          source,
          config: const GenerationConfig(
            typeMappings: [
              TypeMapping(
                schema: '#/components/schemas/Target/properties/point',
                dartType: 'GeoPoint',
                importUrl: 'package:app/domain.dart',
                codec: TypeMappingCodec(
                  importUrl: 'package:app/codecs.dart',
                  fromJson: 'readPoint',
                  toJson: 'writePoint',
                ),
                defaults: [
                  TypeMappingDefault(
                    value: {'latitude': 3, 'longitude': 4},
                    importUrl: 'package:app/defaults.dart',
                    constant: 'point',
                  ),
                ],
              ),
            ],
          ),
        );
    expect(
      result.files.singleWhere((f) => f.relativePath == 'api.dart').content,
      contains('// point package:app/defaults.dart'),
    );
    expect(
      result.files
          .singleWhere((f) => f.relativePath.endsWith('/target.dart'))
          .content,
      contains('// Map<String, Object?> mapped3.point'),
    );
  });

  test('exposes mapping directions to templates', () async {
    final CliConfig config = await CliConfig.load(
      configPath: '../swagger_parser/test/fixtures/directional_mappings/config_v3_2.yaml',
    );
    final GenerationResult result =
        await withTemplates(const {
          'api': '{{defaultSource}}\n{{#options.typeMappings}}// {{dartType}} {{direction}}\n{{/options.typeMappings}}',
        }).generate(
          await const FileSchemaSourceLoader().loadPath(
            '../swagger_parser/test/fixtures/directional_mappings/directional_v3_2.yaml',
          ),
          config: config.generation,
        );
    final String source = result.files
        .singleWhere((f) => f.relativePath == 'api.dart')
        .content;
    expect(source, contains('// CreateStation request'));
    expect(source, contains('// Station response'));
    expect(source, contains('// Label both'));
  });

  test('exposes PATCH presence and wire names from JSON and YAML', () async {
    for (final ext in ['json', 'yaml']) {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        '../swagger_parser_tests/test/fixtures/dto/serializers/dto_serializers.$ext',
      );
      final GenerationResult result =
          await withTemplates(const {
            'models': '{{#library.dtos}}{{#fields}}// {{name}} {{wireName}} {{tracksPresence}}\n{{/fields}}{{/library.dtos}}',
          }).generate(
            source,
            config: const GenerationConfig(usePresenceRecords: true),
          );
      String model(String suffix) => result.files
          .singleWhere((f) => f.relativePath.endsWith(suffix))
          .content;
      expect(model('/station_patch.dart'), contains('// name name true'));
      expect(
        model('/station_patch.dart'),
        contains('// sequence sequence false'),
      );
      expect(model('/platform_directory.dart'), contains(' station-id false'));
    }
  });

  test(
    'renders the built-in files from templates in all four families',
    () async {
      for (final family in [
        'swagger_v2',
        'open_api_v3_0',
        'open_api_v3_1',
        'open_api_v3_2',
      ]) {
        for (final ResponseMode mode in ResponseMode.values) {
          final GenerationResult expected = await runner.generate(
            await fixtureSource('$family.json'),
            config: GenerationConfig(responseMode: mode),
          );
          for (final ext in ['yaml', 'json']) {
            final SchemaSource source = await fixtureSource('$family.$ext');
            final GenerationResult actual = await withTemplates(passthrough)
                .generate(source, config: GenerationConfig(responseMode: mode));
            expect(
              [for (final f in actual.files) (f.relativePath, f.content)],
              [for (final f in expected.files) (f.relativePath, f.content)],
            );
            final GenerationResult context = await withTemplates(const {
              'models': '{{#library.dtos}}{{#fields}}// {{wireName}} {{type.symbol}} {{isRequired}} {{tracksPresence}}\n{{/fields}}{{/library.dtos}}',
              'client': '{{#library.operations}}// {{name}} {{response.symbol}}\n{{/library.operations}}',
              'results': '{{#library.results}}{{#variants}}// {{statusKey}} {{type.symbol}}\n{{/variants}}{{/library.results}}',
            }).generate(source, config: GenerationConfig(responseMode: mode));
            String output(String suffix) => context.files
                .singleWhere((f) => f.relativePath.endsWith(suffix))
                .content;
            expect(
              output('/station.dart'),
              contains('// parent Station false false'),
            );
            expect(
              output('/station.dart'),
              contains('// id String true false'),
            );
            if (mode == ResponseMode.firstSuccess) {
              expect(
                output('/api_client.dart'),
                contains('// getStationsById Station'),
              );
            } else {
              expect(
                output('/api_client_results.dart'),
                contains('// 404 Problem'),
              );
            }
          }
        }
      }
    },
  );
}
