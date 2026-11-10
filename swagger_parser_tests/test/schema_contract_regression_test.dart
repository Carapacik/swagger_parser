@TestOn('vm')
@Timeout(Duration(minutes: 5))
library;

import 'dart:convert';
import 'dart:io';

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'support/bodyless_success_driver.dart';
import 'support/consumer_matrix.dart';
import 'support/contextual_identifiers_driver.dart';
import 'support/test_platforms.dart';
import 'support/unmatched_unions_driver.dart';

Map<String, Object?> _object(Object? value) => value! as Map<String, Object?>;

void main() {
  test('builds grouped model, union, and response contracts', () async {
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
      final document = jsonDecode(
        (await source('unmatched_unions')).content,
      ) as Map<String, Object?>;
      final Map<String, Object?> schemas = _object(
        _object(document['components'])['schemas'],
      );
      for (final (group, name) in [
        ('reference_annotations', 'ReferenceModel'),
        ('reference_metadata', 'MetadataModel'),
        ('enum_members', ''),
        ('required_inference', 'OptionalModel'),
      ]) {
        final extra =
            jsonDecode((await source(group)).content) as Map<String, Object?>;
        expect(extra['openapi'], document['openapi']);
        expect(extra['paths'], isEmpty);
        final Map<String, Object?> additions = _object(
          _object(extra['components'])['schemas'],
        );
        for (final MapEntry<String, Object?> entry in additions.entries) {
          final String key = entry.key == 'Foo' ? name : entry.key;
          expect(schemas.containsKey(key), isFalse);
          schemas[key] = entry.value;
        }
      }
      const mappings = [
        TypeMapping(
          schema: '#/components/schemas/Timestamp',
          dartType: 'OffsetTimestamp',
          importUrl: 'package:swagger_parser_tests/offset_timestamp.dart',
          codec: TypeMappingCodec(
            importUrl: 'package:swagger_parser_tests/offset_timestamp.dart',
            fromJson: 'readOffsetTimestamp',
            toJson: 'writeOffsetTimestamp',
          ),
        ),
      ];
      for (final UnknownValueMode mode in UnknownValueMode.values) {
        final folder = '${prefix}_${mode.name}';
        await generate(
          folder,
          mode == UnknownValueMode.reject
              ? SchemaSource.json(jsonEncode(document))
              : await source('unmatched_unions'),
          GenerationConfig(
            serializer: serializer,
            unmatchedUnionValues: mode,
            generateValidators:
                serializer == DtoSerializer.plain &&
                mode == UnknownValueMode.preserve,
            typeMappings: mappings,
          ),
        );
        await write(
          '${folder}_test.dart',
          unmatchedUnionsDriver(
            folder,
            preserve: mode == UnknownValueMode.preserve,
            validate: serializer == DtoSerializer.plain,
          ),
        );
      }
      await generate(
        '${prefix}_inferred',
        await source('required_inference'),
        GenerationConfig(serializer: serializer, inferMissingRequired: true),
      );
      await write('${prefix}_test.dart', '''
import 'package:test/test.dart';
import '${prefix}_reject/api.dart' as contracts;
import '${prefix}_inferred/api.dart' as inferred;

void main() {
  test('uses enum defaults and rejects undeclared reference values', () {
    final contracts.MetadataModel value = contracts.MetadataModel.fromJson({});
    final contracts.Language language = value.language;
    final contracts.Reason? reason = value.reason;
    expect(language, contracts.Language.de);
    expect(reason, isNull);
    expect(value.toJson(), {'language': 'de'});
    expect(contracts.MetadataModel(language: contracts.Language.en, reason: contracts.Reason.field1).toJson(), {'language': 'en', 'reason': 1});
    final json = {'language': 'en', 'reason': 0};
    expect(contracts.MetadataModel.fromJson(json).toJson(), json);
    expect(() => contracts.MetadataModel.fromJson({'language': 'xx'}), throwsA(anything));
    expect(() => contracts.MetadataModel.fromJson({'reason': 7}), throwsA(anything));
  });
  test('distinguishes absent fields from explicit null', () {
    expect(contracts.MetadataModel.fromJson({}).reason, isNull);
    expect(() => contracts.MetadataModel.fromJson({'language': null}), throwsA(anything));
    expect(() => contracts.MetadataModel.fromJson({'reason': null}), throwsA(anything));
  });
  test('reuses referenced types and retains enum validation', () {
    final contracts.Bar bar = contracts.Bar(name: 'bar');
    final contracts.ReferenceModel foo = contracts.ReferenceModel(status: contracts.Status.open, bar: bar);
    final contracts.Status status = foo.status;
    final contracts.Bar reused = foo.bar;
    expect(status, contracts.Status.open);
    expect(identical(reused, bar), isTrue);
    final json = {'status': 'OPEN', 'bar': {'name': 'bar'}};
    expect(contracts.ReferenceModel.fromJson(json).toJson(), json);
    expect(() => contracts.ReferenceModel.fromJson({'status': 'INVALID', 'bar': {'name': 'bar'}}), throwsA(anything));
  });
  test('keeps signed enum names and round trips every unique member', () {
    expect(contracts.Doors.fieldMinus1.toJson(), -1);
    expect(contracts.Doors.field1.toJson(), 1);
    expect(contracts.Sound.values, [contracts.Sound.squeak, contracts.Sound.noise]);
    for (final value in contracts.Sound.values) {
      expect(contracts.Sound.fromJson(value.toJson()), value);
    }
    for (final value in contracts.Doors.values) {
      expect(contracts.Doors.fromJson(value.toJson()), value);
    }
  });
  test('accepts missing fields by default and retains inference as an option', () {
    final value = contracts.OptionalModel.fromJson({});
    expect(value.a, isNull);
    expect(value.b, isNull);
    expect(contracts.OptionalModel().toJson(), <String, Object?>{});
    expect(() => inferred.Foo.fromJson({}), throwsA(anything));
    expect(inferred.Foo(a: 'value', b: 1).toJson(), {'a': 'value', 'b': 1});
  });
}
''');
      for (final HttpClientBackend backend in HttpClientBackend.values) {
        final folder = '${prefix}_${backend.name}_contextual';
        await generate(
          folder,
          await source('contextual_identifiers'),
          GenerationConfig(serializer: serializer, httpClient: backend),
        );
        await write(
          '${folder}_test.dart',
          contextualIdentifiersDriver(folder, backend),
        );
      }
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
    final String entryPoint = await groupConsumerTests(dir);
    await dart(['run', 'build_runner', 'build']);
    await dart(['analyze', dir.path]);
    await dart(['test', entryPoint]);
    if (runChromeTests) {
      await dart(['test', '--platform=chrome', entryPoint]);
    }
  });
}
