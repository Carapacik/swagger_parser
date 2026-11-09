@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';
import 'package:test/test.dart';

import 'support/test_platforms.dart';

void main() {
  test(
    'builds generic page helpers with all serializers and clients',
    () async {
      final Directory dir = await Directory('test')
          .createTemp('generated_helpers_');
      addTearDown(() => dir.delete(recursive: true));
      Future<void> write(String path, String source) async {
        final file = File('${dir.path}/$path');
        await file.parent.create(recursive: true);
        await file.writeAsString(source);
      }

      Future<void> dart(List<String> args) async {
        final ProcessResult result = await Process.run(
          Platform.resolvedExecutable,
          args,
        );
        expect(
          result.exitCode,
          0,
          reason: '${args.join(' ')}\n${result.stdout}\n${result.stderr}',
        );
      }

      await write(
        'analysis_options.yaml',
        'analyzer:\n  language:\n    strict-casts: true\n',
      );
      const base = '../swagger_parser_templates/test/fixtures/pagination';
      final runner = SwaggerParserRunner(
        generator: DartGenerator(
          renderer: MustacheSourceRenderer(
            {
              'stations/models/stations_page.dart': await File(
                '$base/stations_page.mustache',
              ).readAsString(),
            },
            files: [
              TemplateFile(
                relativePath: 'helpers/page.dart',
                source: await File('$base/page.mustache').readAsString(),
              ),
            ],
          ),
        ),
      );
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final HttpClientBackend backend in HttpClientBackend.values) {
          final folder = '${serializer.name}_${backend.name}';
          final GenerationResult result = await runner.generate(
            await const FileSchemaSourceLoader().loadPath('$base/v3_2.yaml'),
            config: GenerationConfig(
              serializer: serializer,
              httpClient: backend,
            ),
          );
          expect(result.diagnostics, isEmpty);
          for (final GeneratedFile file in result.files) {
            await write('$folder/${file.relativePath}', file.content);
          }
          await write('${folder}_test.dart', '''
import 'package:test/test.dart';
import '$folder/api.dart';

void main() {
  test('reads a concrete page through the generic type', () {
    final json = <String, Object?>{
      'page': 2,
      'pageSize': 25,
      'results': [{'id': 'north'}],
    };
    final concrete = StationsPage.fromJson(json);
    final Page<Station> page = concrete;
    expect(page.page, 2);
    expect(page.pageSize, 25);
    expect(page.results.single.id, 'north');
    expect(concrete.toJson(), json);
    final rebuilt = StationsPage.fromJson(concrete.toJson());
    expect(rebuilt.results.single.id, 'north');
  });
}
''');
        }
      }
      await dart(['run', 'build_runner', 'build']);
      await dart(['analyze', dir.path]);
      await dart(['test', '--concurrency=1', dir.path]);
      if (runChromeTests) {
        await dart([
          'test',
          '--platform',
          'chrome',
          '--concurrency=1',
          dir.path,
        ]);
      }
    },
  );
}
