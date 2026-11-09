@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/cli/output_writer.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/model_selection';
const _rules = [
  ParameterExclusion(name: 'x-trace-id', location: 'header'),
  ParameterExclusion(
    name: 'debug',
    location: 'query',
    paths: ['/stations/**'],
    methods: ['GET'],
  ),
  ParameterExclusion(name: 'session', location: 'cookie'),
];

Future<GenerationResult> _generate(
  String family,
  String ext,
  GenerationConfig config,
) async {
  const loader = FileSchemaSourceLoader();
  return await const SwaggerParserRunner().generate(
    await loader.loadPath('$_base/$family.$ext'),
    loader: loader,
    config: config,
  );
}

void main() {
  test('excludes wire parameters and prunes dependencies across versions and clients', () async {
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        for (final ResponseMode mode in ResponseMode.values) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await _generate(
              family,
              ext,
              GenerationConfig(
                httpClient: backend,
                responseMode: mode,
                excludeParameters: _rules,
                pruneUnusedModels: true,
                applyParameterDefaults: true,
                keepModels: [
                  '#/${family == 'v2' ? 'definitions' : 'components/schemas'}/AuditRecord',
                ],
              ),
            );
            expect(result.diagnostics.map((d) => d.code), [
              'excludedRequiredParameter',
            ]);
            expect(
              result.diagnostics.single.sourceUri.toString(),
              endsWith('${family == 'v2' ? 'header_v2' : 'header'}.$ext'),
            );
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            expected ??= files;
            expect(files, expected);
            final String source = files.values.join();
            for (final removed in [
              'X-Trace-Id',
              'xTraceId',
              'UnusedA',
              'UnusedB',
              'UnusedAlias',
              'GetStationDebug',
            ]) {
              expect(source, isNot(contains(removed)));
            }
            expect(source, contains('getOther('));
            for (final name in [
              'AuditRecord',
              'AuditDetail',
              'Tree',
              'Detail',
            ]) {
              expect(source, contains('class $name'));
            }
            expect(
              source.contains('class Problem'),
              mode == ResponseMode.allStatuses,
            );
            expect(files['exports.dart'], contains('models/audit_record.dart'));
          }
        }
      }
    }
  });

  test(
    'retains complete filtered graphs after declaration reordering',
    () async {
      for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('$_base/$family.json');
        final document = jsonDecode(source.content) as Map<String, dynamic>;
        final definitions = family == 'v2'
            ? document['definitions'] as Map<String, dynamic>
            : (document['components'] as Map<String, dynamic>)['schemas']
                  as Map<String, dynamic>;
        final reversed = Map<String, dynamic>.fromEntries(
          definitions.entries.toList().reversed,
        );
        definitions
          ..clear()
          ..addAll(reversed);
        for (final filter in const [
          OperationFilterConfig(includeTags: ['Stations']),
          OperationFilterConfig(excludePaths: ['/other']),
        ]) {
          final config = GenerationConfig(
            pruneUnusedModels: true,
            operationFilters: filter,
          );
          final GenerationResult original = await _generate(
            family,
            'json',
            config,
          );
          final GenerationResult reordered = await const SwaggerParserRunner()
              .generate(
                SchemaSource(
                  jsonEncode(document),
                  format: SchemaFormat.json,
                  uri: source.uri,
                ),
                loader: const FileSchemaSourceLoader(),
                config: config,
              );
          Map<String, String> files(GenerationResult result) => {
            for (final file in result.files) file.relativePath: file.content,
          };
          expect(files(reordered), files(original));
          final String text = original.files.map((f) => f.content).join();
          for (final name in [
            'DeepGraph',
            'DeepShared',
            'DeepGraphNested',
            'DeepGraphNestedSecondItem',
            'DeepGraphNestedSecondItemThird',
          ]) {
            expect(text, contains('class $name'));
          }
          expect(text, isNot(contains('class UnusedA')));
          if (family != 'v2') {
            for (final name in [
              'ParameterOnly',
              'PathOnly',
              'QueryOnly',
              'CookieOnly',
            ]) {
              expect(text, contains('enum $name'));
            }
            expect(text, contains('class FlatOnly'));
          }
        }
      }
    },
  );

  test('keeps all named models by default and validates keep roots', () async {
    for (final ext in ['json', 'yaml']) {
      final GenerationResult all = await _generate(
        'v3_2',
        ext,
        const GenerationConfig(
          excludeParameters: _rules,
          operationFilters: OperationFilterConfig(includePaths: []),
        ),
      );
      expect(all.files.map((f) => f.content).join(), contains('class UnusedA'));
      final GenerationResult empty = await _generate(
        'v3_2',
        ext,
        const GenerationConfig(
          pruneUnusedModels: true,
          operationFilters: OperationFilterConfig(includePaths: []),
        ),
      );
      expect(empty.files.map((f) => f.relativePath), [
        'api.dart',
        'exports.dart',
      ]);
      final GenerationResult kept = await _generate(
        'v3_2',
        ext,
        const GenerationConfig(
          pruneUnusedModels: true,
          operationFilters: OperationFilterConfig(includePaths: []),
          keepModels: [
            '#/components/schemas/KeptAlias',
            '#/components/schemas/Station',
          ],
        ),
      );
      final String source = kept.files.map((f) => f.content).join();
      expect(source, contains('class AuditRecord'));
      expect(source, contains('class AuditDetail'));
      expect(source, contains(r'class Station$Request'));
      expect(source, contains(r'class Station$Response'));
      expect(source, isNot(contains('class UnusedA')));
      for (final selector in [
        'Station',
        '#/components/schemas/Typo',
        '#/paths',
        'other.yaml#/components/schemas/Station',
      ]) {
        await expectLater(
          _generate('v3_2', ext, GenerationConfig(keepModels: [selector])),
          throwsA(isA<GenerationException>()),
        );
      }
    }
  });

  test(
    'preserves source parameters and applies case and method selectors',
    () async {
      const loader = FileSchemaSourceLoader();
      final SchemaSource input = await loader.loadPath('$_base/v3_2.yaml');
      final OpenApiDocument document = const OpenApiParser().parse(input);
      final ReferenceGraph graph = await const OpenApiReferenceResolver()
          .resolve(document, sourceUri: input.uri, loader: loader);
      final ApiDefinition api = const ApiDefinitionExtractor().extract(
        document,
        graph,
      );
      final List<ApiParameter> original = api.operations.first.parameters;
      final DartGenerationModel mapped = const DartModelMapper().map(
        api,
        const GenerationConfig(
          excludeParameters: [
            ParameterExclusion(name: 'DEBUG', location: 'query'),
            ParameterExclusion(
              name: 'debug',
              location: 'query',
              methods: ['POST'],
            ),
            ParameterExclusion(name: 'not-present', location: 'header'),
          ],
        ),
      );
      expect(mapped.diagnostics, isEmpty);
      expect(
        mapped.libraries
            .expand((l) => l.operations)
            .firstWhere((op) => op.name == 'getStation')
            .parameters
            .map((p) => p.wireName),
        contains('debug'),
      );
      const DartModelMapper().map(
        api,
        const GenerationConfig(excludeParameters: _rules),
      );
      expect(api.operations.first.parameters, same(original));
      expect(original.map((p) => p.name), containsAll(['debug', 'X-Trace-Id']));
      expect(
        () => const DartModelMapper().map(
          api,
          const GenerationConfig(
            excludeParameters: [
              ParameterExclusion(name: 'id', location: 'path'),
            ],
          ),
        ),
        throwsA(isA<GenerationException>()),
      );
    },
  );

  test('inherits selection fields and replaces input lists', () async {
    for (final ext in ['json', 'yaml']) {
      final CliConfig defaults = await CliConfig.load(
        configPath: '$_base/default.$ext',
      );
      expect(defaults.generation.pruneUnusedModels, isFalse);
      expect(defaults.generation.keepModels, isEmpty);
      expect(defaults.generation.excludeParameters, isEmpty);
      final CliConfig enabled = await CliConfig.load(
        configPath: '$_base/enabled.$ext',
      );
      expect(enabled.generation.excludeParameters, hasLength(3));
      expect(enabled.generation.pruneUnusedModels, isTrue);
      final List<CliConfig> inputs = await CliConfig.loadAll(
        configPath: '$_base/inputs.$ext',
      );
      expect(inputs.first.generation.excludeParameters, hasLength(3));
      expect(inputs.first.generation.keepModels, hasLength(1));
      expect(inputs.last.generation.excludeParameters, isEmpty);
      expect(inputs.last.generation.keepModels, isEmpty);
      expect(inputs.last.generation.pruneUnusedModels, isFalse);
      for (final name in [
        'path',
        'location',
        'name',
        'pattern',
        'method',
        'null',
        'key',
        'prune',
        'keep',
      ]) {
        await expectLater(
          CliConfig.load(configPath: '$_base/invalid_$name.$ext'),
          throwsA(isA<FormatException>()),
        );
      }
    }
  });

  test(
    'removes obsolete generated models and preserves application files',
    () async {
      final Directory dir = await Directory.systemTemp.createTemp(
        'model_selection_',
      );
      addTearDown(() => dir.delete(recursive: true));
      final GenerationResult all = await _generate(
        'v3_2',
        'yaml',
        const GenerationConfig(),
      );
      await writeOutput(dir, all.files);
      final app = File('${dir.path}/custom.dart');
      await app.writeAsString('// Application file.\n');
      final GenerationResult pruned = await _generate(
        'v3_2',
        'yaml',
        const GenerationConfig(
          pruneUnusedModels: true,
          excludeParameters: _rules,
        ),
      );
      await writeOutput(dir, pruned.files);
      expect(File('${dir.path}/models/unused_a.dart').existsSync(), isFalse);
      expect(await app.readAsString(), '// Application file.\n');
      expect(await checkOutput(dir, pruned.files), isEmpty);
    },
  );
}
