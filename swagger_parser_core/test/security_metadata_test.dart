import 'dart:convert';

import 'package:swagger_parser_core/swagger_parser_core.dart';
import 'package:test/test.dart';

import 'support/read_input.dart';

void main() {
  const parser = OpenApiParser(
    config: ParseConfig(unknownFields: UnknownFieldPolicy.reject),
  );
  for (final version in ['v3_1', 'v3_2']) {
    for (final format in ['json', 'yaml']) {
      test(
        'preserves $version authentication and service metadata from $format',
        () async {
          final path = 'parsing/security_metadata/open_api_$version';
          final String text = await readInput('$path.$format');
          final Object? expected = jsonDecode(await readInput('$path.json'));
          final OpenApiDocument document = parser.parse(SchemaSource(text));
          expect(document.toJson(), expected);
          switch (document) {
            case final OpenApiV31Document doc:
              _checkV31(doc);
            case final OpenApiV32Document doc:
              _checkV32(doc);
            default:
              fail('Unexpected document version.');
          }
          final Map<String, Object?> exported = document.toJson();
          final components = exported['components']! as Map<String, Object?>;
          (components['securitySchemes']! as Map<String, Object?>).clear();
          (exported['servers']! as List<Object?>).clear();
          (exported['security']! as List<Object?>).clear();
          expect(document.toJson(), expected);
        },
      );
    }
  }
  for (final format in ['json', 'yaml']) {
    test('locates a bearer format on a basic scheme in $format', () async {
      final String text = await readInput(
        'parsing/security_metadata/invalid_bearer.$format',
      );
      final Uri uri = Uri.parse('https://example.org/invalid_bearer.$format');
      expect(
        () => parser.parse(SchemaSource(text, uri: uri)),
        throwsA(
          isA<SchemaParseException>()
              .having((error) => error.sourceUri, 'source', uri)
              .having(
                (error) => error.documentPath,
                'path',
                '/components/securitySchemes/basic/bearerFormat',
              )
              .having((error) => error.location, 'location', isNotNull)
              .having(
                (error) => error.toString(),
                'message',
                contains('Expected a bearer scheme.'),
              ),
        ),
      );
    });
  }
}

void _checkV31(OpenApiV31Document document) {
  expect(document.info.contact!.email, 'api@example.org');
  expect(document.info.termsOfService, 'https://example.org/terms');
  expect(document.info.license!.url, 'https://example.org/license');
  expect(
    document.tags!.single.externalDocs!.url,
    'https://example.org/stations',
  );
  expect(document.externalDocs!.description, 'API guide');
  final OpenApiV31Server server = document.servers!.single;
  expect(server.url, 'https://{region}.example.org/{version}');
  expect(server.variables!['region']!.enumValues, ['eu', 'us']);
  expect(server.variables!['version']!.enumValues, isNull);
  expect(server.variables!['version']!.defaultValue, 'v1');
  expect(server.variables!.clear, throwsUnsupportedError);
  expect(
    server.variables!['region']!.enumValues!.clear,
    throwsUnsupportedError,
  );

  final Map<String, OpenApiV31RefOr<OpenApiV31SecurityScheme>> schemes =
      document.components!.securitySchemes!;
  OpenApiV31SecurityScheme scheme(String name) =>
      (schemes[name]! as OpenApiV31Inline<OpenApiV31SecurityScheme>).value;
  for (final (name, location) in [
    ('queryKey', OpenApiV31ApiKeyLocation.query),
    ('headerKey', OpenApiV31ApiKeyLocation.header),
    ('cookieKey', OpenApiV31ApiKeyLocation.cookie),
  ]) {
    expect((scheme(name) as OpenApiV31ApiKeySecurityScheme).location, location);
  }
  final bearer = scheme('bearer') as OpenApiV31HttpSecurityScheme;
  expect(bearer.scheme, 'Bearer');
  expect(bearer.bearerFormat, 'JWT');
  expect(
    (scheme('basic') as OpenApiV31HttpSecurityScheme).bearerFormat,
    isNull,
  );
  expect(
    (scheme(
      'discovery',
    ) as OpenApiV31OpenIdConnectSecurityScheme).openIdConnectUrl,
    'https://example.org/.well-known/openid-configuration',
  );
  expect(scheme('certificate'), isA<OpenApiV31MutualTlsSecurityScheme>());

  final oauth = scheme('oauth') as OpenApiV31OAuth2SecurityScheme;
  expect(oauth.flows.implicit!.tokenUrl, isNull);
  expect(
    oauth.flows.implicit!.authorizationUrl,
    'https://example.org/authorize',
  );
  expect(oauth.flows.password!.authorizationUrl, isNull);
  expect(oauth.flows.password!.tokenUrl, 'https://example.org/password');
  expect(oauth.flows.password!.scopes, isEmpty);
  expect(oauth.flows.clientCredentials!.tokenUrl, 'https://example.org/token');
  expect(
    oauth.flows.authorizationCode!.refreshUrl,
    'https://example.org/refresh',
  );
  expect(oauth.flows.authorizationCode!.scopes, {
    'stations:read': 'Read stations',
    'stations:write': 'Update stations',
  });
  expect(oauth.flows.authorizationCode!.scopes.clear, throwsUnsupportedError);
  final List<OpenApiV31SecurityRequirement> security = document.security!;
  expect(security.first.schemes, {
    'oauth': ['stations:read'],
    'headerKey': <String>[],
  });
  expect(security[1].schemes, {'certificate': <String>[]});
  expect(security.last.schemes, isEmpty);
  expect(security.first.schemes.clear, throwsUnsupportedError);
  expect(security.first.schemes['oauth']!.clear, throwsUnsupportedError);
}

