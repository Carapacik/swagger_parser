@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

Future<GenerationResult> _generate(
  String name,
  DtoSerializer serializer,
) async {
  final SchemaSource source = await _loader.loadPath(
    'test/fixtures/reference_siblings/$name',
  );
  return await const SwaggerParserRunner().generate(
    source,
    config: GenerationConfig(serializer: serializer),
  );
}

void main() {
  for (final version in ['v3_1', 'v3_2']) {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      test('$version keeps a union when a reference has a matching type '
          'with ${serializer.name}', () async {
        Map<String, String>? baseline;
        for (final format in ['json', 'yaml']) {
          final GenerationResult result = await _generate(
            'object_union_$version.$format',
            serializer,
          );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final file in result.files) file.relativePath: file.content,
          };
          baseline ??= files;
          expect(files, baseline);
          // The sibling `type: object` repeats what every union member says.
          // It does not wrap the union in a generated object.
          final String envelope = files['models/envelope.dart']!;
          expect(envelope, contains('Frame frame'));
          expect(files.keys, contains('default_client/models/frame.dart'));
          final String client = files['default_client/api_client.dart']!;
          expect(client, contains('Future<models.Frame> getFrame('));
          // A sibling `type: object` beside an object reference stays valid.
          expect(client, contains('Future<A> getObject('));
        }
      });
    }

    test('$version keeps the intersection when the sibling type narrows '
        'the union', () async {
      for (final format in ['json', 'yaml']) {
        await expectLater(
          _generate('mixed_union_$version.$format', DtoSerializer.plain),
          throwsA(
            isA<GenerationException>().having(
              (e) => e.message,
              'message',
              contains('Expected object branches in allOf.'),
            ),
          ),
        );
      }
    });
  }
}
