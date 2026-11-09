@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_pages/src/editor_config.dart';
import 'package:swagger_parser_pages/src/editor_services.dart';
import 'package:swagger_parser_pages/src/generation_archive.dart';
import 'package:test/test.dart';

void main() {
  final services = EditorServices();
  final base = EditorConfig.parse(
    File('test/fixtures/generation.yaml').readAsStringSync(),
  );
  for (final family in ['v2_0', 'v3_0', 'v3_1', 'v3_2']) {
    for (final format in ['json', 'yaml']) {
      for (final serializer in [
        'plain',
        'json_serializable',
        'freezed',
        'dart_mappable',
      ]) {
        for (final client in ['retrofit', 'dio', 'http']) {
          test('archives $family $format $serializer $client with original paths', () async {
            final String source = File(
              '../swagger_parser/test/fixtures/e2e/client_models/inputs/$family.$format',
            ).readAsStringSync();
            final EditorConfig config = base
                .withValue('serializer', serializer)
                .withValue('http_client', client);
            final GenerationArchive result = await services.generate(
              source,
              config,
            );
            final Archive archive = ZipDecoder().decodeBytes(
              result.bytes,
              verify: true,
            );
            final PipelineConfig settings = config.pipelineConfig;
            final GenerationResult expected = await services
                .createRunner(normalize: settings.normalize)
                .generate(
                  SchemaSource(source),
                  config: settings.generation,
                  parseConfig: settings.parse,
                );
            expect(
              archive.files.map((f) => f.name).toSet(),
              expected.files.map((f) => f.relativePath).toSet(),
            );
            expect(result.fileCount, expected.files.length);
            expect(
              archive.files.any((f) => f.name == 'transit_api.dart'),
              isTrue,
            );
            expect(archive.files.any((f) => f.name == 'exports.dart'), isTrue);
            expect(
              archive.files.any((f) => f.name.contains('/models/')),
              isTrue,
            );
            for (final ArchiveFile file in archive.files) {
              expect(
                utf8.decode(file.content),
                expected.files
                    .singleWhere((f) => f.relativePath == file.name)
                    .content,
              );
              expect(file.name, isNot(startsWith('lib/generated')));
            }
            final Map<String, String> files = {
              for (final file in archive.files)
                file.name: utf8.decode(file.content),
            };
            expect(files['transit_api.dart'], contains('class TransitApi'));
            expect(
              files['transit_api.dart'],
              contains("export 'exports.dart'"),
            );
            expect(
              files['exports.dart'],
              contains('stations/models/station.api.dart'),
            );
            final String station = files['stations/models/station.api.dart']!;
            expect(station, contains('final String? note'));
            if (serializer == 'freezed') {
              expect(station, contains('required final StationId id'));
              expect(station, contains('required final String name'));
              expect(station, isNot(contains('required final String? note')));
              expect(station, contains('final bool enabled = true'));
            } else {
              expect(station, contains('required this.id'));
              expect(station, contains('required this.name'));
              expect(station, contains('this.note,'));
              expect(station, isNot(contains('required this.note')));
              expect(station, contains('this.enabled = true'));
            }
          });
        }
      }
    }
  }

  test('rejects browser-only limitations and unknown pipeline settings', () {
    for (final name in ['config', 'unsupported', 'unknown_option']) {
      final config = EditorConfig.parse(
        File('test/fixtures/$name.yaml').readAsStringSync(),
      );
      expect(() => config.pipelineConfig, throwsFormatException);
    }
  });

  test('rejects external references without fetching them', () async {
    await expectLater(
      services.generate(
        File('test/fixtures/external_reference.yaml').readAsStringSync(),
        base,
      ),
      throwsA(isA<OpenApiException>()),
    );
  });

  test('reports validation errors with schema paths', () async {
    try {
      await services.generate(
        File('test/fixtures/invalid_operation.yaml').readAsStringSync(),
        base,
      );
      fail('Expected validation failure.');
    } on GenerationException catch (error) {
      expect(error.diagnostics, isNotEmpty);
      expect(
        error.diagnostics.map(formatDiagnostic).join('\n'),
        contains('/paths/'),
      );
      expect(
        error.diagnostics.map(formatDiagnostic).join('\n'),
        contains('id'),
      );
    }
  });

  test('fails malformed schemas without an archive', () async {
    await expectLater(
      services.generate(
        File('test/fixtures/malformed_schema.yaml').readAsStringSync(),
        base,
      ),
      throwsA(isA<OpenApiException>()),
    );
  });
}
