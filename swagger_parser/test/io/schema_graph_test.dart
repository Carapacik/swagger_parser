@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<Map<String, String>> _generate(
  String path, {
  GenerationConfig config = const GenerationConfig(),
  ParseConfig? parseConfig,
}) async {
  final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
    path,
  );
  final watch = Stopwatch()..start();
  final GenerationResult result = await const SwaggerParserRunner().generate(
    source,
    config: config,
    parseConfig: parseConfig,
  );
  watch.stop();
  expect(result.diagnostics, isEmpty);
  stdout.writeln(
    jsonEncode({
      'input': path,
      'rules': config.naming.replaceRules.length,
      'elapsed_ms': watch.elapsedMilliseconds,
      'process_peak_rss_bytes': ProcessInfo.maxRss,
      'files': result.files.length,
    }),
  );
  return {for (final file in result.files) file.relativePath: file.content};
}

void main() {
  test(
    'terminates a 1100-node cyclic graph with nullable shared branches',
    () async {
      final Map<String, String> json = await _generate(
        'test/fixtures/schema_graphs/large_cycle/graph.json',
      );
      final Map<String, String> yaml = await _generate(
        'test/fixtures/schema_graphs/large_cycle/graph.yaml',
      );
      expect(yaml, json);
      expect(json.length, greaterThanOrEqualTo(1100));
      final String first = json.entries
          .singleWhere((e) => e.key.endsWith('/node0_dto.dart'))
          .value;
      final String last = json.entries
          .singleWhere((e) => e.key.endsWith('/node1099_dto.dart'))
          .value;
      expect(first, contains('Node1Dto? next'));
      expect(first, contains('Node1099Dto? peer'));
      expect(last, contains('Node0Dto? next'));
      expect(first, contains('SharedDto? shared'));
      expect(json.values.join(), contains('class NullableRootDto'));
      expect(
        await _generate(
          'test/fixtures/schema_graphs/large_cycle/graph.json',
          parseConfig: const ParseConfig(maxDepth: 32),
        ),
        json,
      );
    },
  );

  test(
    'preserves output with no-op and overlapping name replacements',
    () async {
      final CliConfig config = await CliConfig.load(
        configPath: 'test/fixtures/naming/replacements/rules.yaml',
      );
      final CliConfig jsonConfig = await CliConfig.load(
        configPath: 'test/fixtures/naming/replacements/rules.json',
      );
      final Map<String, String> baseline = await _generate(
        'test/fixtures/schema_graphs/large_cycle/graph.json',
      );
      expect(
        await _generate(
          'test/fixtures/schema_graphs/large_cycle/graph.json',
          config: const GenerationConfig(
            naming: NamingConfig(
              replaceRules: [
                NameReplacementRule(
                  target: NamingTarget.models,
                  pattern: r'NeverMatches$',
                  replacement: '',
                ),
              ],
            ),
          ),
        ),
        baseline,
      );
      final Map<String, String> expected = await _generate(
        'test/fixtures/naming/replacements/renamed.json',
      );
      expect(
        await _generate('test/fixtures/naming/replacements/renamed.yaml'),
        expected,
      );
      expect(expected.values.join(), contains('class NodeX0'));
      expect(
        expected.values.join(),
        contains('Keep Node.1Dto and Node.10Dto in source text.'),
      );
      expect(expected.values.join(), contains('"Node.1Dto"'));
      // Model rules do not rename union views derived from source keys.
      const unionPath = 'models/nullable_root.dart';
      expected[unionPath] = expected[unionPath]!
          .replaceAll('hasItem0', 'hasNode0Dto')
          .replaceAll('asItem0', 'asNode0Dto');
      expect(
        await _generate(
          'test/fixtures/schema_graphs/large_cycle/graph.json',
          config: jsonConfig.generation,
        ),
        expected,
      );
      expect(
        await _generate(
          'test/fixtures/schema_graphs/large_cycle/graph.yaml',
          config: config.generation,
        ),
        expected,
      );
    },
  );
}
