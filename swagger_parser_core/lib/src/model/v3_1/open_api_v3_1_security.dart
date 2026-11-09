part of 'open_api_v3_1_objects.dart';

/// An API key passed in a named request field.
final class OpenApiV31ApiKeySecurityScheme({
  /// Name of the request field that carries the API key.
  required final String name,

  /// Where the request carries this value.
  required final OpenApiV31ApiKeyLocation location,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV31SecurityScheme {
  /// Identifies the request field that carries the key.
  this;

  @override
  OpenApiV31SecuritySchemeType get type => OpenApiV31SecuritySchemeType.apiKey;
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
final class OpenApiV31HttpSecurityScheme({
  /// HTTP authentication scheme name.
  required final String scheme,

  /// Format hint for bearer tokens.
  final String? bearerFormat,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV31SecurityScheme {
  /// Uses the HTTP authentication scheme named by [scheme].
  this;

  @override
  OpenApiV31SecuritySchemeType get type => OpenApiV31SecuritySchemeType.http;
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
final class OpenApiV31OAuth2SecurityScheme({
  /// OAuth flows supported by this scheme.
  required final OpenApiV31OAuthFlows flows,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV31SecurityScheme {
  /// Declares the OAuth grants available to clients.
  this;

  @override
  OpenApiV31SecuritySchemeType get type => OpenApiV31SecuritySchemeType.oauth2;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'flows': flows.toJson(),
    'description': ?description,
  };
}

/// OpenID Connect discovery settings.
final class OpenApiV31OpenIdConnectSecurityScheme({
  /// URL of the OpenID Connect discovery document.
  required final String openIdConnectUrl,
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV31SecurityScheme {
  /// Uses [openIdConnectUrl] to locate the discovery document.
  this;

  @override
  OpenApiV31SecuritySchemeType get type =>
      OpenApiV31SecuritySchemeType.openIdConnect;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'openIdConnectUrl': openIdConnectUrl,
    'description': ?description,
  };
}

/// OAuth grant types supported by the authorization server.
final class OpenApiV31OAuthFlows({
  /// Configuration for the implicit grant.
  final OpenApiV31OAuthFlow? implicit,

  /// Configuration for the resource owner password grant.
  final OpenApiV31OAuthFlow? password,

  /// Configuration for the client credentials grant.
  final OpenApiV31OAuthFlow? clientCredentials,

  /// Configuration for the authorization code grant.
  final OpenApiV31OAuthFlow? authorizationCode,
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
final class OpenApiV31OAuthFlow({
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

/// Client authentication with a TLS certificate.
final class OpenApiV31MutualTlsSecurityScheme({
  @override final String? description,
  super.extensions,
  super.extraFields,
}) extends OpenApiV31SecurityScheme {
  /// Declares mutual TLS client authentication.
  this;
  @override
  OpenApiV31SecuritySchemeType get type =>
      OpenApiV31SecuritySchemeType.mutualTLS;
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.name,
    'description': ?description,
  };
}
