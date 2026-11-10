@TestOn('vm')
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/editor_config.dart';
import 'package:swagger_parser_pages/src/editor_services.dart';
import 'package:swagger_parser_pages/src/page_routes.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('maps clean routes at root and under a project path', () {
    for (final base in ['/', '/swagger_parser/']) {
      final routes = PageRoutes(base);
      expect(PageRoutes.tabs.keys, ['generator', 'templates', 'configuration']);
      for (final String tab in PageRoutes.tabs.keys) {
        final String path = routes.path(tab);
        expect(routes.tab(path), tab);
        expect(
          routes.tab(
            path.endsWith('/') ? '${path}index.html' : '$path/index.html',
          ),
          tab,
        );
      }
      expect(routes.path('templates'), '${base}template');
      expect(routes.path('configuration'), '${base}config');
    }
  });
  test('keeps the approved form defaults', () {
    final config = EditorConfig.defaults();
    expect(config.value('serializer'), 'plain');
    expect(config.value('http_client'), 'retrofit');
    expect(config.value('response_mode'), 'first_success');
    expect(config.value('unmatched_union_values'), 'reject');
    expect(config.value('root_api_class_name'), 'Api');
    expect(config.value('page_width'), 80);
    expect(config.value('generate_docs'), isTrue);
    expect(config.value('infer_missing_required'), isFalse);
    expect(config.parseConfig.maxDepth, 128);
    expect(config.parseConfig.captureSourceLocations, isTrue);
    expect(config.parseConfig.unknownFields, UnknownFieldPolicy.preserve);
  });

  test(
    'changes form values without losing other YAML settings or comments',
    () {
      final String source = File('test/fixtures/config.yaml')
          .readAsStringSync();
      final config = EditorConfig.parse(source);
      final EditorConfig changed = config.withValue('serializer', 'freezed');
      expect(config.yaml, source);
      expect(changed.value('serializer'), 'freezed');
      expect(changed.value('http_client'), 'dio');
      expect(changed.yaml, contains('# Keep the user template.'));
      final before =
          (loadYaml(config.yaml) as YamlMap)['swagger_parser'] as YamlMap;
      final beforeGeneration = before['generation'] as YamlMap;
      final after =
          (loadYaml(changed.yaml) as YamlMap)['swagger_parser'] as YamlMap;
      final afterGeneration = after['generation'] as YamlMap;
      expect(afterGeneration['templates'], beforeGeneration['templates']);
      expect(
        afterGeneration['operation_filters'],
        beforeGeneration['operation_filters'],
      );
      expect(changed.parseConfig.maxDepth, 64);
      expect(changed.parseConfig.unknownFields, UnknownFieldPolicy.reject);
    },
  );

  test('edits and validates unmatched union values', () {
    final config = EditorConfig.defaults();
    final EditorConfig changed = config.withValue(
      'unmatched_union_values',
      'preserve',
    );
    expect(
      changed.pipelineConfig.generation.unmatchedUnionValues,
      UnknownValueMode.preserve,
    );
    expect(
      config.pipelineConfig.generation.unmatchedUnionValues,
      UnknownValueMode.reject,
    );
    expect(
      () => config.withValue('unmatched_union_values', 'fallback'),
      throwsFormatException,
    );
  });

  test('loads bare config and adds missing generation settings', () {
    final config = EditorConfig.parse(
      File('test/fixtures/bare.yaml').readAsStringSync(),
    );
    final EditorConfig changed = config.withValue('page_width', 100);
    expect(changed.value('page_width'), 100);
    expect(loadYaml(changed.yaml), isNot(contains('swagger_parser')));
    expect(changed.parseConfig.captureSourceLocations, isFalse);
  });

  test('rejects invalid known values without changing the previous config', () {
    final config = EditorConfig.defaults();
    for (final (key, value) in <(String, Object)>[
      ('page_width', 0),
      ('page_width', 80.5),
      ('serializer', 'invalid'),
      ('http_client', 'fetch'),
      ('generate_docs', 'false'),
      ('root_api_class_name', 'class'),
    ]) {
      expect(() => config.withValue(key, value), throwsFormatException);
    }
    for (final name in ['invalid', 'batch', 'null']) {
      expect(
        () => EditorConfig.parse(
          File('test/fixtures/$name.yaml').readAsStringSync(),
        ),
        throwsFormatException,
      );
    }
    expect(config.value('page_width'), 80);
  });

  final services = EditorServices();
  for (final family in ['v2_0', 'v3_0', 'v3_1', 'v3_2']) {
    test('parses both schema formats for $family through the shared package', () {
      OpenApiDocument? json;
      for (final extension in ['json', 'yaml']) {
        final source = File(
          '../swagger_parser/test/fixtures/e2e/client_models/inputs/$family.$extension',
        );
        final OpenApiDocument document = services.parse(
          source.readAsStringSync(),
          const ParseConfig(),
        );
        if (extension == 'json') {
          json = document;
        } else {
          expect(document.toJson(), json!.toJson());
        }
      }
    });
  }

  test('connects the template renderer without generating files', () {
    expect(
      services.createRunner(templates: {'models': '{{defaultSource}}'}),
      isA<SwaggerParserRunner>(),
    );
  });
}
