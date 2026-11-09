@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:swagger_parser_pages/src/editor_config.dart';
import 'package:swagger_parser_pages/src/editor_services.dart';
import 'package:swagger_parser_pages/src/generation_archive.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

import '../tool/build_reference.dart';

void main() {
  final services = EditorServices();
  final String templates = File('test/fixtures/templates/sources.yaml')
      .readAsStringSync();
  for (final family in ['v2_0', 'v3_0', 'v3_1', 'v3_2']) {
    for (final format in ['json', 'yaml']) {
      test('renders overrides and helper exports for $family $format', () async {
        final String source = File(
          '../swagger_parser/test/fixtures/e2e/client_models/inputs/$family.$format',
        ).readAsStringSync();
        for (final serializer in [
          'plain',
          'json_serializable',
          'freezed',
          'dart_mappable',
        ]) {
          for (final client in ['retrofit', 'dio', 'http']) {
            final EditorConfig config = EditorConfig.defaults()
                .withValue('serializer', serializer)
                .withValue('http_client', client);
            final GenerationArchive result = await services.generate(
              source,
              config,
              templates: templates,
            );
            final Archive archive = ZipDecoder().decodeBytes(
              result.bytes,
              verify: true,
            );
            final Map<String, String> files = {
              for (final file in archive.files)
                file.name: utf8.decode(file.content),
            };
            expect(result.name, 'swagger_parser_templates.zip');
            expect(
              files['stations/stations_client.dart'],
              contains('class StationsClientRoutes'),
            );
            expect(
              files['stations/models/station.dart'],
              contains('// Custom model output.'),
            );
            expect(files['helpers/page.dart'], contains('class Page<T>'));
            expect(
              files['helpers/internal.dart'],
              contains('internalValue = 1'),
            );
            expect(files['exports.dart'], contains('helpers/page.dart'));
            expect(
              files['exports.dart'],
              isNot(contains('helpers/internal.dart')),
            );
          }
        }
      });
    }
  }
  test(
    'fails invalid template config, syntax, selectors, and output paths',
    () async {
      final String source = File('test/fixtures/generation_schema.yaml')
          .readAsStringSync();
      final cases = loadYaml(
        File('test/fixtures/templates/invalid.yaml').readAsStringSync(),
      ) as YamlMap;
      for (final MapEntry<dynamic, dynamic> entry in cases.entries) {
        await expectLater(
          services.generate(
            source,
            EditorConfig.defaults(),
            templates: jsonEncode(entry.value),
          ),
          throwsException,
          reason: '${entry.key}',
        );
      }
    },
  );

  test(
    'builds local references with working guide links and section anchors',
    () async {
      final Directory output = Directory.systemTemp.createTempSync(
        'pages-reference-',
      );
      addTearDown(() => output.deleteSync(recursive: true));
      await buildReference(output);
      final String html = File('${output.path}/configuration.html')
          .readAsStringSync();
      expect(html, contains('id="complete-defaults"'));
      expect(html, contains('href="guide.html'));
      expect(html, contains('page_width: 80'));
      for (final name in ['configuration', 'guide', 'templates']) {
        final String text = File('${output.path}/$name.html')
            .readAsStringSync();
        final Set<String?> ids = RegExp('id="([^"]+)"')
            .allMatches(text)
            .map((m) => m[1])
            .toSet();
        for (final RegExpMatch anchor in RegExp(
          'href="#([^"]+)"',
        ).allMatches(text)) {
          expect(ids, contains(anchor[1]), reason: '$name: ${anchor[1]}');
        }
      }
    },
  );
}
