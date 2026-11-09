@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test('preserves docs and independent deprecation', () async {
    const loader = FileSchemaSourceLoader();
    for (final family in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend client in HttpClientBackend.values) {
          for (final docs in [false, true]) {
            Map<String, String>? baseline;
            for (final format in ['json', 'yaml']) {
              final GenerationResult result = await const SwaggerParserRunner()
                  .generate(
                    await loader.loadPath(
                      'test/fixtures/documentation/$family.$format',
                    ),
                    loader: loader,
                    config: GenerationConfig(
                      serializer: serializer,
                      httpClient: client,
                      generateDocs: docs,
                      applyParameterDefaults: true,
                      bodyPositional: true,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final f in result.files) f.relativePath: f.content,
              };
              baseline ??= files;
              expect(files, baseline);
              final String source = files.values.join('\n');
              for (final text in [
                'Station summary.',
                'Summary without description.',
                'Station description.',
                'Station identifier.',
                'Ordered stops.',
                'Status description.',
                'Code description.',
                'Extended description.',
                'Inherited identifier.',
                'Local note.',
                'Maximum stations.',
                'Station payload.',
                'Form label.',
                'Get summary.',
                'Get description.',
                'Save summary only.',
                'Send description only.',
              ]) {
                expect(
                  source.contains('/// $text'),
                  docs,
                  reason: '$family/$serializer/$client/$text',
                );
              }
              if (family != 'v2') {
                for (final text in [
                  'Stop description.',
                  'Rail description.',
                  'Rail platform.',
                  'Choice description.',
                  'Rail type.',
                ]) {
                  expect(source.contains('/// $text'), docs, reason: text);
                }
              }
              expect(
                source.contains('/// Local reference description.'),
                docs && (family == 'v3_1' || family == 'v3_2'),
              );
              expect(source, contains('@Deprecated('));
              final String station = files.entries
                  .singleWhere((e) => e.key.endsWith('/station.dart'))
                  .value;
              expect(
                '@Deprecated('.allMatches(station).length,
                greaterThanOrEqualTo(2),
              );
              expect(
                station.contains(
                  r'Keep $value, "quotes", \paths, */ and Привет.',
                ),
                docs,
              );
              final String declarations = station.replaceAll(
                RegExp(r'@[\w.]+(?:\((?:[^()]|\([^()]*\))*\))?\s*'),
                '',
              );
              expect(
                RegExp(
                  r'/// Station identifier\.\s+(?:required )?final String id\b',
                ).hasMatch(declarations),
                docs,
                reason: 'Field Dartdoc: $serializer',
              );
              expect(
                RegExp(
                  r'/// Keep[^\n]*\n\s*(?:final |sealed |abstract )?class (?:const )?Station\b',
                ).hasMatch(declarations),
                docs,
                reason: 'Class Dartdoc: $serializer',
              );
              final String undocumented = files.entries
                  .singleWhere((e) => e.key.endsWith('/undocumented.dart'))
                  .value;
              expect(undocumented, isNot(contains('///')));
              expect(undocumented, isNot(contains('@Deprecated(')));
            }
          }
        }
      }
    }
  });
}
