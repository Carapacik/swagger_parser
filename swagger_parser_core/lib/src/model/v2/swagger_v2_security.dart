part of 'swagger_v2_objects.dart';

/// Credentials an operation can require.
sealed class SwaggerV2SecurityScheme() with SwaggerV2Object {
  /// Initializes a concrete subtype.
  this;

  /// Description supplied by the document author.
  String? get description;
}

/// Security schemes that must be satisfied together.
final class SwaggerV2SecurityRequirement(Map<String, List<String>> schemes)
    implements SwaggerV2JsonSerializable {
  /// Copies each scheme and its required scopes.
  this;

  /// Required scopes indexed by security scheme name.
  final Map<String, List<String>> schemes = Map.unmodifiable(
    schemes.map(
      (key, value) => MapEntry(key, List<String>.unmodifiable(value)),
    ),
  );
  @override
  Map<String, Object?> toJson() =>
      schemes.map((key, value) => MapEntry(key, value.toList()));
}

/// HTTP Basic authentication.
final class SwaggerV2BasicSecurityScheme({
  @override final String? description,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends SwaggerV2SecurityScheme {
  /// Declares HTTP Basic credentials.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': 'basic',
    'description': ?description,
  };
}

/// An API key passed in a named request field.
final class SwaggerV2ApiKeySecurityScheme({
  /// Name of the request field that carries the API key.
  required final String name,

  /// Where the request carries this value.
  required final SwaggerV2ApiKeyLocation location,
  @override final String? description,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends SwaggerV2SecurityScheme {
  /// Identifies the request field that carries the key.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': 'apiKey',
    'name': name,
    'in': location.name,
    'description': ?description,
  };
}

/// OAuth 2.0 authorization settings.
final class SwaggerV2OAuth2SecurityScheme({
  /// The OAuth grant used by this scheme.
  required final SwaggerV2OAuthFlow flow,
  required Map<String, String> scopes,

  /// Authorization endpoint URL.
  final String? authorizationUrl,

  /// Token endpoint URL.
  final String? tokenUrl,
  @override final String? description,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends SwaggerV2SecurityScheme {
  /// Declares the OAuth grants available to clients.
  this;

  /// Scope descriptions indexed by scope name.
  final Map<String, String> scopes = Map.unmodifiable(scopes);

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': 'oauth2',
    'flow': flow.name,
    'scopes': scopes.map(MapEntry.new),
    'authorizationUrl': ?authorizationUrl,
    'tokenUrl': ?tokenUrl,
    'description': ?description,
  };
}
