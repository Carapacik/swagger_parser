import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

Map<String, Object?> _parameterAt(
  Map<String, Object?> document,
  String pointer,
) {
  Object? node = document;
  for (final String token in pointer.split('/').skip(1)) {
    final String key = token.replaceAll('~1', '/').replaceAll('~0', '~');
    node = node is List<Object?>
        ? node[int.parse(key)]
        : (node! as Map<String, Object?>)[key];
  }
  return node! as Map<String, Object?>;
}

void main() {
  const normalizer = OpenApiNormalizer(
    config: NormalizeConfig(explicitParameterSerialization: true),
  );
  const cases = <String, Map<String, Map<String, Object?>>>{
    'swagger_v2': {
      '/paths/~1stations~1{ids}/parameters/0': {'collectionFormat': 'csv'},
      '/parameters/Tags': {'collectionFormat': 'csv'},
      '/paths/~1stations~1{ids}/get/parameters/0': {},
      '/paths/~1stations~1{ids}/get/parameters/1': {
        'collectionFormat': 'multi',
      },
      '/paths/~1stations~1{ids}/get/parameters/2': {},
      '/paths/~1stations~1{ids}/post/parameters/0': {},
    },
    'open_api_v3_0': {
      '/paths/~1stations~1{id}/parameters/0': {
        'style': 'matrix',
        'explode': false,
      },
      '/paths/~1stations~1{id}/post/parameters/0': {
        'style': 'form',
        'explode': true,
      },
      '/paths/~1stations~1{id}/post/parameters/1': {
        'style': 'form',
        'explode': false,
      },
      '/paths/~1stations~1{id}/post/parameters/2': {},
      '/components/parameters/Filter': {'style': 'deepObject'},
      '/components/parameters/Payload': {},
      r'/components/callbacks/Notify/{$request.body#~1url}/post/parameters/0': {
        'style': 'simple',
        'explode': false,
      },
    },
    'open_api_v3_1': {
      '/webhooks/update/post/parameters/0': {'style': 'form', 'explode': true},
      '/components/pathItems/Station/parameters/0': {
        'style': 'simple',
        'explode': false,
      },
      '/components/pathItems/Station/get/parameters/0': {
        'style': 'pipeDelimited',
        'explode': false,
      },
      '/components/parameters/Filter': {'style': 'deepObject', 'explode': true},
    },
    'open_api_v3_2': {
      '/paths/~1reports/query/parameters/0': {},
      '/paths/~1reports/query/parameters/1': {
        'style': 'cookie',
        'explode': true,
      },
      '/paths/~1reports/additionalOperations/REPORT/parameters/0': {
        'style': 'form',
        'explode': true,
      },
      '/paths/~1reports/additionalOperations/REPORT/parameters/1': {
        'style': 'form',
        'explode': false,
      },
      '/paths/~1reports/additionalOperations/REPORT/parameters/2': {
        'style': 'simple',
        'explode': true,
      },
    },
  };

  test(
    'normalizes local parameters beside an external Path Item reference',
    () async {
      final source = const OpenApiParser().parse(
        SchemaSource.yaml(await readInput('parsing/open_api_v3_0.yaml')),
      ) as OpenApiV30Document;
      final OpenApiV30Document normalized = normalizer.normalize(source);
      final OpenApiV30PathItem path = normalized.paths['/events/{id}']!;
      final OpenApiV30Parameter parameter =
          (path.parameters!.single as OpenApiV30Inline<OpenApiV30Parameter>)
              .value;
      expect(path.ref, './paths.yaml#/events');
      expect(normalized.openapi, '3.0.4');
      expect(parameter.explode, isFalse);
      expect(() => path.parameters!.clear(), throwsUnsupportedError);
    },
  );

  for (final MapEntry<String, Map<String, Map<String, Object?>>> entry
      in cases.entries) {
    final fixture = 'normalization/${entry.key}';
    for (final SchemaFormat format in [SchemaFormat.json, SchemaFormat.yaml]) {
      test('normalizes ${entry.key} from ${format.name}', () async {
        final String content = await readInput('$fixture.${format.name}');
        final OpenApiDocument source = const OpenApiParser().parse(
          SchemaSource(content, format: format),
        );
        final Map<String, Object?> before = source.toJson();
        final expected = jsonDecode(
          await readInput('$fixture.json'),
        ) as Map<String, Object?>;
        expect(before, expected);

        final OpenApiDocument copy = const OpenApiNormalizer().normalize(
          source,
        );
        expect(copy, isNot(same(source)));
        expect(copy.runtimeType, source.runtimeType);
        expect(copy.toJson(), before);

        for (final MapEntry<String, Map<String, Object?>> setting
            in entry.value.entries) {
          final serialization = ParameterSerialization.effective(
            source.version.family,
            _parameterAt(before, setting.key),
          );
          expect(serialization.toJson(), setting.value, reason: setting.key);
          _parameterAt(expected, setting.key).addAll(setting.value);
        }
        final OpenApiDocument normalized = normalizer.normalize(source);
        expect(normalized, isNot(same(source)));
        expect(normalized.runtimeType, source.runtimeType);
        expect(normalized.version.value, source.version.value);
        expect(normalized.toJson(), expected);
        expect(source.toJson(), before);
        expect(normalizer.normalize(normalized).toJson(), expected);
      });
    }
  }
}
