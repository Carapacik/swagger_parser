import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';
import 'package:test/test.dart';

void main() {
  final model = DartGenerationModel(
    libraries: [
      DartLibraryModel(
        relativePath: 'models/id.dart',
        dtos: [DartDtoModel(name: 'Id')],
      ),
    ],
  );

  test('renders sorted helper files with independent exports and context', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer(
        {'exports': '{{defaultSource}}\n// Public API.'},
        files: const [
          TemplateFile(relativePath: 'z.dart', source: 'class Z {}'),
          TemplateFile(
            relativePath: 'internal/a.dart',
            source:
                '// {{kind}} {{options.rootApiClassName}}\n'
                '{{#files}}// {{relativePath}}\n{{/files}}class A {}',
            export: false,
          ),
        ],
      ),
    );
    final input = DartGenerationModel(
      libraries: [
        ...model.libraries,
        DartLibraryModel(relativePath: 'exports.dart', dtos: const []),
      ],
    );
    final GenerationResult result = generator.generate(input);
    expect(result.files.map((f) => f.relativePath), [
      'exports.dart',
      'internal/a.dart',
      'models/id.dart',
      'z.dart',
    ]);
    expect(result.files.first.content, contains('export "z.dart";'));
    expect(result.files.first.content, isNot(contains('internal/a.dart')));
    expect(result.files.first.content, contains('// Public API.'));
    expect(result.files[1].content, contains('// helper Api'));
    expect(result.files[1].content, contains('// models/id.dart'));
    expect(
      generator.generate(input).files.map((f) => f.content),
      result.files.map((f) => f.content),
    );
  });

  test('rejects unsafe, conflicting, and builder-owned helper paths', () {
    for (final path in [
      '',
      '/page.dart',
      '../page.dart',
      './page.dart',
      'a//page.dart',
      r'a\page.dart',
      'C:/page.dart',
      'a\u0000.dart',
      'page.txt',
      'models/id.dart',
      'MODELS/ID.dart',
      'models/id.dart/child.dart',
      'page.g.dart',
      'page.freezed.dart',
      'page.mapper.dart',
    ]) {
      final generator = DartGenerator(
        renderer: MustacheSourceRenderer(
          {},
          files: [TemplateFile(relativePath: path, source: 'class Page {}')],
        ),
      );
      expect(
        () => generator.generate(model),
        throwsA(isA<GenerationException>()),
        reason: path,
      );
    }
    for (final path in ['page.dart', 'PAGE.dart', 'page.dart/child.dart']) {
      final generator = DartGenerator(
        renderer: MustacheSourceRenderer(
          {},
          files: [
            const TemplateFile(
              relativePath: 'page.dart',
              source: 'class Page {}',
            ),
            TemplateFile(relativePath: path, source: 'class Other {}'),
          ],
        ),
      );
      expect(
        () => generator.generate(model),
        throwsA(isA<GenerationException>()),
        reason: path,
      );
    }
  });

  test('reports helper template and Dart syntax errors with paths', () {
    for (final source in ['{{#unclosed}}', 'class {']) {
      final generator = DartGenerator(
        renderer: MustacheSourceRenderer(
          {},
          files: [
            TemplateFile(relativePath: 'helpers/page.dart', source: source),
          ],
        ),
      );
      expect(
        () => generator.generate(model),
        throwsA(
          isA<GenerationException>().having(
            (e) => e.message,
            'message',
            contains('helpers/page.dart'),
          ),
        ),
      );
    }
  });

  test('exposes required and nullable policies to templates', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models': '// {{options.inferMissingRequired}} {{options.usePresenceRecords}}',
      }),
    );
    expect(
      generator.generate(model).files.single.content,
      contains('// false false'),
    );
    expect(
      generator
          .generate(
            model,
            config: const GenerationConfig(
              inferMissingRequired: true,
              usePresenceRecords: true,
            ),
          )
          .files
          .single
          .content,
      contains('// true true'),
    );
  });

  test('renders an in-memory override', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models': '{{defaultSource}}\nconst revision = {{contractVersion}};',
      }),
    );
    expect(
      generator.generate(model).files.single.content,
      contains('const revision = 1;'),
    );
  });

  test('keeps request support separate from DTO templates', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({'models': 'class ReplacedDto {}'}),
    );
    final GenerationResult result = generator.generate(
      DartGenerationModel(
        libraries: [
          DartLibraryModel(
            relativePath: 'http_request_options.dart',
            dtos: const [],
            httpRequestOptions: true,
          ),
        ],
      ),
      config: const GenerationConfig(httpClient: HttpClientBackend.http),
    );
    expect(result.files.single.content, contains('class HttpRequestOptions'));
    expect(result.files.single.content, isNot(contains('ReplacedDto')));
  });

  test('keeps response support separate from DTO templates', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models': 'class ReplacedDto {}',
        'support': '{{defaultSource}}\nconst responseSupport = true;',
      }),
    );
    final GenerationResult result = generator.generate(
      DartGenerationModel(
        libraries: [
          DartLibraryModel(
            relativePath: 'http_response.dart',
            dtos: const [],
            httpResponse: true,
          ),
        ],
      ),
      config: const GenerationConfig(
        httpClient: HttpClientBackend.http,
        originalHttpResponse: true,
        decodeResponsesInBackground: true,
        applyParameterDefaults: true,
      ),
    );
    expect(result.files.single.content, contains('class HttpResponse<T>'));
    expect(
      result.files.single.content,
      contains('const responseSupport = true;'),
    );
    expect(result.files.single.content, isNot(contains('ReplacedDto')));
  });

  test('exposes validator options and classifies error support', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models': 'class ReplacedDto {}',
        'support': '{{defaultSource}}\n// {{options.generateValidators}} {{library.validationErrorName}}',
      }),
    );
    final GenerationResult result = generator.generate(
      DartGenerationModel(
        libraries: [
          DartLibraryModel(
            relativePath: 'dto_validation_error.dart',
            dtos: const [],
            validationErrors: true,
          ),
        ],
      ),
      config: const GenerationConfig(generateValidators: true),
    );
    expect(result.files.single.content, contains('class DtoValidationError'));
    expect(result.files.single.content, contains('// true DtoValidationError'));
    expect(result.files.single.content, isNot(contains('ReplacedDto')));
  });

  test('exposes metadata context without applying DTO templates', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models': 'class ReplacedDto {}',
        'support':
            '{{defaultSource}}\n'
            '// attach: {{options.apiMetadata}}\n'
            '// type: {{library.metadataTypeName}}\n'
            '{{#library.metadataOperations}}'
            '// {{operationId}} {{tags}} {{externalDocsUrl}}\n'
            '{{/library.metadataOperations}}',
      }),
    );
    final GenerationResult result = generator.generate(
      DartGenerationModel(
        libraries: [
          DartLibraryModel(
            relativePath: 'api_metadata.dart',
            dtos: const [],
            apiMetadata: true,
          ),
          DartLibraryModel(
            relativePath: 'stations/metadata.dart',
            dtos: const [],
            clientMetadataName: 'StationsMetadata',
            metadataOperations: [
              DartClientOperation(
                name: 'lookup',
                method: 'GET',
                path: '/stations',
                status: 204,
                response: DartTypeReference(symbol: 'void'),
                objectResponse: false,
                parameters: const [],
                operationId: 'sourceLookup',
                tags: const ['Station'],
                externalDocsUrl: 'https://example.test/docs',
              ),
            ],
          ),
        ],
      ),
      config: const GenerationConfig(
        apiMetadata: ApiMetadataMode.generateAndAttach,
      ),
    );
    final String source = result.files.map((f) => f.content).join();
    expect(source, contains('class OperationMetadata'));
    expect(source, contains('class StationsMetadata'));
    expect(source, contains('// attach: generateAndAttach'));
    expect(source, contains('sourceLookup'));
    expect(source, contains('https://example.test/docs'));
    expect(source, isNot(contains('ReplacedDto')));
  });

  test('rejects an unknown output path', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models/missing.dart': '{{defaultSource}}',
      }),
    );
    expect(
      () => generator.generate(model),
      throwsA(
        isA<GenerationException>().having(
          (e) => e.message,
          'message',
          contains('models/missing.dart'),
        ),
      ),
    );
  });

  test('exposes structural union fallback names', () async {
    final runner = SwaggerParserRunner(
      generator: DartGenerator(
        renderer: MustacheSourceRenderer({
          'models':
              '{{defaultSource}}\n'
              '{{#library.structuralUnions}}'
              '// fallback: {{name}} {{unknownType}}\n'
              '{{/library.structuralUnions}}',
        }),
      ),
    );
    for (final UnknownValueMode mode in UnknownValueMode.values) {
      final GenerationResult result = await runner.generate(
        const SchemaSource.json('''
      {
        "openapi": "3.0.0",
        "info": {"title": "Unions", "version": "1"},
        "paths": {},
        "components": {"schemas": {
          "Choice": {"oneOf": [{"type": "string"}, {"type": "integer"}]},
          "Views": {"anyOf": [{"type": "string"}, {"type": "integer"}]}
        }}
      }'''),
        config: GenerationConfig(unmatchedUnionValues: mode),
      );
      expect(result.diagnostics, isEmpty);
      final String output = result.files.map((f) => f.content).join();
      for (final name in ['Choice', 'Views']) {
        expect(
          output,
          contains(
            mode == UnknownValueMode.preserve
                ? '// fallback: $name ${name}Unknown'
                : '// fallback: $name',
          ),
        );
      }
    }
  });

  test('exposes naming options to templates', () {
    final generator = DartGenerator(
      renderer: MustacheSourceRenderer({
        'models':
            '{{defaultSource}}\n'
            '// {{options.fallbackClientName}} '
            '{{options.naming.preserveSchemaCasing}}\n'
            '// {{options.unknownEnumValues}} {{options.unknownDiscriminatorValues}}\n'
            '// unmatched: {{options.unmatchedUnionValues}}\n'
            '// bodyPositional: {{options.bodyPositional}}\n'
            '// pathNames: {{options.usePathForMethodNames}}\n'
            '// fileSuffix: {{options.fileSuffix}}\n'
            '// originalHttpResponse: {{options.originalHttpResponse}}\n'
            '// decodeResponsesInBackground: {{options.decodeResponsesInBackground}}\n'
            '// applyParameterDefaults: {{options.applyParameterDefaults}}\n'
            '// prune: {{options.pruneUnusedModels}}\n'
            '{{#options.keepModels}}// keep: {{.}}\n{{/options.keepModels}}\n'
            '{{#options.excludeParameters}}// exclude: {{name}} {{location}}\n{{/options.excludeParameters}}\n'
            '{{#options.naming.replaceRules}}'
            '// {{target}} {{pattern}} -> {{replacement}}\n'
            '{{/options.naming.replaceRules}}',
      }),
    );
    final GenerationResult result = generator.generate(
      model,
      config: const GenerationConfig(
        fallbackClientName: 'CommonClient',
        unmatchedUnionValues: UnknownValueMode.preserve,
        fileSuffix: '_generated',
        pruneUnusedModels: true,
        keepModels: ['#/components/schemas/Station'],
        excludeParameters: [
          ParameterExclusion(name: 'trace', location: 'header'),
        ],
        bodyPositional: true,
        usePathForMethodNames: true,
        originalHttpResponse: true,
        decodeResponsesInBackground: true,
        applyParameterDefaults: true,
        unknownEnumValues: UnknownValueMode.preserve,
        naming: NamingConfig(
          preserveSchemaCasing: true,
          replaceRules: [
            NameReplacementRule(
              target: NamingTarget.models,
              pattern: r'Dto$',
              replacement: '',
            ),
          ],
        ),
      ),
    );
    expect(
      result.files.single.content,
      contains('// applyParameterDefaults: true'),
    );
    expect(result.files.single.content, contains('// bodyPositional: true'));
    expect(result.files.single.content, contains('// unmatched: preserve'));
    expect(result.files.single.content, contains('// pathNames: true'));
    expect(result.files.single.content, contains('// fileSuffix: _generated'));
    expect(
      result.files.single.content,
      contains('// originalHttpResponse: true'),
    );
    expect(
      result.files.single.content,
      contains('// decodeResponsesInBackground: true'),
    );
    expect(result.files.single.content, contains('// CommonClient true'));
    expect(result.files.single.content, contains('// prune: true'));
    expect(
      result.files.single.content,
      contains('// keep: #/components/schemas/Station'),
    );
    expect(result.files.single.content, contains('// exclude: trace header'));
    expect(result.files.single.content, contains('// preserve reject'));
    expect(result.files.single.content, contains(r'// models Dto$ ->'));
  });
}
