@TestOn('vm')
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';
import 'package:test/test.dart';

void main() {
  test('shares a page helper across schema versions and serializers', () async {
    const base = 'test/fixtures/pagination';
    final renderer = MustacheSourceRenderer(
      {
        'stations/models/stations_page.dart': await File(
          '$base/stations_page.mustache',
        ).readAsString(),
        'exports': await File('$base/exports.mustache').readAsString(),
      },
      files: [
        TemplateFile(
          relativePath: 'helpers/page.dart',
          source: await File('$base/page.mustache').readAsString(),
        ),
      ],
    );
    final runner = SwaggerParserRunner(
      generator: DartGenerator(renderer: renderer),
    );
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          Map<String, String>? expected;
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await runner.generate(
              await const FileSchemaSourceLoader().loadPath(
                '$base/v$version.$ext',
              ),
              config: GenerationConfig(
                serializer: serializer,
                httpClient: backend,
              ),
            );
            expect(result.diagnostics, isEmpty);
            final GenerationResult builtin = await const SwaggerParserRunner()
                .generate(
                  await const FileSchemaSourceLoader().loadPath(
                    '$base/v$version.$ext',
                  ),
                  config: GenerationConfig(
                    serializer: serializer,
                    httpClient: backend,
                  ),
                );
            final String concrete = builtin.files
                .singleWhere(
                  (f) => f.relativePath == 'stations/models/stations_page.dart',
                )
                .content;
            expect(concrete, contains('List<Station>'));
            expect(concrete, contains('pageSize'));
            expect(concrete, contains('results'));
            expect(concrete, isNot(contains('extends Page<')));

            final Map<String, String> files = {
              for (final file in result.files) file.relativePath: file.content,
            };
            expected ??= files;
            expect(files, expected);
            expect(files['helpers/page.dart'], contains('class Page<T>'));
            expect(
              files['exports.dart'],
              contains('export "helpers/page.dart";'),
            );
            expect(
              files['stations/models/stations_page.dart'],
              contains('class StationsPage extends Page<Station>'),
            );
            expect(
              files['stations/stations_client.dart'],
              matches(r'Future<(?:models\.)?StationsPage>'),
            );
            expect(files['stations/models/station.dart'], contains('fromJson'));
          }
        }
      }
    }
  });
}
