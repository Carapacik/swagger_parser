import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_serialization.dart';

part 'open_api_v3_0_metadata.dart';
part 'open_api_v3_0_paths.dart';
part 'open_api_v3_0_payloads.dart';
part 'open_api_v3_0_schema.dart';
part 'open_api_v3_0_security.dart';

/// A document object that can export its fields as JSON.
abstract interface class OpenApiV30JsonSerializable() {
  /// Initializes a concrete subtype.
  this;

  /// Returns a detached JSON representation.
  Map<String, Object?> toJson();
}

/// Common fields for specification extensions and unrecognized properties.
mixin OpenApiV30Object implements OpenApiV30JsonSerializable {
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
}) with OpenApiV30Object {
  /// Specification extensions keyed by their `x-` names. Defaults to empty.
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);

  /// Unrecognized fields retained for JSON export. Defaults to empty.
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
}

/// An inline definition or a reference to another definition.
sealed class const OpenApiV30RefOr<T extends OpenApiV30JsonSerializable>()
    implements OpenApiV30JsonSerializable {
  /// Initializes a concrete subtype.
  this;
}

/// A definition stored at its point of use.
final class const OpenApiV30Inline<T extends OpenApiV30JsonSerializable>(
  /// The embedded definition.
  final T value,
) extends OpenApiV30RefOr<T> {
  /// Embeds [value] at its point of use.
  this;

  @override
  Map<String, Object?> toJson() => value.toJson();
}

/// A reference to a local or external definition.
final class OpenApiV30Reference<T extends OpenApiV30JsonSerializable>(
  /// The URI reference from `$ref`.
  final String ref, {
  Map<String, JsonValue> ignoredFields = const {},
}) extends OpenApiV30RefOr<T> {
  /// Keeps the reference URI as written in the document.
  this;

  /// Retained for export. Only `$ref` affects reference semantics.
  final Map<String, JsonValue> ignoredFields = Map.unmodifiable(ignoredFields);

  @override
  Map<String, Object?> toJson() => {
    for (final entry in ignoredFields.entries) entry.key: entry.value.toJson(),
    r'$ref': ref,
  };
}

abstract base class _Entries<T extends OpenApiV30JsonSerializable>({
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
final class OpenApiV30Paths({required super.entries, super.extensions})
    extends _Entries<OpenApiV30PathItem> {
  /// Indexes path items by their relative paths.
  this;
}

/// Responses indexed by status code or `default`.
final class OpenApiV30Responses({required super.entries, super.extensions})
    extends _Entries<OpenApiV30RefOr<OpenApiV30Response>> {
  /// Indexes responses by status code, range where supported, or `default`.
  this;
}

/// Callback path items indexed by runtime expression.
final class OpenApiV30Callback({required super.entries, super.extensions})
    extends _Entries<OpenApiV30PathItem> {
  /// Indexes callback paths by runtime expression.
  this;
}

/// Security schemes that must be satisfied together.
final class OpenApiV30SecurityRequirement(Map<String, List<String>> schemes)
    implements OpenApiV30JsonSerializable {
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

/// A boolean or schema for extra object properties.
sealed class const OpenApiV30AdditionalProperties() {
  /// Initializes a concrete subtype.
  this;

  /// Returns the boolean rule or the property schema as JSON.
  Object toJson();
}

/// A boolean rule for extra object properties.
final class const OpenApiV30AdditionalPropertiesAllowed({
  /// Whether the object accepts extra properties.
  required final bool allowed,
}) extends OpenApiV30AdditionalProperties {
  /// Sets whether the schema accepts extra property names.
  this;

  @override
  bool toJson() => allowed;
}

/// A schema that constrains extra object properties.
final class const OpenApiV30AdditionalPropertiesSchema(
  /// Schema that describes the value.
  final OpenApiV30RefOr<OpenApiV30Schema> schema,
) extends OpenApiV30AdditionalProperties {
  /// Applies [schema] to each extra property value.
  this;

  @override
  Map<String, Object?> toJson() => schema.toJson();
}

/// Credentials an operation can require.
sealed class OpenApiV30SecurityScheme({super.extensions, super.extraFields})
    extends _FixedObject {
  /// Initializes a concrete subtype.
  this;

  /// Discriminator for the authentication mechanism.
  OpenApiV30SecuritySchemeType get type;

  /// Description supplied by the document author.
  String? get description;
}

/// A type name accepted by OpenAPI 3.0.
enum OpenApiV30Type() {
  /// A sequence of characters.
  string,

  /// A numeric value, including an integer.
  number,

  /// A number with no fractional part.
  integer,

  /// A true or false value.
  boolean,

  /// An ordered sequence of values.
  array,

  /// A map of named properties.
  object,
}

/// The serialization style of a parameter.
typedef OpenApiV30Style = OpenApiParameterStyle;

/// The part of the request that carries a parameter.
typedef OpenApiV30ParameterLocation = OpenApiParameterLocation;

/// The part of the request that carries an API key.
enum OpenApiV30ApiKeyLocation() {
  /// In the URL query string.
  query,

  /// In an HTTP request header.
  header,

  /// In a request cookie.
  cookie,
}

/// The authentication mechanism of a security scheme.
enum OpenApiV30SecuritySchemeType() {
  /// An API key in a named request field.
  apiKey,

  /// HTTP authentication, such as Basic or Bearer.
  http,

  /// An OAuth 2.0 access token.
  oauth2,

  /// Authentication through OpenID Connect discovery.
  openIdConnect,
}