void _checkV32(OpenApiV32Document document) {
  expect(document.info.contact!.email, 'api@example.org');
  expect(document.info.termsOfService, 'https://example.org/terms');
  expect(document.info.license!.url, 'https://example.org/license');
  expect(
    document.tags!.single.externalDocs!.url,
    'https://example.org/stations',
  );
  expect(document.externalDocs!.description, 'API guide');
  final OpenApiV32Server server = document.servers!.single;
  expect(server.url, 'https://{region}.example.org/{version}');
  expect(server.variables!['region']!.enumValues, ['eu', 'us']);
  expect(server.variables!['version']!.enumValues, isNull);
  expect(server.variables!['version']!.defaultValue, 'v1');
  expect(server.variables!.clear, throwsUnsupportedError);
  expect(
    server.variables!['region']!.enumValues!.clear,
    throwsUnsupportedError,
  );

  final Map<String, OpenApiV32RefOr<OpenApiV32SecurityScheme>> schemes =
      document.components!.securitySchemes!;
  OpenApiV32SecurityScheme scheme(String name) =>
      (schemes[name]! as OpenApiV32Inline<OpenApiV32SecurityScheme>).value;
  for (final (name, location) in [
    ('queryKey', OpenApiV32ApiKeyLocation.query),
    ('headerKey', OpenApiV32ApiKeyLocation.header),
    ('cookieKey', OpenApiV32ApiKeyLocation.cookie),
  ]) {
    expect((scheme(name) as OpenApiV32ApiKeySecurityScheme).location, location);
  }
  final bearer = scheme('bearer') as OpenApiV32HttpSecurityScheme;
  expect(bearer.scheme, 'Bearer');
  expect(bearer.bearerFormat, 'JWT');
  expect(
    (scheme('basic') as OpenApiV32HttpSecurityScheme).bearerFormat,
    isNull,
  );
  expect(
    (scheme(
      'discovery',
    ) as OpenApiV32OpenIdConnectSecurityScheme).openIdConnectUrl,
    'https://example.org/.well-known/openid-configuration',
  );
  expect(scheme('certificate'), isA<OpenApiV32MutualTlsSecurityScheme>());

  final oauth = scheme('oauth') as OpenApiV32OAuth2SecurityScheme;
  expect(oauth.flows.implicit!.tokenUrl, isNull);
  expect(
    oauth.flows.implicit!.authorizationUrl,
    'https://example.org/authorize',
  );
  expect(oauth.flows.password!.authorizationUrl, isNull);
  expect(oauth.flows.password!.tokenUrl, 'https://example.org/password');
  expect(oauth.flows.password!.scopes, isEmpty);
  expect(oauth.flows.clientCredentials!.tokenUrl, 'https://example.org/token');
  expect(
    oauth.flows.authorizationCode!.refreshUrl,
    'https://example.org/refresh',
  );
  expect(oauth.flows.authorizationCode!.scopes, {
    'stations:read': 'Read stations',
    'stations:write': 'Update stations',
  });
  expect(oauth.flows.authorizationCode!.scopes.clear, throwsUnsupportedError);
  final List<OpenApiV32SecurityRequirement> security = document.security!;
  expect(security.first.schemes, {
    'oauth': ['stations:read'],
    'headerKey': <String>[],
  });
  expect(security[1].schemes, {'certificate': <String>[]});
  expect(security.last.schemes, isEmpty);
  expect(security.first.schemes.clear, throwsUnsupportedError);
  expect(security.first.schemes['oauth']!.clear, throwsUnsupportedError);
  expect(server.name, 'regional');
  expect(document.tags!.single.kind, 'nav');
  expect(document.tags!.single.summary, 'Stations');
  expect((scheme('basic') as OpenApiV32HttpSecurityScheme).deprecated, isTrue);
  expect(
    oauth.flows.deviceAuthorization!.deviceAuthorizationUrl,
    'https://example.org/device',
  );
  expect(
    oauth.flows.deviceAuthorization!.tokenUrl,
    'https://example.org/token',
  );
}
