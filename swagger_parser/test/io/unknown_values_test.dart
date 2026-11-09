@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> _generate(
  String version,
  String ext,
  GenerationConfig config,
) async => await const SwaggerParserRunner().generate(
  await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/unknown_values/unknown_v$version.$ext',
  ),
  config: config,
);

void main() {
  test(
    'renders reject and preserve policies for all versions and serializers',
    () async {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final UnknownValueMode mode in UnknownValueMode.values) {
          for (final version in ['2_0', '3_0', '3_1', '3_2']) {
            final config = GenerationConfig(
              serializer: serializer,
              unknownEnumValues: mode,
              unknownDiscriminatorValues: mode,
            );
            final GenerationResult json = await _generate(
              version,
              'json',
              config,
            );
            final GenerationResult yaml = await _generate(
              version,
              'yaml',
              config,
            );
            expect(json.diagnostics, isEmpty);
            expect(yaml.diagnostics, isEmpty);
            expect(
              {for (final f in json.files) f.relativePath: f.content},
              {for (final f in yaml.files) f.relativePath: f.content},
            );
            final String source = json.files.map((f) => f.content).join();
            expect(source, contains('sealed class Stop'));
            expect(
              source,
              matches(RegExp(r'Future<(?:models\.)?Status> getStatus')),
            );
            if (mode == UnknownValueMode.preserve) {
              expect(source, contains('sealed class Status'));
              expect(source, contains('class StatusUnknown'));
              expect(source, contains('class StopUnknown'));
              expect(source, contains('enum CollisionValue2'));
              expect(source, contains('class CollisionKnown2'));
              expect(source, contains('class CollisionUnknown2'));
            } else {
              expect(source, contains('enum Status'));
              expect(source, isNot(contains('class StatusUnknown')));
              expect(source, isNot(contains('class StopUnknown')));
            }
          }
        }
      }
    },
  );
  test('keeps Swagger discriminator tags after model renaming', () async {
    for (final ext in ['json', 'yaml']) {
      final GenerationResult result = await _generate(
        '2_0',
        ext,
        const GenerationConfig(
          naming: NamingConfig(
            replaceRules: [
              NameReplacementRule(
                target: NamingTarget.models,
                pattern:
                    '^Rail'
                    r'$',
                replacement: 'Train',
              ),
            ],
          ),
          unknownDiscriminatorValues: UnknownValueMode.preserve,
        ),
      );
      expect(result.diagnostics, isEmpty);
      final String source = result.files.map((f) => f.content).join();
      expect(source, contains('case "Rail":'));
      expect(source, contains('return Train.fromJson(json);'));
      expect(source, isNot(contains('case "Train":')));
      expect(source, contains(r'sealed class Entity$Request'));
      expect(source, contains(r'sealed class Entity$Response'));
      final GenerationResult prefixed = await _generate(
        '2_0',
        ext,
        const GenerationConfig(
          naming: NamingConfig(
            replaceRules: [
              NameReplacementRule(
                target: NamingTarget.models,
                pattern: '^',
                replacement: 'Custom',
              ),
            ],
          ),
        ),
      );
      final String renamed = prefixed.files.map((f) => f.content).join();
      expect(renamed, contains('class CustomStopValue'));
      expect(renamed, isNot(contains('CustomCustomStopValue')));
    }
  });

  test('keeps enum and discriminator policies independent', () async {
    final GenerationResult enumOnly = await _generate(
      '3_2',
      'yaml',
      const GenerationConfig(unknownEnumValues: UnknownValueMode.preserve),
    );
    final String enumSource = enumOnly.files.map((f) => f.content).join();
    expect(enumSource, contains('class StatusUnknown'));
    expect(enumSource, isNot(contains('class StopUnknown')));
    final GenerationResult unionOnly = await _generate(
      '3_2',
      'json',
      const GenerationConfig(
        unknownDiscriminatorValues: UnknownValueMode.preserve,
      ),
    );
    final String unionSource = unionOnly.files.map((f) => f.content).join();
    expect(unionSource, contains('enum Status'));
    expect(unionSource, contains('class StopUnknown'));
  });
  test('loads unknown-value policies from JSON and YAML config', () async {
    expect(const GenerationConfig().unknownEnumValues, UnknownValueMode.reject);
    expect(
      const GenerationConfig().unknownDiscriminatorValues,
      UnknownValueMode.reject,
    );
    for (final ext in ['json', 'yaml']) {
      for (final UnknownValueMode mode in UnknownValueMode.values) {
        final CliConfig config = await CliConfig.load(
          configPath: 'test/fixtures/unknown_values/config_${mode.name}.$ext',
        );
        expect(config.generation.unknownEnumValues, mode);
        expect(config.generation.unknownDiscriminatorValues, mode);
      }
      await expectLater(
        CliConfig.load(
          configPath: 'test/fixtures/unknown_values/config_invalid.$ext',
        ),
        throwsA(isA<Exception>()),
      );
    }
  });
}
