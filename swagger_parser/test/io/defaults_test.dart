@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> generate(
  String stem,
  String ext,
  DtoSerializer serializer,
) async => await const SwaggerParserRunner().generate(
  await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/defaults/$stem.$ext',
  ),
  config: GenerationConfig(serializer: serializer),
);

void main() {
  test('maps defaults from paired documents with every serializer', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        final GenerationResult json = await generate(
          'defaults_v$version',
          'json',
          serializer,
        );
        final GenerationResult yaml = await generate(
          'defaults_v$version',
          'yaml',
          serializer,
        );
        expect(json.diagnostics, isEmpty);
        expect(
          {for (final f in json.files) f.relativePath: f.content},
          {for (final f in yaml.files) f.relativePath: f.content},
        );
        final String source = json.files.map((f) => f.content).join();
        expect(source, contains('= 20'));
        expect(source, contains('= false'));
        expect(source, contains('Status.new2'));
        if (serializer == DtoSerializer.freezed) {
          expect(source, contains(r'class const Options2$Request('));
          expect(source, isNot(contains(r'abstract class Options2$Request')));
        }
      }
    }
  });

  test('rejects defaults that cannot initialize the generated type', () async {
    for (final stem in [
      'invalid_type',
      'invalid_null',
      'invalid_enum',
      'runtime_default',
    ]) {
      for (final ext in ['json', 'yaml']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          await expectLater(
            generate(stem, ext, serializer),
            throwsA(isA<GenerationException>()),
          );
        }
      }
    }
  });

  test(
    'maps PATCH presence independently from defaults and wire names',
    () async {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          for (final records in [false, true]) {
            Map<String, String>? expected;
            for (final ext in ['json', 'yaml']) {
              final mapper = _Mapper();
              final GenerationResult result =
                  await SwaggerParserRunner(mapper: mapper).generate(
                    await const FileSchemaSourceLoader().loadPath(
                      'test/fixtures/defaults/defaults_v$version.$ext',
                    ),
                    config: GenerationConfig(
                      serializer: serializer,
                      usePresenceRecords: records,
                      inferMissingRequired: false,
                    ),
                  );
              expect(result.diagnostics, isEmpty);
              final Map<String, String> files = {
                for (final file in result.files)
                  file.relativePath: file.content,
              };
              expected ??= files;
              expect(files, expected);
              final Map<String, DartDtoModel> dtos = {
                for (final dto in mapper.model.libraries.expand((l) => l.dtos))
                  dto.name: dto,
              };
              final Map<String, DartFieldModel> changes = {
                for (final field in dtos['PatchChanges']!.fields)
                  field.wireName!: field,
              };
              expect(
                changes.keys,
                unorderedEquals([
                  'notes',
                  'notesPresent',
                  'display-name',
                  'alias',
                  'nested',
                  'copyWith',
                ]),
              );
              for (final name in ['notes', 'display-name', 'alias']) {
                expect(changes[name]!.tracksPresence, records);
                expect(changes[name]!.isRequired, isFalse);
              }
              expect(changes['notesPresent']!.name, 'notesPresent');
              expect(changes['notesPresent']!.acceptsNull, isFalse);
              expect(changes['notesPresent']!.tracksPresence, isFalse);
              expect(changes.values.map((f) => f.name).toSet(), hasLength(6));
              final Map<String, DartFieldModel> envelope = {
                for (final field in dtos['PatchEnvelope']!.fields)
                  field.wireName!: field,
              };
              expect(envelope['required_note']!.isRequired, isTrue);
              expect(envelope['required_note']!.tracksPresence, isFalse);
              expect(envelope['required_note']!.defaultExpression, isNull);
              expect(envelope['default_label']!.tracksPresence, isFalse);
              expect(envelope['default_label']!.defaultExpression, isNotNull);
            }
          }
        }
      }
    },
  );
}

final class _Mapper() implements DartModelMapper {
  late DartGenerationModel model;

  @override
  DartGenerationModel map(ApiDefinition api, GenerationConfig config) =>
      model = const DartModelMapper().map(api, config);
}
