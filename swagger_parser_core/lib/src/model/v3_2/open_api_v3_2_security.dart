part of 'open_api_v3_2_objects.dart';

/// An API key passed in a named request field.
final class OpenApiV32ApiKeySecurityScheme({
  /// Name of the request field that carries the API key.
  required final String name,

  /// Where the request carries this value.
  required final OpenApiV32ApiKeyLocation location,
  @override final String? description,
  super.deprecated,
  super.extensions,
  super.extraFields,
}) extends OpenApiV32SecurityScheme {
  /// Identifies the request field that carries the key.
  this;

  @override
  OpenApiV32SecuritySchemeType get type => OpenApiV32SecuritySchemeType.apiKey;
  @override
  Map<String, Object?> toJson() => {
    ..._securityFields(),
    'name': name,
    'in': location.name,
  };
}

/// An HTTP authentication scheme for the Authorization header.
final class OpenApiV32HttpSecurityScheme({
  /// HTTP authentication scheme name.
  required final String scheme,

  /// Format hint for bearer tokens.
  final String? bearerFormat,
  @override final String? description,
  super.deprecated,
  super.extensions,
  super.extraFields,
}) extends OpenApiV32SecurityScheme {
  /// Uses the HTTP authentication scheme named by [scheme].
  this;

  @override
  OpenApiV32SecuritySchemeType get type => OpenApiV32SecuritySchemeType.http;
  @override
  Map<String, Object?> toJson() => {
    ..._securityFields(),
    'scheme': scheme,
    'bearerFormat': ?bearerFormat,
  };
}

/// OAuth 2.0 authorization settings.
final class OpenApiV32OAuth2SecurityScheme({
  /// OAuth flows supported by this scheme.
  required final OpenApiV32OAuthFlows flows,

  /// URL of the OAuth authorization server metadata.
  final String? oauth2MetadataUrl,
  @override final String? description,
  super.deprecated,
  super.extensions,
  super.extraFields,
}) extends OpenApiV32SecurityScheme {
  /// Declares the OAuth grants available to clients.
  this;

  @override
  OpenApiV32SecuritySchemeType get type => OpenApiV32SecuritySchemeType.oauth2;
  @override
  Map<String, Object?> toJson() => {
    ..._securityFields(),
    'oauth2MetadataUrl': ?oauth2MetadataUrl,
    'flows': flows.toJson(),
  };
}

/// OpenID Connect discovery settings.
final class OpenApiV32OpenIdConnectSecurityScheme({
  /// URL of the OpenID Connect discovery document.
  required final String openIdConnectUrl,
  @override final String? description,
  super.deprecated,
  super.extensions,
  super.extraFields,
}) extends OpenApiV32SecurityScheme {
  /// Uses [openIdConnectUrl] to locate the discovery document.
  this;

  @override
  OpenApiV32SecuritySchemeType get type =>
      OpenApiV32SecuritySchemeType.openIdConnect;
  @override
  Map<String, Object?> toJson() => {
    ..._securityFields(),
    'openIdConnectUrl': openIdConnectUrl,
  };
}

/// OAuth grant types supported by the authorization server.
final class OpenApiV32OAuthFlows({
  /// Configuration for the device authorization grant.
  final OpenApiV32OAuthFlow? deviceAuthorization,

  /// Configuration for the implicit grant.
  final OpenApiV32OAuthFlow? implicit,

  /// Configuration for the resource owner password grant.
  final OpenApiV32OAuthFlow? password,

  /// Configuration for the client credentials grant.
  final OpenApiV32OAuthFlow? clientCredentials,

  /// Configuration for the authorization code grant.
  final OpenApiV32OAuthFlow? authorizationCode,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups endpoint settings by grant type.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    if (deviceAuthorization != null)
      'deviceAuthorization': deviceAuthorization!.toJson(),
    if (implicit != null) 'implicit': implicit!.toJson(),
    if (password != null) 'password': password!.toJson(),
    if (clientCredentials != null)
      'clientCredentials': clientCredentials!.toJson(),
    if (authorizationCode != null)
      'authorizationCode': authorizationCode!.toJson(),
  };
}

/// Authorization endpoints and scopes for an OAuth flow.
final class OpenApiV32OAuthFlow({
  required Map<String, String> scopes,

  /// Endpoint that starts device authorization.
  final String? deviceAuthorizationUrl,

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
    'deviceAuthorizationUrl': ?deviceAuthorizationUrl,
    'scopes': Map<String, String>.of(scopes),
    'authorizationUrl': ?authorizationUrl,
    'tokenUrl': ?tokenUrl,
    'refreshUrl': ?refreshUrl,
  };
}

/// Client authentication with a TLS certificate.
final class OpenApiV32MutualTlsSecurityScheme({
  @override final String? description,
  super.deprecated,
  super.extensions,
  super.extraFields,
}) extends OpenApiV32SecurityScheme {
  /// Declares mutual TLS client authentication.
  this;
  @override
  OpenApiV32SecuritySchemeType get type =>
      OpenApiV32SecuritySchemeType.mutualTLS;
  @override
  Map<String, Object?> toJson() => _securityFields();
}
