@TestOn('vm')
library;

import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

const _loader = FileSchemaSourceLoader();

Future<ApiDefinition> _extract(SchemaSource source) async {
  final OpenApiDocument document = const OpenApiParser().parse(source);
  expect(const OpenApiValidator().validate(document).diagnostics, isEmpty);
  final ReferenceGraph graph = await const OpenApiReferenceResolver().resolve(
    document,
    sourceUri: source.uri,
    loader: _loader,
  );
  expect(
    const ResolvedOperationValidator().validate(document, graph).diagnostics,
    isEmpty,
  );
  return const ApiDefinitionExtractor().extract(document, graph);
}

void main() {
  for (final version in ['v2', 'v3_0', 'v3_1', 'v3_2']) {
    final bool modern = version == 'v3_1' || version == 'v3_2';
    test('resolves reusable operation definitions in $version', () async {
      for (final ext in ['json', 'yaml']) {
        final SchemaSource source = await _loader.loadPath(
          'test/fixtures/references/$version.$ext',
        );
        final ApiDefinition api = await _extract(source);
        ApiOperation operation(String name) =>
            api.operations.singleWhere((op) => op.operationId == name);
        expect(api.operations, hasLength(12));
        final ApiOperation lookup = operation('lookup');
        final ApiOperation inline = operation('inlineLookup');
        expect(lookup.parameters.map((p) => (p.name, p.location)), [
          ('id', 'path'),
          ('limit', 'query'),
          ('tag', 'query'),
          ('limit', 'header'),
          ('query', 'query'),
        ]);
        Object? signature(ApiParameter p) => [
          p.name,
          p.location,
          p.isRequired,
          p.description,
          p.serialization.collectionFormat,
          p.serialization.style,
          p.serialization.explode,
          api.schemas[p.schema]?.definition.value,
        ];
        expect(
          lookup.parameters.map(signature),
          inline.parameters.map(signature),
        );
        final ApiParameter limit = lookup.parameters[1];
        expect(
          (api.schemas[limit.schema]!.definition.value!
              as Map<String, Object?>)['default'],
          7,
        );
        expect(limit.description, modern ? 'Local limit.' : 'Operation limit.');
        expect(limit.isRequired, false);
        expect(lookup.parameters[3].description, modern ? '' : 'Header limit.');
        expect(lookup.requestBody, isNull);
        expect(
          lookup.parameters[2].source.documentUri!.pathSegments.last,
          '${version}_targets.$ext',
        );
        final ApiRequestBody body = operation('login').requestBody!;
        expect(body.isRequired, isTrue);
        expect(
          body.description,
          modern ? 'Local credentials.' : 'Shared credentials.',
        );
        expect(
          body.source.documentUri!.pathSegments.last,
          '${version}_targets.$ext',
        );
        expect(
          api
              .schemas[body.content['application/json']!.schema]!
              .properties
              .keys,
          ['login', 'password'],
        );
        for (final (name, media) in [
          ('submitForm', 'application/x-www-form-urlencoded'),
          ('submitMultipart', 'multipart/form-data'),
        ]) {
          final ApiRequestBody form = operation(name).requestBody!;
          expect(form.content.keys, [media]);
          if (version == 'v2') {
            expect(form.formFields.map((p) => (p.name, p.isRequired)), [
              ('login', true),
              ('password', true),
            ]);
          } else {
            expect(form.isRequired, true);
            expect(
              form.description,
              name == 'submitForm'
                  ? 'Shared form fields.'
                  : 'Shared multipart fields.',
            );
            expect(
              form.source.pointer,
              name == 'submitForm'
                  ? '/components/requestBodies/FormBody'
                  : '/components/requestBodies/formBody',
            );
            expect(api.schemas[form.content[media]!.schema]!.properties.keys, [
              'login',
              'password',
            ]);
          }
        }
        expect(
          lookup.responses['200']!.description,
          modern ? 'Local item.' : 'Item response.',
        );
        expect(
          inline.responses['200']!.description,
          modern ? 'Alias item.' : 'Item response.',
        );
        final ApiResponse escaped = operation('escapedResponse')
            .responses['200']!;
        expect(
          escaped.source.pointer,
          '/paths/~1shared~1~0item/get/responses/200',
        );
        expect(
          escaped.source.documentUri!.pathSegments.last,
          '${version}_targets.$ext',
        );
        expect(
          api
              .schemas[escaped.content['application/json']!.schema]!
              .properties
              .keys,
          ['external'],
        );
        for (final (name, field) in [
          ('stationInfo', 'camel_code'),
          ('StationInfo', 'pascal_code'),
          ('stationinfo', 'flat_code'),
        ]) {
          expect(api.schemas[api.namedSchemas[name]]!.properties.keys, [field]);
        }
        expect(lookup.responses['400']!.description, 'Shared error.');
        expect(operation('failure').responses.keys, ['400']);
        expect(operation('accepted').responses.keys, ['202']);
        expect(api.schemas[api.namedSchemas['Station']]!.properties.keys, [
          'upper_code',
        ]);
        expect(api.schemas[api.namedSchemas['station']]!.properties.keys, [
          'lower_code',
        ]);
      }
    });
    test('generates reference imports and codecs for $version', () async {
      for (final DtoSerializer serializer in DtoSerializer.values) {
        Map<String, String>? expected;
        for (final ext in ['json', 'yaml']) {
          final GenerationResult result = await const SwaggerParserRunner()
              .generate(
                await _loader.loadPath(
                  'test/fixtures/references/$version.$ext',
                ),
                loader: _loader,
                config: GenerationConfig(
                  serializer: serializer,
                  generateValidators: true,
                  applyParameterDefaults: true,
                  inferMissingRequired: false,
                ),
              );
          expect(result.diagnostics, isEmpty);
          final Map<String, String> files = {
            for (final file in result.files) file.relativePath: file.content,
          };
          expected ??= files;
          expect(files, expected);
          final String client = files['default_client/api_client.dart']!;
          expect(client, contains('Future<Station> typed('));
          expect(client, contains('Future<void> failure('));
          expect(client, contains('Future<Station> accepted('));
          expect(client, contains('int? limit = 7'));
          expect(client, contains('int? limit2 = 9'));
          expect(
            client,
            contains(modern ? 'Local limit.' : 'Operation limit.'),
          );
          expect(client, isNot(contains('Ignored parameter summary.')));
          expect(client, isNot(contains('Ignored body summary.')));
          expect(client, isNot(contains('Ignored response summary.')));
          expect(
            client,
            contains('required Credentials${version == 'v2' ? '2' : ''} body'),
          );
          expect(files['exports.dart'], contains('station_alias_chain.dart'));
          expect(files.values.join(), isNot(contains("import 'null")));
        }
      }
    });
    test(
      'rejects a body without its required payload field in $version',
      () async {
        for (final ext in ['json', 'yaml']) {
          final SchemaSource source = await _loader.loadPath(
            'test/fixtures/references/${version}_invalid_body.$ext',
          );
          for (final DtoSerializer serializer in DtoSerializer.values) {
            await expectLater(
              const SwaggerParserRunner().generate(
                source,
                loader: _loader,
                config: GenerationConfig(serializer: serializer),
              ),
              throwsA(
                isA<OpenApiException>()
                    .having(
                      (e) => e.documentPath,
                      'pointer',
                      version == 'v2'
                          ? '/paths/~1invalid/post/parameters/0/schema'
                          : '/paths/~1invalid/post/requestBody/content',
                    )
                    .having((e) => e.sourceUri, 'URI', source.uri),
              ),
            );
          }
        }
      },
    );
    for (final error in ['cycle', 'missing', 'alias_cycle']) {
      test(
        error == 'alias_cycle'
            ? 'rejects cyclic schema aliases in $version'
            : 'reports a $error response reference in $version',
        () async {
          for (final ext in ['json', 'yaml']) {
            final SchemaSource source = await _loader.loadPath(
              'test/fixtures/references/${version}_$error.$ext',
            );
            await expectLater(
              const SwaggerParserRunner().generate(source, loader: _loader),
              throwsA(
                error == 'alias_cycle'
                    ? isA<GenerationException>().having(
                        (e) => e.diagnostics.single.code,
                        'code',
                        'unsupportedDartSchema',
                      )
                    : error == 'cycle'
                    ? isA<GenerationException>()
                          .having(
                            (e) => e.diagnostics.single.code,
                            'code',
                            'unresolvedDefinition',
                          )
                          .having(
                            (e) => e.diagnostics.single.documentPath,
                            'pointer',
                            '/paths/~1invalid/get/responses/200',
                          )
                    : isA<OpenApiException>().having(
                        (e) => e.documentPath,
                        'pointer',
                        r'/paths/~1invalid/get/responses/200/$ref',
                      ),
              ),
            );
          }
        },
      );
    }
  }
}
