@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<SchemaSource> _load(String version, String ext) =>
    const FileSchemaSourceLoader().loadPath(
      'test/fixtures/fixed_discriminators/fixed_v$version.$ext',
    );

void main() {
  test(
    'keeps kind independent of the type discriminator in JSON and YAML',
    () async {
      for (final version in ['2_0', '3_0', '3_1', '3_2']) {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await _load(version, ext);
          final OpenApiDocument document = const OpenApiParser().parse(source);
          final ReferenceGraph graph = await const OpenApiReferenceResolver()
              .resolve(document, sourceUri: source.uri);
          final ApiDefinition api = const ApiDefinitionExtractor().extract(
            document,
            graph,
          );
          for (final DtoSerializer serializer in DtoSerializer.values) {
            final DartGenerationModel model = const DartModelMapper().map(
              api,
              GenerationConfig(serializer: serializer),
            );
            final DartDtoModel dto = model.libraries
                .expand((lib) => lib.dtos)
                .singleWhere((dto) => dto.name == 'TypedRailStop');
            final DartFieldModel tag = dto.fields.singleWhere(
              (f) => f.wireName == 'type',
            );
            final DartFieldModel kind = dto.fields.singleWhere(
              (f) => f.wireName == 'kind',
            );
            expect(tag.fixedValue!.value, 'rail');
            expect(kind.fixedValue, isNull);
            expect(kind.isRequired, isTrue);
            expect(kind.name, 'kind');
            expect(kind.type.symbol, 'String');
          }
        }
      }
    },
  );

  test(
    'rejects object defaults with a contradictory fixed discriminator',
    () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/fixed_discriminators/invalid_default.$ext',
            );
        await expectLater(
          const SwaggerParserRunner().generate(source),
          throwsA(isA<GenerationException>()),
        );
      }
    },
  );

  test(
    'renders fixed discriminators in all families and serializers',
    () async {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        for (final version in ['2_0', '3_0', '3_1', '3_2']) {
          final outputs = <Map<String, String>>[];
          for (final ext in ['json', 'yaml']) {
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await _load(version, ext),
                  config: GenerationConfig(serializer: serializer),
                );
            expect(result.diagnostics, isEmpty);
            outputs.add({
              for (final f in result.files) f.relativePath: f.content,
            });
          }
          expect(outputs.first, outputs.last);
          final String rail = outputs.first.values.singleWhere(
            (s) =>
                s.contains('class RailStop ') ||
                s.contains('class const RailStop('),
          );
          expect(rail, contains('get kind => RailStopKind.rail'));
          expect(rail, isNot(contains('required this.kind')));
          expect(rail, isNot(contains('required final RailStopKind kind')));
        }
      }
    },
  );

  test('fixes only required singleton discriminator fields', () async {
    for (final version in ['2_0', '3_0', '3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await _load(version, ext);
        final OpenApiDocument document = const OpenApiParser().parse(source);
        final Map<String, Object?> before = document.toJson();
        final ReferenceGraph graph = await const OpenApiReferenceResolver()
            .resolve(document, sourceUri: source.uri);
        final ApiDefinition api = const ApiDefinitionExtractor().extract(
          document,
          graph,
        );
        final DartGenerationModel model = const DartModelMapper().map(
          api,
          const GenerationConfig(),
        );
        final Map<String, DartDtoModel> dtos = {
          for (final lib in model.libraries)
            for (final dto in lib.dtos) dto.name: dto,
        };
        for (final name in [
          'RailStop',
          'BusStop',
          'Inherited',
          'Wrapped',
          'Closed',
        ]) {
          final DartFieldModel field = dtos[name]!.fields.singleWhere(
            (f) => f.wireName == 'kind',
          );
          expect(field.fixedValue, isNotNull, reason: name);
          expect(field.isRequired, isTrue);
        }
        for (final name in [
          'AliasStop',
          'OptionalStop',
          'Unmarked',
          'LooseStop',
          'NullableStop',
        ]) {
          expect(
            dtos[name]!.fields
                .singleWhere((f) => f.wireName == 'kind')
                .fixedValue,
            isNull,
            reason: name,
          );
        }
        expect(document.toJson(), before);
      }
    }
  });
}
