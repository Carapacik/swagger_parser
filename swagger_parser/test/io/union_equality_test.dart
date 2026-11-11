@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  for (final DtoSerializer serializer in DtoSerializer.values) {
    test('generates wrapper equality for ${serializer.name}', () async {
      Map<String, String>? baseline;
      for (final format in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath(
              'test/fixtures/e2e/union_equality/inputs/openapi.$format',
            );
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(source, config: GenerationConfig(serializer: serializer));
        expect(result.diagnostics, isEmpty);
        final files = <String, String>{
          for (final file in result.files) file.relativePath: file.content,
        };
        baseline ??= files;
        expect(files, baseline);
        final String primitive = files.values.singleWhere(
          (source) => source.contains('class FooFlagBoolean '),
        );
        expect(primitive, contains('const FooFlagBoolean(this.value)'));
        expect(primitive, contains('Object? toJson() => value;'));
        final String scalar = files['models/scalar_choice.dart']!;
        final String alias = files['models/named_boolean.dart']!;
        if (serializer == DtoSerializer.freezed) {
          for (final source in [primitive, scalar, alias]) {
            expect(
              source,
              contains('@Freezed(fromJson: false, toJson: false)'),
            );
            expect(source, isNot(contains('bool operator ==')));
            expect(source, isNot(contains('get hashCode')));
            expect(source, contains('.freezed.dart'));
            expect(
              RegExp('package:freezed_annotation/freezed_annotation.dart')
                  .allMatches(source),
              hasLength(1),
            );
          }
          expect(scalar, contains(r'with _$ScalarChoiceBoolean'));
          expect(scalar, isNot(contains("part 'scalar_choice.g.dart'")));
          expect(alias, contains(r'with _$NamedBoolean'));
          expect(alias, isNot(contains("part 'named_boolean.g.dart'")));
          expect(files.keys, contains('models/deep_collection_equality2.dart'));
        } else {
          for (final source in [primitive, scalar, alias]) {
            expect(source, isNot(contains('bool operator ==')));
            expect(source, isNot(contains('DeepCollectionEquality().hash')));
          }
        }
      }
    });
    test('delegates model behavior to ${serializer.name}', () async {
      Map<String, String>? baseline;
      for (final format in ['json', 'yaml']) {
        final SchemaSource source = await const FileSchemaSourceLoader()
            .loadPath('test/fixtures/e2e/union_equality/inputs/models.$format');
        final GenerationResult result = await const SwaggerParserRunner()
            .generate(
              source,
              config: GenerationConfig(
                serializer: serializer,
                httpClient: HttpClientBackend.dio,
                responseMode: ResponseMode.allStatuses,
                unknownEnumValues: UnknownValueMode.preserve,
                unknownDiscriminatorValues: UnknownValueMode.preserve,
                unmatchedUnionValues: UnknownValueMode.preserve,
              ),
            );
        expect(result.diagnostics, isEmpty);
        final Map<String, String> files = {
          for (final file in result.files) file.relativePath: file.content,
        };
        baseline ??= files;
        expect(files, baseline);
        final String sourceCode = files.values.join('\n');
        if (serializer == DtoSerializer.freezed) {
          for (final name in [
            'Envelope',
            'Position',
            'ChoiceBoolean',
            'ChoiceArray',
            'ChoiceUnknown',
            'Views',
            'ViewsUnknown',
            'ViewsObject',
            'ViewsObject2',
            'Cat',
            'Dog',
            'TaggedUnknown',
            'StatusKnown',
            'StatusUnknown',
            'ReadModels200',
            'ReadModels204',
            'ReadModelsDefault',
          ]) {
            expect(sourceCode, contains('with _\$$name'), reason: name);
          }
          expect(sourceCode, isNot(contains('bool operator ==')));
          expect(sourceCode, isNot(contains('get hashCode')));
          for (final name in ['position', 'views', 'choice', 'status']) {
            final String file = files['default_client/models/$name.dart']!;
            expect(file, contains("part '$name.freezed.dart'"));
            expect(file, isNot(contains("part '$name.g.dart'")));
          }
          final String snapshots = files['default_client/models/views.dart']!;
          expect(RegExp('copyWith: false').allMatches(snapshots), hasLength(2));
          expect(
            files['default_client/models/position.dart'],
            contains('copyWith: false'),
          );
          final String client = files['default_client/api_client.dart']!;
          expect(client, isNot(contains('@Freezed')));
          expect(files['api.dart'], isNot(contains('@Freezed')));
        } else {
          expect(sourceCode, isNot(contains('freezed_annotation')));
          expect(sourceCode, isNot(contains('.freezed.dart')));
        }
      }
    });
  }
}
