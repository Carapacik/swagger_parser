import 'package:swagger_parser_core/src/model/json_value.dart';

part 'swagger_v2_metadata.dart';
part 'swagger_v2_schema.dart';
part 'swagger_v2_parameters.dart';
part 'swagger_v2_responses.dart';
part 'swagger_v2_paths.dart';
part 'swagger_v2_security.dart';

/// A document object that can export its fields as JSON.
abstract interface class SwaggerV2JsonSerializable() {
  /// Initializes a concrete subtype.
  this;

  /// Returns a detached JSON representation.
  Map<String, Object?> toJson();
}

/// Preserves extensions and unknown fields without interpreting them.
mixin SwaggerV2Object implements SwaggerV2JsonSerializable {
  /// Specification extensions keyed by their `x-` names.
  Map<String, JsonValue> get extensions;

  /// Unrecognized fields retained for JSON export.
  Map<String, JsonValue> get extraFields;

  /// Exports extensions and unrecognized fields as JSON.
  Map<String, Object?> extraToJson() => {
    ...extraFields.map((key, value) => MapEntry(key, value.toJson())),
    ...extensions.map((key, value) => MapEntry(key, value.toJson())),
  };
}

/// An inline definition or a reference to another definition.
sealed class const SwaggerV2RefOr<T extends SwaggerV2JsonSerializable>()
    implements SwaggerV2JsonSerializable {
  /// Initializes a concrete subtype.
  this;
}

/// A definition stored at its point of use.
final class const SwaggerV2Inline<T extends SwaggerV2JsonSerializable>(
  /// The embedded definition.
  final T value,
) extends SwaggerV2RefOr<T> {
  /// Embeds [value] at its point of use.
  this;

  @override
  Map<String, Object?> toJson() => value.toJson();
}

/// A reference to a local or external definition.
final class SwaggerV2Reference<T extends SwaggerV2JsonSerializable>(
  /// The URI reference from `$ref`.
  final String ref, {
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends SwaggerV2RefOr<T> with SwaggerV2Object {
  /// Keeps the reference URI as written in the document.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  Map<String, Object?> toJson() => {...extraToJson(), r'$ref': ref};
}

/// A type name accepted by Swagger 2.0.
enum SwaggerV2Type() {
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

  /// A file upload.
  file,

  /// The JSON `null` type.
  nullValue,
}

/// The part of the request that carries a parameter.
enum SwaggerV2ParameterLocation() {
  /// In the URL query string.
  query,

  /// In an HTTP request header.
  header,

  /// In a URL path template.
  path,

  /// In a form field in the request body.
  formData,

  /// In the request body as a single payload.
  body,
}

/// The part of the request that carries an API key.
enum SwaggerV2ApiKeyLocation() {
  /// In the URL query string.
  query,

  /// In an HTTP request header.
  header,
}

/// The wire format of an array parameter.
enum SwaggerV2CollectionFormat() {
  /// Separate array values with commas.
  csv,

  /// Separate array values with spaces.
  ssv,

  /// Separate array values with tabs.
  tsv,

  /// Separate array values with vertical bars.
  pipes,

  /// Repeat the parameter name for each array value.
  multi,
}

/// The OAuth grant declared by a Swagger 2.0 security scheme.
enum SwaggerV2OAuthFlow() {
  /// The OAuth 2.0 implicit grant.
  implicit,

  /// The resource owner password credentials grant.
  password,

  /// The client credentials grant.
  application,

  /// The authorization code grant.
  accessCode,
}

/// The spelling of a Swagger type in the source document.
extension SwaggerV2TypeName on SwaggerV2Type {
  /// The type name used in the document.
  String get wireName => this == SwaggerV2Type.nullValue ? 'null' : name;
}
