part of 'open_api_v3_0_document_parser.dart';

extension _SecurityReader on OpenApiV30DocumentParser {
  OpenApiV30ApiKeySecurityScheme _apiKeySecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'name',
      'in',
      'description',
    });
    return OpenApiV30ApiKeySecurityScheme(
      name: reader.required('name', context.string),
      location: reader.required('in', enumOf(OpenApiV30ApiKeyLocation.values)),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30HttpSecurityScheme _httpSecurityScheme(Object? value, String path) {
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
    return OpenApiV30HttpSecurityScheme(
      scheme: reader.required('scheme', context.string),
      bearerFormat: reader.optional('bearerFormat', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30OAuth2SecurityScheme _oauth2SecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'flows',
      'description',
    });
    return OpenApiV30OAuth2SecurityScheme(
      flows: reader.required('flows', _oauthFlows),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30OpenIdConnectSecurityScheme _openIdConnectSecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'type',
      'openIdConnectUrl',
      'description',
    });
    return OpenApiV30OpenIdConnectSecurityScheme(
      openIdConnectUrl: reader.required('openIdConnectUrl', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30OAuthFlows _oauthFlows(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'implicit',
      'password',
      'clientCredentials',
      'authorizationCode',
    });
    return OpenApiV30OAuthFlows(
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

  OpenApiV30OAuthFlow _oauthFlow(
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
    return OpenApiV30OAuthFlow(
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

  OpenApiV30SecurityScheme _securityScheme(Object? value, String path) {
    final Map<String, Object?> fields = objectFields(value, path);
    final reader = ObjectReader(context, fields, path, fields.keys.toSet());
    return switch (reader.required(
      'type',
      enumOf(OpenApiV30SecuritySchemeType.values),
    )) {
      OpenApiV30SecuritySchemeType.apiKey => _apiKeySecurityScheme(
        fields,
        path,
      ),
      OpenApiV30SecuritySchemeType.http => _httpSecurityScheme(fields, path),
      OpenApiV30SecuritySchemeType.oauth2 => _oauth2SecurityScheme(
        fields,
        path,
      ),
      OpenApiV30SecuritySchemeType.openIdConnect =>
        _openIdConnectSecurityScheme(fields, path),
    };
  }

  OpenApiV30SecurityRequirement _securityRequirement(
    Object? value,
    String path,
  ) => OpenApiV30SecurityRequirement(
    context.map(value, path, listOf(context.string)),
  );
}
