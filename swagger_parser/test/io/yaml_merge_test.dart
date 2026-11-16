@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> _generate() async =>
    await const SwaggerParserRunner().generate(
      await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/yaml_merge/api.yaml',
      ),
      config: const GenerationConfig(httpClient: HttpClientBackend.dio),
    );

void main() {
  test('expands a YAML merge key before mapping schemas', () async {
    final GenerationResult result = await _generate();
    expect(result.diagnostics, isEmpty);
    final String source = result.files
        .singleWhere((file) => file.relativePath.endsWith('station.dart'))
        .content
        .replaceAll(RegExp(r'\s+'), ' ');
    // The merged properties are the model fields instead of an untyped value.
    expect(source, contains('required this.name'));
    expect(source, contains('final String name;'));
    expect(source, contains('final int? lineCode;'));
    expect(source, isNot(contains('Object? value')));
  });

  test('keeps the merged description', () async {
    final GenerationResult result = await _generate();
    final String source = result.files
        .singleWhere((file) => file.relativePath.endsWith('station.dart'))
        .content;
    expect(source, contains('/// A station.'));
  });
}
