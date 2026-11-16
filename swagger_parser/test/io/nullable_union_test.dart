@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

Future<GenerationResult> _generate(
  String version,
  String format,
  DtoSerializer serializer,
) async => await const SwaggerParserRunner().generate(
  await _loader.loadPath('test/fixtures/nullable_unions/$version.$format'),
  config: GenerationConfig(serializer: serializer),
);

Map<String, String> _files(GenerationResult result) => {
  for (final file in result.files) file.relativePath: file.content,
};

void main() {
  for (final version in ['v3_1', 'v3_2']) {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      test('$version reduces a union with null to a nullable type with '
          '${serializer.name}', () async {
        Map<String, String>? baseline;
        for (final format in ['json', 'yaml']) {
          final GenerationResult result = await _generate(
            version,
            format,
            serializer,
          );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = _files(result);
          baseline ??= files;
          expect(files, baseline);

          final String holder = files['default_client/models/holder.dart']!;
          // Referenced objects keep their own type and become nullable.
          expect(holder, contains('Card? anyCard'));
          expect(holder, contains('Card? oneCard'));
          expect(holder, contains('Reach? reach'));
          // Scalars and collection items become nullable Dart types.
          expect(holder, contains('String? text'));
          expect(holder, contains('List<Card?>? cards'));
          // Defaults stay valid constants on the nullable type.
          expect(holder, contains('bool? archived'));
          expect(holder, contains('String? label'));
          expect(holder, contains('String? cleared'));
          expect(holder, contains('String? constNull'));
          expect(holder, contains('int? enumNull'));
          expect(holder, contains('int? zero'));
          expect(holder, contains('List<String>? listDefault'));
          expect(holder, contains('HolderOverlap'));
          expect(holder, contains('NamedNullable'));
          expect(holder, contains('false'));
          expect(holder, contains('"none"'));
          // No wrapper types remain for two-member unions with null.
          for (final name in [
            'holder_any_card',
            'holder_one_card',
            'holder_text',
            'holder_archived',
            'holder_label',
            'holder_cleared',
            'holder_reach',
          ]) {
            expect(files.keys, isNot(contains('models/$name.dart')));
            expect(
              files.keys,
              isNot(contains('default_client/models/$name.dart')),
            );
          }
          // Unions with several non-null members stay unions.
          expect(holder, isNot(contains('Card? choice')));
          expect(holder, contains('HolderChoice'));
          expect(holder, contains('HolderTriple'));
        }
      });
    }
  }
}
