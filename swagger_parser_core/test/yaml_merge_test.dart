import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

Future<String> _read(String name) => readInput('parsing/yaml_merge/$name.yaml');

void main() {
  for (final version in ['2.0', '3.0.3', '3.1.1', '3.2.0']) {
    test('expands merges and preserves scalar keys in $version', () async {
      final String input = (await _read('valid')).replaceFirst(
        'openapi: 3.0.3',
        version == '2.0' ? "swagger: '2.0'" : 'openapi: $version',
      );
      final Map<String, Object?> data = const OpenApiParser()
          .parse(SchemaSource.yaml(input))
          .toJson();
      final cases = data['x-cases']! as Map<String, Object?>;
      final base = cases['base']! as Map<String, Object?>;
      expect(cases['single'], {...base, 'description': 'merged'});
      expect(cases['sequence'], {'type': 'number', 'description': 'first'});
      expect(cases['nested'], {
        ...base,
        'description': 'middle',
        'title': 'leaf',
      });
      for (final key in [
        'quoted',
        'singleQuoted',
        'stringTagged',
        'anchoredStringKey',
        'aliasStringKey',
      ]) {
        expect(cases[key], {
          '<<': {'field': 'value'},
        }, reason: key);
      }
      expect(cases['anchoredKey'], base);
      expect(cases['aliasKey'], base);
      expect(cases['nullOverride'], {'type': 'string', 'description': null});
      expect(cases['nullWinner'], {'description': null, 'type': 'string'});
      expect(cases['empty'], {'type': 'string'});
    });
  }

  for (final fixture in ['sequence_error', 'override_error']) {
    test('reports the winning type location in $fixture', () async {
      final String input = await _read(fixture);
      final int offset = input.indexOf('123');
      final int line = input.substring(0, offset).split('\n').length;
      expect(
        () => const OpenApiParser().parse(SchemaSource.yaml(input)),
        throwsA(
          isA<SchemaParseException>()
              .having(
                (e) => e.documentPath,
                'path',
                '/components/schemas/Merged/type',
              )
              .having((e) => e.location?.line, 'line', line)
              .having((e) => e.location?.offset, 'offset', offset),
        ),
      );
    });
  }

  test('indexes only surviving fields at their expanded paths', () async {
    final String input = await _read('nested_locations');
    final DecodedDocument decoded = const SourceDecoder().decode(
      SchemaSource.yaml(input),
      const ParseConfig(),
    );
    expect(
      decoded.locations['/target/a~1b/new~0key']?.offset,
      input.indexOf('winning'),
    );
    expect(decoded.locations, isNot(contains('/target/0/a~1b/new~0key')));
    expect(decoded.locations, isNot(contains('/target/a~1b/old~0key')));
    expect(decoded.locations, isNot(contains('/override/a~1b/old~0key')));
    expect(
      decoded.locations['/override/a~1b']?.offset,
      input.indexOf('replacement'),
    );
  });

  test('omits merged coordinates when source capture is disabled', () async {
    final String input = await _read('nested_locations');
    final DecodedDocument decoded = const SourceDecoder().decode(
      SchemaSource.yaml(input),
      const ParseConfig(captureSourceLocations: false),
    );
    expect(decoded.locations, isEmpty);
    expect((decoded.value! as Map<String, Object?>)['target'], {
      'a/b': {'new~key': 'winning'},
    });
  });

  for (final fixture in ['invalid_scalar', 'invalid_sequence']) {
    test('rejects a non-mapping merge source in $fixture', () async {
      final String input = await _read(fixture);
      expect(
        () => const OpenApiParser().parse(SchemaSource.yaml(input)),
        throwsA(
          isA<SchemaParseException>().having(
            (e) => e.message,
            'message',
            'Expected a mapping for a merge key.',
          ),
        ),
      );
    });
  }

  test('rejects cyclic merge aliases', () async {
    final String input = await _read('cycle');
    expect(
      () => const OpenApiParser().parse(SchemaSource.yaml(input)),
      throwsA(
        isA<SchemaParseException>().having(
          (e) => e.message,
          'message',
          'Self-referential collections are not supported.',
        ),
      ),
    );
  });

  test('keeps the depth limit while expanding merge sources', () async {
    final String input = await _read('nested_locations');
    expect(
      () => const SourceDecoder().decode(
        SchemaSource.yaml(input),
        const ParseConfig(maxDepth: 3),
      ),
      throwsA(
        isA<SchemaParseException>().having(
          (e) => e.message,
          'message',
          'Maximum nesting depth exceeded.',
        ),
      ),
    );
  });
}
