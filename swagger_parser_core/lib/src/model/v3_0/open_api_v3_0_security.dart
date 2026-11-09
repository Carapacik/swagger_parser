part of 'open_api_v3_0_objects.dart';

/// An API key passed in a named request field.
final class OpenApiV30ApiKeySecurityScheme({
  /// Name of the request field that carries the API key.
  required final String name,

  /// Where the request carries this value.
  required final OpenApiV30ApiKeyLocation location,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV30SecurityScheme {
  /// Identifies the request field that carries the key.
  this;

  @override
  OpenApiV30SecuritySchemeType get type => OpenApiV30SecuritySchemeType.apiKey;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'name': name,
    'in': location.name,
    'description': ?description,
  };
}

/// An HTTP authentication scheme for the Authorization header.
final class OpenApiV30HttpSecurityScheme({
  /// HTTP authentication scheme name.
  required final String scheme,

  /// Format hint for bearer tokens.
  final String? bearerFormat,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV30SecurityScheme {
  /// Uses the HTTP authentication scheme named by [scheme].
  this;

  @override
  OpenApiV30SecuritySchemeType get type => OpenApiV30SecuritySchemeType.http;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'scheme': scheme,
    'bearerFormat': ?bearerFormat,
    'description': ?description,
  };
}

/// OAuth 2.0 authorization settings.
final class OpenApiV30OAuth2SecurityScheme({
  /// OAuth flows supported by this scheme.
  required final OpenApiV30OAuthFlows flows,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV30SecurityScheme {
  /// Declares the OAuth grants available to clients.
  this;

  @override
  OpenApiV30SecuritySchemeType get type => OpenApiV30SecuritySchemeType.oauth2;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'flows': flows.toJson(),
    'description': ?description,
  };
}

/// OpenID Connect discovery settings.
final class OpenApiV30OpenIdConnectSecurityScheme({
  /// URL of the OpenID Connect discovery document.
  required final String openIdConnectUrl,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV30SecurityScheme {
  /// Uses [openIdConnectUrl] to locate the discovery document.
  this;

  @override
  OpenApiV30SecuritySchemeType get type =>
      OpenApiV30SecuritySchemeType.openIdConnect;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'openIdConnectUrl': openIdConnectUrl,
    'description': ?description,
  };
}

/// OAuth grant types supported by the authorization server.
final class OpenApiV30OAuthFlows({
  /// Configuration for the implicit grant.
  final OpenApiV30OAuthFlow? implicit,

  /// Configuration for the resource owner password grant.
  final OpenApiV30OAuthFlow? password,

  /// Configuration for the client credentials grant.
  final OpenApiV30OAuthFlow? clientCredentials,

  /// Configuration for the authorization code grant.
  final OpenApiV30OAuthFlow? authorizationCode,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups endpoint settings by grant type.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    if (implicit != null) 'implicit': implicit!.toJson(),
    if (password != null) 'password': password!.toJson(),
    if (clientCredentials != null)
      'clientCredentials': clientCredentials!.toJson(),
    if (authorizationCode != null)
      'authorizationCode': authorizationCode!.toJson(),
  };
}

/// Authorization endpoints and scopes for an OAuth flow.
final class OpenApiV30OAuthFlow({
  required Map<String, String> scopes,

  /// Authorization endpoint URL.
  final String? authorizationUrl,

  /// Token endpoint URL.
  final String? tokenUrl,

  /// URL for refreshing an access token.
  final String? refreshUrl,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Associates grant endpoints with their available scopes.
  this;

  /// Scope descriptions indexed by scope name.
  final Map<String, String> scopes = Map.unmodifiable(scopes);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'scopes': Map<String, String>.of(scopes),
    'authorizationUrl': ?authorizationUrl,
    'tokenUrl': ?tokenUrl,
    'refreshUrl': ?refreshUrl,
  };
}
