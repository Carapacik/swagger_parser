@TestOn('vm')
library;

import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('swagger-v2-input-');
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'loads JSON and YAML filename variants without changing bytes',
    () async {
      for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final ext in ['json', 'JSON', 'yaml', 'YAML', 'yml', 'YML']) {
          final format = ext.toLowerCase() == 'json' ? 'json' : 'yaml';
          final input = File(
            'test/fixtures/collections/nullability/$version.$format',
          );
          final file = File('${directory.path}/api.$ext');
          await input.copy(file.path);
          final SchemaSource source = await const FileSchemaSourceLoader()
              .loadPath(file.path);
          expect(source.uri, file.absolute.uri);
          expect(source.content, await input.readAsString());
          expect(
            source.format,
            format == 'json' ? SchemaFormat.json : SchemaFormat.yaml,
          );
          expect(const OpenApiParser().parse(source).toJson(), isNotEmpty);
        }
      }
    },
  );

  test('keeps JSON syntax strict for json files', () async {
    final file = File('${directory.path}/api.json');
    await file.writeAsString(
      "{swagger: '2.0', info: {title: API, version: '1'}, paths: {}}",
    );
    final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
      file.path,
    );
    expect(source.format, SchemaFormat.json);
    expect(
      () => const OpenApiParser().parse(source),
      throwsA(isA<SchemaParseException>()),
    );
  });

  test('rejects non-file URIs', () {
    expect(
      const FileSchemaSourceLoader().load(
        Uri.parse('https://example.com/api.yaml'),
      ),
      throwsArgumentError,
    );
  });
}
