@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

Future<GenerationResult> _generate(
  String version,
  String ext,
  GenerationConfig config,
) async => await const SwaggerParserRunner().generate(
  await const FileSchemaSourceLoader().loadPath(
    'test/fixtures/union_titles/titles_v$version.$ext',
  ),
  config: config,
);

void main() {
  test('names inline union branches from titles across serializers', () async {
    for (final DtoSerializer serializer in DtoSerializer.values) {
      for (final version in ['3_0', '3_1', '3_2']) {
        final config = GenerationConfig(serializer: serializer);
        final GenerationResult json = await _generate(version, 'json', config);
        final GenerationResult yaml = await _generate(version, 'yaml', config);
        expect(json.diagnostics, isEmpty);
        expect(yaml.diagnostics, isEmpty);
        expect(
          {for (final f in json.files) f.relativePath: f.content},
          {for (final f in yaml.files) f.relativePath: f.content},
        );
        final String source = json.files.map((f) => f.content).join();
        for (final name in [
          'IdentifierExternalCode',
          'IdentifierInternalId',
          'StopRail',
          'StopBus',
          'ContactById',
          'ContactByEmail',
          'MergedOnline',
          'MergedOffline',
          'ComposedRail',
          'ComposedBus',
          'StateOnline',
          'StateOffline',
          'TaggedAnyReady',
          'TaggedAnyBusy',
          'RailStop',
          'BusStop',
          'ChoicesSameName',
          'ChoicesSameName2',
          'GlobalChoiceBranch2',
          'FallbackString',
          'FallbackInteger',
        ]) {
          expect(
            RegExp('class (?:const )?${RegExp.escape(name)}[\\s({]')
                .hasMatch(source),
            isTrue,
            reason: '$version $serializer: $name',
          );
        }
        for (final label in [
          'ById',
          'ByEmail',
          'RailStop',
          'BusStop',
          'SameName',
          'SameName2',
          'Boolean',
          'Array',
          'Class',
          'Model123Id',
        ]) {
          expect(source, contains('has$label'));
          expect(source, contains('get as$label'));
        }
        expect(source, contains('sealed class Identifier'));
        expect(source, isNot(contains('class RailStation')));
        expect(source, isNot(contains('IgnoredLocalTitle')));
        expect(source, isNot(contains('StateVariant1')));
        expect(source, contains(r'sealed class Directional$Request'));
        expect(source, contains(r'DirectionalCreated$Request'));
        expect(source, contains(r'DirectionalCreated$Response'));
      }
    }
  });

  test('keeps titled const branches as unions', () async {
    for (final version in ['3_1', '3_2']) {
      for (final ext in ['json', 'yaml']) {
        final GenerationResult result = await _generate(
          version,
          ext,
          const GenerationConfig(),
        );
        final String source = result.files.map((f) => f.content).join();
        expect(source, contains('sealed class Status'));
        expect(source, contains('class StatusEnabled implements Status'));
        expect(source, contains('class StatusDisabled implements Status'));
        expect(source, contains('enum StatusEnabledValue'));
        expect(source, contains('enum StatusDisabledValue'));
        expect(source, isNot(contains('enum Status {')));
        expect(source, contains('get asEnabled'));
        expect(source, contains('get asDisabled'));
      }
    }
  });

  test('applies model replacements after inline branch titles', () async {
    for (final ext in ['json', 'yaml']) {
      final GenerationResult result = await _generate(
        '3_2',
        ext,
        const GenerationConfig(
          naming: NamingConfig(
            replaceRules: [
              NameReplacementRule(
                target: NamingTarget.models,
                pattern: '^IdentifierExternalCode',
                replacement: 'ExternalKey',
              ),
              NameReplacementRule(
                target: NamingTarget.models,
                pattern: '^ContactById',
                replacement: 'ContactLookup',
              ),
            ],
          ),
        ),
      );
      expect(result.diagnostics, isEmpty);
      final String source = result.files.map((f) => f.content).join();
      expect(source, contains('class ExternalKey implements Identifier'));
      expect(source, contains('ContactLookup? get asById'));
      expect(source, isNot(contains('class IdentifierExternalCode')));
      expect(source, isNot(contains('class ContactById')));
    }
  });
}
