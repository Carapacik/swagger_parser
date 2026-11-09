@TestOn('vm')
library;

import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

void main() {
  test(
    'generates validators from paired schemas with each serializer',
    () async {
      for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
        for (final DtoSerializer serializer in DtoSerializer.values) {
          Map<String, String>? baseline;
          for (final format in ['json', 'yaml']) {
            const loader = FileSchemaSourceLoader();
            final GenerationResult result = await const SwaggerParserRunner()
                .generate(
                  await loader.loadPath(
                    'test/fixtures/dto_validation/$version.$format',
                  ),
                  loader: loader,
                  config: GenerationConfig(
                    serializer: serializer,
                    generateValidators: true,
                  ),
                );
            expect(result.diagnostics, isEmpty);
            final Map<String, String> files = {
              for (final f in result.files) f.relativePath: f.content,
            };
            baseline ??= files;
            expect(files, baseline);
            expect(
              files['dto_validation_error.dart'],
              contains('class DtoValidationError2'),
            );
            expect(
              files['exports.dart'],
              contains("export 'dto_validation_error.dart'"),
            );
            expect(files['models/station.dart'], contains('validate()'));
            expect(
              files['models/station.dart'],
              contains('StationValidation2'),
            );
            expect(files['models/station.dart'], contains('validate2'));
          }
        }
      }
    },
  );

  test('omits validators by default and loads input overrides', () async {
    for (final format in ['json', 'yaml']) {
      Future<CliConfig> config(String name) => CliConfig.load(
        configPath: 'test/fixtures/dto_validation/$name.$format',
      );
      expect(
        (await config('config_default')).generation.generateValidators,
        false,
      );
      expect(
        (await config('config_enabled')).generation.generateValidators,
        true,
      );
      final List<CliConfig> inputs = await CliConfig.loadAll(
        configPath: 'test/fixtures/dto_validation/config_inputs.$format',
      );
      expect(inputs.first.generation.generateValidators, false);
      expect(inputs.last.generation.generateValidators, true);
      await expectLater(config('config_invalid'), throwsA(anything));
      const loader = FileSchemaSourceLoader();
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            await loader.loadPath('test/fixtures/dto_validation/v3_2.$format'),
            loader: loader,
          );
      expect(
        result.files.any((f) => f.relativePath == 'dto_validation_error.dart'),
        false,
      );
      expect(result.files.any((f) => f.content.contains(' validate()')), false);
    }
  });
  test('rejects unsupported assertions with their schema path', () async {
    for (final format in ['json', 'yaml']) {
      final SchemaSource source = await const FileSchemaSourceLoader().loadPath(
        'test/fixtures/dto_validation/unsupported.$format',
      );
      await const SwaggerParserRunner().generate(source);
      await expectLater(
        const SwaggerParserRunner().generate(
          source,
          config: const GenerationConfig(generateValidators: true),
        ),
        throwsA(
          isA<GenerationException>().having(
            (e) => e.diagnostics.single.documentPath,
            'path',
            '/components/schemas/Station/dependentRequired',
          ),
        ),
      );
    }
  });
  test('keeps facade and validation support paths distinct', () async {
    for (final format in ['json', 'yaml']) {
      const loader = FileSchemaSourceLoader();
      final GenerationResult result = await const SwaggerParserRunner()
          .generate(
            await loader.loadPath('test/fixtures/dto_validation/v3_2.$format'),
            loader: loader,
            config: const GenerationConfig(
              generateValidators: true,
              rootApiClassName: 'DtoValidationError',
            ),
          );
      final Map<String, String> files = {
        for (final file in result.files) file.relativePath: file.content,
      };
      expect(files.length, result.files.length);
      expect(
        files['dto_validation_error.dart'],
        contains('class DtoValidationError'),
      );
      expect(
        files['dto_validation_error2.dart'],
        contains('class DtoValidationError3'),
      );
      expect(
        files['models/station.dart'],
        contains('../dto_validation_error2.dart'),
      );
    }
  });
}
