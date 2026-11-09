part of 'open_api_v3_1_document_parser.dart';

extension _SecurityReader on OpenApiV31DocumentParser {
  OpenApiV31ApiKeySecurityScheme _apiKeySecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'name',
      'in',
      'description',
    });
    return OpenApiV31ApiKeySecurityScheme(
      name: reader.required('name', context.string),
      location: reader.required('in', enumOf(OpenApiV31ApiKeyLocation.values)),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31HttpSecurityScheme _httpSecurityScheme(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'scheme',
      'bearerFormat',
      'description',
    });
    if (reader.fields.containsKey('bearerFormat') &&
        reader.required('scheme', context.string).toLowerCase() != 'bearer') {
      failField(reader, 'bearerFormat', 'Expected a bearer scheme.');
    }
    return OpenApiV31HttpSecurityScheme(
      scheme: reader.required('scheme', context.string),
      bearerFormat: reader.optional('bearerFormat', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31OAuth2SecurityScheme _oauth2SecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'flows',
      'description',
    });
    return OpenApiV31OAuth2SecurityScheme(
      flows: reader.required('flows', _oauthFlows),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31OpenIdConnectSecurityScheme _openIdConnectSecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'openIdConnectUrl',
      'description',
    });
    return OpenApiV31OpenIdConnectSecurityScheme(
      openIdConnectUrl: reader.required('openIdConnectUrl', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31OAuthFlows _oauthFlows(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'implicit',
      'password',
      'clientCredentials',
      'authorizationCode',
    });
    return OpenApiV31OAuthFlows(
      implicit: reader.optional(
        'implicit',
        (value, path) =>
            _oauthFlow(value, path, authorization: true, token: false),
      ),
      password: reader.optional(
        'password',
        (value, path) =>
            _oauthFlow(value, path, authorization: false, token: true),
      ),
      clientCredentials: reader.optional(
        'clientCredentials',
        (value, path) =>
            _oauthFlow(value, path, authorization: false, token: true),
      ),
      authorizationCode: reader.optional(
        'authorizationCode',
        (value, path) =>
            _oauthFlow(value, path, authorization: true, token: true),
      ),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31OAuthFlow _oauthFlow(
    Object? value,
    String path, {
    required bool authorization,
    required bool token,
  }) {
    final reader = ObjectReader(context, value, path, const {
      'scopes',
      'authorizationUrl',
      'tokenUrl',
      'refreshUrl',
    });
    return OpenApiV31OAuthFlow(
      scopes: reader.required('scopes', mapOf(context.string)),
      authorizationUrl: authorization
          ? reader.required('authorizationUrl', context.string)
          : reader.optional('authorizationUrl', context.string),
      tokenUrl: token
          ? reader.required('tokenUrl', context.string)
          : reader.optional('tokenUrl', context.string),
      refreshUrl: reader.optional('refreshUrl', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31SecurityScheme _securityScheme(Object? value, String path) {
    final Map<String, Object?> fields = objectFields(value, path);
    final reader = ObjectReader(context, fields, path, fields.keys.toSet());
    return switch (reader.required(
      'type',
      enumOf(OpenApiV31SecuritySchemeType.values),
    )) {
      OpenApiV31SecuritySchemeType.mutualTLS => _mutualTls(fields, path),
      OpenApiV31SecuritySchemeType.apiKey => _apiKeySecurityScheme(
        fields,
        path,
      ),
      OpenApiV31SecuritySchemeType.http => _httpSecurityScheme(fields, path),
      OpenApiV31SecuritySchemeType.oauth2 => _oauth2SecurityScheme(
        fields,
        path,
      ),
      OpenApiV31SecuritySchemeType.openIdConnect =>
        _openIdConnectSecurityScheme(fields, path),
    };
  }

  OpenApiV31MutualTlsSecurityScheme _mutualTls(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'description',
    });
    return OpenApiV31MutualTlsSecurityScheme(
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31SecurityRequirement _securityRequirement(
    Object? value,
    String path,
  ) => OpenApiV31SecurityRequirement(
    context.map(value, path, listOf(context.string)),
  );
}
