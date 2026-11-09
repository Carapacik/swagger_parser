@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> _generate(
  String stem,
  String ext, {
  GenerationConfig config = const GenerationConfig(),
}) async => await const SwaggerParserRunner().generate(
  await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/directions/$stem.$ext',
  ),
  config: config,
);

void main() {
  test('renders paired directional fixtures with every serializer', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        final config = GenerationConfig(serializer: serializer);
        final GenerationResult json = await _generate(
          'directions_v$version',
          'json',
          config: config,
        );
        final GenerationResult yaml = await _generate(
          'directions_v$version',
          'yaml',
          config: config,
        );
        expect(json.diagnostics, isEmpty);
        expect(
          {for (final f in json.files) f.relativePath: f.content},
          {for (final f in yaml.files) f.relativePath: f.content},
        );
      }
    }
  });
  test('projects four versions from JSON and YAML', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      final GenerationResult json = await _generate(
        'directions_v$version',
        'json',
      );
      final GenerationResult yaml = await _generate(
        'directions_v$version',
        'yaml',
      );
      expect(json.diagnostics, isEmpty);
      final Map<String, String> files = {
        for (final f in json.files) f.relativePath: f.content,
      };
      expect(files, {for (final f in yaml.files) f.relativePath: f.content});
      final String request = files['stations/models/station_request.dart']!;
      final String response = files['stations/models/station_response.dart']!;
      expect(request, contains(r'class Station$Request'));
      expect(response, contains(r'class Station$Response'));
      expect(request, isNot(contains('final String id;')));
      expect(response, contains('final String id;'));
      expect(request, contains('final String accessCode;'));
      if (version != '2_0') {
        expect(response, isNot(contains('final String accessCode;')));
      }
      expect(files.values.join(), contains('class StationRequest'));
      expect(files.values.join(), contains('class StationRequest2'));
      expect(
        files['stations/stations_client.dart'],
        contains(r'Future<Station$Response> saveStation'),
      );
      expect(
        files['stations/stations_client.dart'],
        contains(r'Station$Request body'),
      );
      expect(
        files['stations/stations_client.dart'],
        contains('Future<StationRequest> getOriginal'),
      );
      expect(
        files['stations/stations_client.dart'],
        contains('Future<StationRequest2> getLiteral'),
      );
      final String source = files.values.join();
      expect(source, contains(r'class Envelope$Request'));
      expect(source, contains(r'class Catalog$Response'));
      expect(source, contains(r'class Index$Request'));
      expect(source, contains(r'class StationAlias$Response'));
      expect(source, contains('class Shared'));
      expect(source, isNot(contains(r'class Shared$Request')));
    }
  });

  test('keeps reference identity after model name replacements', () async {
    final GenerationResult result = await _generate(
      'directions_v3_2',
      'yaml',
      config: const GenerationConfig(
        naming: NamingConfig(
          replaceRules: [
            NameReplacementRule(
              target: NamingTarget.models,
              pattern: r'^Station$',
              replacement: 'StationRequest',
            ),
          ],
        ),
      ),
    );
    final Map<String, String> files = {
      for (final f in result.files) f.relativePath: f.content,
    };
    final String client = files['stations/stations_client.dart']!;
    expect(client, contains(r'StationRequest$Request body'));
    expect(client, contains(r'Future<StationRequest$Response> saveStation'));
    expect(client, contains('Future<StationRequest2> getOriginal'));
    final String original = files.values.singleWhere(
      (text) => text.contains('class StationRequest2 {'),
    );
    expect(original, contains('final String marker;'));
    expect(original, isNot(contains('stationName')));
  });

  test('rejects contradictory directional property annotations', () async {
    for (final ext in ['json', 'yaml']) {
      await expectLater(
        _generate('conflicting_annotations', ext),
        throwsA(isA<GenerationException>()),
      );
    }
  });
}
