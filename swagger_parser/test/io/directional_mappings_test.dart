@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('selects directional types across versions and serializers', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        Map<String, String>? expected;
        for (final ext in ['json', 'yaml']) {
          final CliConfig config = await CliConfig.load(
            configPath:
                'test/fixtures/directional_mappings/config_v$version.$ext',
          );
          final GenerationResult
          result = await const SwaggerParserRunner().generate(
            await const FileSchemaSourceLoader().loadPath(
              'test/fixtures/directional_mappings/directional_v$version.$ext',
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
          expect(source, contains('mapped1.CreateStation'));
          expect(source, contains('mapped1.Station'));
          expect(source, contains(r'Envelope$Request'));
          expect(source, contains(r'Envelope$Response'));
          expect(source, contains(r'LabelBox$Request'));
          expect(source, contains(r'LabelBox$Response'));
          expect(source, contains(r'Partial$Response'));
          expect(source, isNot(contains(r'class Partial$Request')));
          expect(source, contains('mapped1.defaultDraft'));
          expect(source, contains('mapped1.defaultView'));
          expect(files['exports.dart'], isNot(contains('show defaultDraft')));
        }
      }
    }
  });

  test(
    'keeps rule order independent and requires per-direction defaults',
    () async {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        final CliConfig config = await CliConfig.load(
          configPath:
              'test/fixtures/directional_mappings/config_v$version.yaml',
        );
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/directional_mappings/directional_v$version.yaml',
            );
        final GenerationResult forward = await const SwaggerParserRunner()
            .generate(source, config: config.generation);
        final GenerationResult reversed = await const SwaggerParserRunner()
            .generate(
              source,
              config: GenerationConfig(
                typeMappings: config.generation.typeMappings.reversed.toList(),
              ),
            );
        expect(
          {for (final f in reversed.files) f.relativePath: f.content},
          {for (final f in forward.files) f.relativePath: f.content},
        );
        final List<TypeMapping> missing = [
          for (final rule in config.generation.typeMappings)
            if (rule.direction == TypeMappingDirection.response &&
                rule.defaults.isNotEmpty)
              TypeMapping(
                schema: rule.schema,
                direction: rule.direction,
                dartType: rule.dartType,
                importUrl: rule.importUrl,
                codec: rule.codec,
              )
            else
              rule,
        ];
        await expectLater(
          const SwaggerParserRunner().generate(
            source,
            config: GenerationConfig(typeMappings: missing),
          ),
          throwsA(isA<GenerationException>()),
        );
      }
    },
  );

  test('rejects invalid direction values in JSON and YAML config', () async {
    for (final name in ['sideways', '42', 'null']) {
      for (final ext in ['json', 'yaml']) {
        await expectLater(
          CliConfig.load(
            configPath: 'test/fixtures/directional_mappings/invalid_$name.$ext',
          ),
          throwsA(isA<FormatException>()),
        );
      }
    }
  });

  test('rejects duplicate directions and unsafe both rules', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final CliConfig config = await CliConfig.load(
          configPath:
              'test/fixtures/directional_mappings/config_v$version.$ext',
        );
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/directional_mappings/directional_v$version.$ext',
            );
        final TypeMapping rule = config.generation.typeMappings.first;
        for (final rules in [
          [rule, rule],
          [
            TypeMapping(
              schema: rule.schema,
              dartType: rule.dartType,
              importUrl: rule.importUrl,
              codec: rule.codec,
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
}
