@TestOn('vm')
library;

import 'dart:convert';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('defaults to rejection and parses independent union policies', () {
    expect(
      const GenerationConfig().unmatchedUnionValues,
      UnknownValueMode.reject,
    );
    expect(
      PipelineConfig.fromMap({}).generation.unmatchedUnionValues,
      UnknownValueMode.reject,
    );
    for (final UnknownValueMode mode in UnknownValueMode.values) {
      for (final Object? document in [
        jsonDecode('{"generation":{"unmatched_union_values":"${mode.name}"}}'),
        loadYaml('generation:\n  unmatched_union_values: ${mode.name}\n'),
      ]) {
        final GenerationConfig config = PipelineConfig.fromMap(
          (document! as Map).cast<String, Object?>(),
        ).generation;
        expect(config.unmatchedUnionValues, mode);
        expect(config.unknownEnumValues, UnknownValueMode.reject);
        expect(config.unknownDiscriminatorValues, UnknownValueMode.reject);
      }
    }
    for (final Object value in ['fallback', true, 1]) {
      expect(
        () => PipelineConfig.fromMap({
          'generation': {'unmatched_union_values': value},
        }),
        throwsFormatException,
      );
    }
  });

  for (final DtoSerializer serializer in DtoSerializer.values) {
    for (final UnknownValueMode mode in UnknownValueMode.values) {
      test(
        'maps untagged fallback with ${serializer.name} and ${mode.name}',
        () async {
          Map<String, String>? baseline;
          for (final format in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await const FileSchemaSourceLoader().loadPath(
                    'test/fixtures/e2e/unmatched_unions/inputs/openapi.$format',
                  ),
                  config: GenerationConfig(
                    serializer: serializer,
                    unmatchedUnionValues: mode,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            baseline ??= files;
            expect(files, baseline);
            final String source = files.values.join('\n');
            if (mode == UnknownValueMode.preserve) {
              expect(
                source,
                contains('class MessageUnknown2 implements Message'),
              );
              expect(source, contains('class ViewsUnknown extends Views'));
              expect(source, contains('if (matches.isEmpty)'));
              expect(source, contains('if (matches.length != 1)'));
              expect(
                source,
                contains('class DirectionalMessageRequestUnknown'),
              );
              expect(source, contains('class DirectionalViewsResponseUnknown'));
            } else {
              expect(source, isNot(contains('class MessageUnknown2')));
              expect(source, isNot(contains('class ViewsUnknown')));
            }
            expect(source, isNot(contains('class TaggedUnknown')));
            expect(source, isNot(contains('class PingActionUnknown')));
          }
        },
      );
    }
  }

  test(
    'keeps tagged and enum preservation separate from untagged fallback',
    () async {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/e2e/unmatched_unions/inputs/openapi.json',
      );
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            source,
            config: const GenerationConfig(
              unknownEnumValues: UnknownValueMode.preserve,
              unknownDiscriminatorValues: UnknownValueMode.preserve,
            ),
          );
      expect(result.diagnostics, isEmpty);
      final String output = result.files.map((f) => f.content).join();
      expect(output, contains('class TaggedUnknown'));
      expect(output, contains('class PingActionUnknown'));
      expect(output, isNot(contains('class MessageUnknown2')));
      expect(output, isNot(contains('class ViewsUnknown')));
    },
  );
}
