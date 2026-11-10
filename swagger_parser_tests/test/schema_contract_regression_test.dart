@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/bodyless_success_driver.dart';
import 'support/test_platforms.dart';

Map<String, Object?> _object(Object? value) => value! as Map<String, Object?>;

void main() {
  test('builds reference, enum, required, and bodyless response contracts', () async {
    final Directory dir = await Directory('test')
        .createTemp('generated_schema_contracts_');
    addTearDown(() => dir.delete(recursive: true));
    Future<void> write(String path, String content) async {
      final file = File('${dir.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
    }

    Future<void> dart(List<String> args) async {
      final ProcessResult run = await Process.run(
        Platform.resolvedExecutable,
        args,
      );
      stdout.writeln(
        '${args.join(' ')}: ${(run.stdout as String).trim().split('\n').last}',
      );
      expect(run.exitCode, 0, reason: '${run.stdout}\n${run.stderr}');
    }

    Future<void> generate(
      String folder,
      SchemaSource source,
      GenerationConfig config,
    ) async {
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(source, config: config);
      expect(result.diagnostics, isEmpty);
      for (final GeneratedFile file in result.files) {
        await write('$folder/${file.relativePath}', file.content);
      }
    }

    Future<SchemaSource> source(String group) =>
        const FileSchemaSourceLoader().loadPath(
          '../swagger_parser/test/fixtures/e2e/$group/inputs/openapi.json',
        );
    await write(
      'analysis_options.yaml',
      'analyzer:\n  language:\n    strict-casts: true\n',
    );
    for (final DtoSerializer serializer in DtoSerializer.values) {
      final String prefix = serializer.name;
      for (final group in [
        'reference_annotations',
        'enum_members',
        'required_inference',
      ]) {
        await generate(
          '${prefix}_$group',
          await source(group),
          GenerationConfig(serializer: serializer),
        );
      }
      await generate(
        '${prefix}_inferred',
        await source('required_inference'),
        GenerationConfig(serializer: serializer, inferMissingRequired: true),
      );
      await write('${prefix}_test.dart', '''
import 'package:test/test.dart';
import '${prefix}_reference_annotations/api.dart' as refs;
import '${prefix}_enum_members/api.dart' as enums;
import '${prefix}_required_inference/api.dart' as optional;
import '${prefix}_inferred/api.dart' as inferred;

void main() {
  test('reuses referenced types and retains enum validation', () {
    final refs.Bar bar = refs.Bar(name: 'bar');
    final refs.Foo foo = refs.Foo(status: refs.Status.open, bar: bar);
    final refs.Status status = foo.status;
    final refs.Bar reused = foo.bar;
    expect(status, refs.Status.open);
    expect(identical(reused, bar), isTrue);
    final json = {'status': 'OPEN', 'bar': {'name': 'bar'}};
    expect(refs.Foo.fromJson(json).toJson(), json);
    expect(() => refs.Foo.fromJson({'status': 'INVALID', 'bar': {'name': 'bar'}}), throwsA(anything));
  });
  test('keeps signed enum names and round trips every unique member', () {
    expect(enums.Doors.fieldMinus1.toJson(), -1);
    expect(enums.Doors.field1.toJson(), 1);
    expect(enums.Sound.values, [enums.Sound.squeak, enums.Sound.noise]);
    for (final value in enums.Sound.values) {
      expect(enums.Sound.fromJson(value.toJson()), value);
    }
    for (final value in enums.Doors.values) {
      expect(enums.Doors.fromJson(value.toJson()), value);
    }
  });
  test('accepts missing fields by default and retains inference as an option', () {
    final value = optional.Foo.fromJson({});
    expect(value.a, isNull);
    expect(value.b, isNull);
    expect(optional.Foo().toJson(), <String, Object?>{});
    expect(() => inferred.Foo.fromJson({}), throwsA(anything));
    expect(inferred.Foo(a: 'value', b: 1).toJson(), {'a': 'value', 'b': 1});
  });
}
''');
    }
    for (final HttpClientBackend backend in HttpClientBackend.values) {
      for (final kind in ['json', 'text', 'bytes', 'stream']) {
        for (final original in [false, true]) {
          for (final background in kind == 'json' ? [false, true] : [false]) {
            final folder = '${backend.name}_${kind}_${original}_$background';
            final SchemaSource input = await source('bodyless_success');
            final document = jsonDecode(input.content) as Map<String, Object?>;
            if (kind != 'json') {
              _object(
                _object(
                  _object(
                    _object(_object(document['paths'])['/message'])['post'],
                  )['responses'],
                )['200'],
              )['content'] = {
                kind == 'text' ? 'text/plain' : 'application/octet-stream': {
                  'schema': {
                    'type': 'string',
                    if (kind != 'text') 'format': 'binary',
                  },
                },
              };
            }
            await generate(
              folder,
              SchemaSource.json(jsonEncode(document)),
              GenerationConfig(
                httpClient: backend,
                originalHttpResponse: original,
                decodeResponsesInBackground: background,
                streamBinaryResponses: kind == 'stream',
              ),
            );
            await write(
              '${folder}_test.dart',
              bodylessSuccessDriver(folder, backend, kind, original: original),
            );
          }
        }
      }
    }
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', dir.path]);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', dir.path]);
    }
  });
}
