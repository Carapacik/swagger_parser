part of 'open_api_v3_2_document_parser.dart';

extension _SecurityReader on OpenApiV32DocumentParser {
  OpenApiV32ApiKeySecurityScheme _apiKeySecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'deprecated',
      'type',
      'name',
      'in',
      'description',
    });
    return OpenApiV32ApiKeySecurityScheme(
      deprecated: reader.optional('deprecated', context.boolean),
      name: reader.required('name', context.string),
      location: reader.required('in', enumOf(OpenApiV32ApiKeyLocation.values)),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32HttpSecurityScheme _httpSecurityScheme(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'deprecated',
      'type',
      'scheme',
      'bearerFormat',
      'description',
    });
    if (reader.fields.containsKey('bearerFormat') &&
        reader.required('scheme', context.string).toLowerCase() != 'bearer') {
      failField(reader, 'bearerFormat', 'Expected a bearer scheme.');
    }
    return OpenApiV32HttpSecurityScheme(
      deprecated: reader.optional('deprecated', context.boolean),
      scheme: reader.required('scheme', context.string),
      bearerFormat: reader.optional('bearerFormat', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32OAuth2SecurityScheme _oauth2SecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'deprecated',
      'oauth2MetadataUrl',
      'type',
      'flows',
      'description',
    });
    return OpenApiV32OAuth2SecurityScheme(
      deprecated: reader.optional('deprecated', context.boolean),
      oauth2MetadataUrl: reader.optional('oauth2MetadataUrl', context.string),
      flows: reader.required('flows', _oauthFlows),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32OpenIdConnectSecurityScheme _openIdConnectSecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'deprecated',
      'type',
      'openIdConnectUrl',
      'description',
    });
    return OpenApiV32OpenIdConnectSecurityScheme(
      deprecated: reader.optional('deprecated', context.boolean),
      openIdConnectUrl: reader.required('openIdConnectUrl', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32OAuthFlows _oauthFlows(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'implicit',
      'password',
      'clientCredentials',
      'authorizationCode',
      'deviceAuthorization',
    });
    OpenApiV32OAuthFlow? grant(String name) =>
        reader.optional(name, (value, path) => _oauthFlow(value, path, name));
    return OpenApiV32OAuthFlows(
      implicit: grant('implicit'),
      password: grant('password'),
      clientCredentials: grant('clientCredentials'),
      authorizationCode: grant('authorizationCode'),
      deviceAuthorization: grant('deviceAuthorization'),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32OAuthFlow _oauthFlow(Object? value, String path, String grant) {
    final reader = ObjectReader(context, value, path, const {
      'scopes',
      'authorizationUrl',
      'deviceAuthorizationUrl',
      'tokenUrl',
      'refreshUrl',
    });
    return OpenApiV32OAuthFlow(
      deviceAuthorizationUrl: grant == 'deviceAuthorization'
          ? reader.required('deviceAuthorizationUrl', context.string)
          : reader.optional('deviceAuthorizationUrl', context.string),
      scopes: reader.required('scopes', mapOf(context.string)),
      authorizationUrl: grant == 'authorizationCode' || grant == 'implicit'
          ? reader.required('authorizationUrl', context.string)
          : reader.optional('authorizationUrl', context.string),
      tokenUrl: grant != 'implicit'
          ? reader.required('tokenUrl', context.string)
          : reader.optional('tokenUrl', context.string),
      refreshUrl: reader.optional('refreshUrl', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32SecurityScheme _securityScheme(Object? value, String path) {
    final Map<String, Object?> fields = objectFields(value, path);
    final reader = ObjectReader(context, fields, path, fields.keys.toSet());
    return switch (reader.required(
      'type',
      enumOf(OpenApiV32SecuritySchemeType.values),
    )) {
      OpenApiV32SecuritySchemeType.mutualTLS => _mutualTls(fields, path),
      OpenApiV32SecuritySchemeType.apiKey => _apiKeySecurityScheme(
        fields,
        path,
      ),
      OpenApiV32SecuritySchemeType.http => _httpSecurityScheme(fields, path),
      OpenApiV32SecuritySchemeType.oauth2 => _oauth2SecurityScheme(
        fields,
        path,
      ),
      OpenApiV32SecuritySchemeType.openIdConnect =>
        _openIdConnectSecurityScheme(fields, path),
    };
  }

  OpenApiV32MutualTlsSecurityScheme _mutualTls(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'deprecated',
      'type',
      'description',
    });
    return OpenApiV32MutualTlsSecurityScheme(
      deprecated: reader.optional('deprecated', context.boolean),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32SecurityRequirement _securityRequirement(
    Object? value,
    String path,
  ) => OpenApiV32SecurityRequirement(
    context.map(value, path, listOf(context.string)),
  );
}
