@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _base = 'test/fixtures/parameter_styles';

Future<GenerationResult> _generate(String ext) async =>
    await const SwaggerParserRunner().generate(
      await const FileSchemaSourceLoader().loadPath('$_base/styles.$ext'),
    );

String _client(GenerationResult result) => result.files
    .singleWhere((file) => file.relativePath.endsWith('stations_client.dart'))
    .content;

void main() {
  test('keeps delimiter styles when explode is true', () async {
    for (final ext in ['json', 'yaml']) {
      final GenerationResult result = await _generate(ext);
      expect(result.diagnostics, isEmpty);
      final String source = _client(result);
      expect(source, contains('List<String>? regions'));
      expect(source, contains('ListParam(regions, ListFormat.ssv)'));
      expect(source, contains('List<String>? zones'));
      expect(source, contains('ListParam(zones, ListFormat.pipes)'));
    }
  });

  test('emits the same client for JSON and block YAML inputs', () async {
    expect(_client(await _generate('yaml')), _client(await _generate('json')));
  });
}
