import 'package:swagger_parser_core/src/model/json_value.dart';

part 'open_api_v3_2_metadata.dart';
part 'open_api_v3_2_paths.dart';
part 'open_api_v3_2_payloads.dart';
part 'open_api_v3_2_schema.dart';
part 'open_api_v3_2_security.dart';

/// A document object that can export its fields as JSON.
abstract interface class OpenApiV32JsonSerializable() {
  /// Initializes a concrete subtype.
  this;

  /// Returns a detached JSON representation.
  Map<String, Object?> toJson();
}

/// Common fields for specification extensions and unrecognized properties.
mixin OpenApiV32Object implements OpenApiV32JsonSerializable {
  /// Specification extensions keyed by their `x-` names.
  Map<String, JsonValue> get extensions;

  /// Unrecognized fields retained for JSON export.
  Map<String, JsonValue> get extraFields;

  /// Exports extensions and unrecognized fields as JSON.
  Map<String, Object?> extraToJson() => {
    for (final entry in extraFields.entries) entry.key: entry.value.toJson(),
    for (final entry in extensions.entries) entry.key: entry.value.toJson(),
  };
}

abstract base class _FixedObject({
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with OpenApiV32Object {
  /// Specification extensions keyed by their `x-` names. Defaults to empty.
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);

  /// Unrecognized fields retained for JSON export. Defaults to empty.
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
}

/// An inline definition or a reference to another definition.
sealed class const OpenApiV32RefOr<T extends OpenApiV32JsonSerializable>()
    implements OpenApiV32JsonSerializable {
  /// Initializes a concrete subtype.
  this;
}

/// A definition stored at its point of use.
final class const OpenApiV32Inline<T extends OpenApiV32JsonSerializable>(
  /// The embedded definition.
  final T value,
) extends OpenApiV32RefOr<T> {
  /// Embeds [value] at its point of use.
  this;

  @override
  Map<String, Object?> toJson() => value.toJson();
}

/// A reference to a local or external definition.
final class OpenApiV32Reference<T extends OpenApiV32JsonSerializable>(
  /// The URI reference from `$ref`.
  final String ref, {

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,
  Map<String, JsonValue> ignoredFields = const {},
}) extends OpenApiV32RefOr<T> {
  /// Keeps the reference URI as written in the document.
  this;

  /// Additional fields retained for export.
  final Map<String, JsonValue> ignoredFields = Map.unmodifiable(ignoredFields);

  @override
  Map<String, Object?> toJson() => {
    for (final entry in ignoredFields.entries) entry.key: entry.value.toJson(),
    r'$ref': ref,
    'summary': ?summary,
    'description': ?description,
  };
}

abstract base class _Entries<T extends OpenApiV32JsonSerializable>({
  required Map<String, T> entries,
  super.extensions,
}) extends _FixedObject {
  /// Values indexed by their source keys.
  final Map<String, T> entries = Map.unmodifiable(entries);

  /// Returns the value at [key], or null if the key is absent.
  T? operator [](String key) => entries[key];

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    for (final entry in entries.entries) entry.key: entry.value.toJson(),
  };
}

/// Path items indexed by relative API path.
final class OpenApiV32Paths({required super.entries, super.extensions})
    extends _Entries<OpenApiV32PathItem> {
  /// Indexes path items by their relative paths.
  this;
}

/// Responses indexed by status code or `default`.
final class OpenApiV32Responses({required super.entries, super.extensions})
    extends _Entries<OpenApiV32RefOr<OpenApiV32Response>> {
  /// Indexes responses by status code, range where supported, or `default`.
  this;
}

/// Callback path items indexed by runtime expression.
final class OpenApiV32Callback({required super.entries, super.extensions})
    extends _Entries<OpenApiV32PathItem> {
  /// Indexes callback paths by runtime expression.
  this;
}

/// Security schemes that must be satisfied together.
final class OpenApiV32SecurityRequirement(Map<String, List<String>> schemes)
    implements OpenApiV32JsonSerializable {
  /// Copies each scheme and its required scopes.
  this;

  /// Required scopes indexed by security scheme name.
  final Map<String, List<String>> schemes = Map.unmodifiable(
    schemes.map((k, v) => MapEntry(k, List<String>.unmodifiable(v))),
  );

  @override
  Map<String, Object?> toJson() => {
    for (final entry in schemes.entries) entry.key: entry.value.toList(),
  };
}

/// Credentials an operation can require.
sealed class OpenApiV32SecurityScheme({
  /// Whether the author discourages new uses of this scheme.
  final bool? deprecated,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Initializes a concrete subtype.
  this;

  /// Discriminator for the authentication mechanism.
  OpenApiV32SecuritySchemeType get type;

  /// Description supplied by the document author.
  String? get description;

  Map<String, Object?> _securityFields() => {
    ...extraToJson(),
    'type': type.name,
    'description': ?description,
    'deprecated': ?deprecated,
  };
}

/// How a parameter is serialized in a request.
enum OpenApiV32Style() {
  /// Prefix a path parameter with a semicolon.
  matrix,

  /// Prefix a path parameter with a period.
  label,

  /// Use form-style query or cookie parameters.
  form,

  /// Use comma-separated path or header values.
  simple,

  /// Separate query values with spaces.
  spaceDelimited,

  /// Separate query values with vertical bars.
  pipeDelimited,

  /// Use bracketed property names in a query object.
  deepObject,

  /// Use semicolon-separated cookie pairs.
  cookie,
}

/// The part of the request that carries a parameter.
enum OpenApiV32ParameterLocation() {
  /// In the URL query string.
  query,

  /// The entire URL query string.
  querystring,

  /// In an HTTP request header.
  header,

  /// In a URL path template.
  path,

  /// In a request cookie.
  cookie,
}

/// The part of the request that carries an API key.
enum OpenApiV32ApiKeyLocation() {
  /// In the URL query string.
  query,

  /// In an HTTP request header.
  header,

  /// In a request cookie.
  cookie,
}

/// The authentication mechanism of a security scheme.
enum OpenApiV32SecuritySchemeType() {
  /// An API key in a named request field.
  apiKey,

  /// HTTP authentication, such as Basic or Bearer.
  http,

  /// Mutual TLS with a client certificate.
  mutualTLS,

  /// An OAuth 2.0 access token.
  oauth2,

  /// Authentication through OpenID Connect discovery.
  openIdConnect,
}
