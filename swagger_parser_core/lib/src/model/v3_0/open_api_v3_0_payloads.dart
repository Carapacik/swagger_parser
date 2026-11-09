part of 'open_api_v3_0_objects.dart';

/// A named input to an operation.
final class OpenApiV30Parameter({
  /// Parameter name in its declared request location.
  required final String name,

  /// Where the request carries this value.
  required final OpenApiV30ParameterLocation location,

  /// Description supplied by the document author.
  final String? description,

  /// Whether the caller must supply this input.
  final bool? isRequired,

  /// Whether the author discourages new uses.
  final bool? deprecated,

  /// Whether a query parameter can have an empty value.
  final bool? allowEmptyValue,

  /// Serialization style for the parameter or property.
  final OpenApiV30Style? style,

  /// Whether to serialize array items or object properties separately.
  final bool? explode,

  /// Whether reserved URI characters can appear unescaped.
  final bool? allowReserved,

  /// Schema that describes the value.
  final OpenApiV30RefOr<OpenApiV30Schema>? schema,

  /// An inline example value.
  final JsonValue? example,
  Map<String, OpenApiV30RefOr<OpenApiV30Example>>? examples,
  Map<String, OpenApiV30MediaType>? content,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Describes an input by name and request location.
  this;

  /// Named examples for this representation.
  final Map<String, OpenApiV30RefOr<OpenApiV30Example>>? examples =
      examples == null ? null : Map.unmodifiable(examples);

  /// Representations indexed by media type.
  final Map<String, OpenApiV30MediaType>? content = content == null
      ? null
      : Map.unmodifiable(content);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': name,
    'in': location.name,
    'description': ?description,
    'required': ?isRequired,
    'deprecated': ?deprecated,
    'allowEmptyValue': ?allowEmptyValue,
    'style': ?style?.name,
    'explode': ?explode,
    'allowReserved': ?allowReserved,
    if (schema != null) 'schema': schema!.toJson(),
    if (example != null) 'example': example!.toJson(),
    if (examples != null)
      'examples': examples!.map((key, value) => MapEntry(key, value.toJson())),
    if (content != null)
      'content': content!.map((key, value) => MapEntry(key, value.toJson())),
  };
}

/// The value and serialization rules for an HTTP header.
final class OpenApiV30Header({
  /// Description supplied by the document author.
  final String? description,

  /// Whether the caller must supply this input.
  final bool? isRequired,

  /// Whether the author discourages new uses.
  final bool? deprecated,

  /// Serialization style for the parameter or property.
  final OpenApiV30Style? style,

  /// Whether to serialize array items or object properties separately.
  final bool? explode,

  /// Schema that describes the value.
  final OpenApiV30RefOr<OpenApiV30Schema>? schema,

  /// An inline example value.
  final JsonValue? example,
  Map<String, OpenApiV30RefOr<OpenApiV30Example>>? examples,
  Map<String, OpenApiV30MediaType>? content,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Sets the value constraints and wire format for a header.
  this;

  /// Named examples for this representation.
  final Map<String, OpenApiV30RefOr<OpenApiV30Example>>? examples =
      examples == null ? null : Map.unmodifiable(examples);

  /// Representations indexed by media type.
  final Map<String, OpenApiV30MediaType>? content = content == null
      ? null
      : Map.unmodifiable(content);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'description': ?description,
    'required': ?isRequired,
    'deprecated': ?deprecated,
    'style': ?style?.name,
    'explode': ?explode,
    if (schema != null) 'schema': schema!.toJson(),
    if (example != null) 'example': example!.toJson(),
    if (examples != null)
      'examples': examples!.map((key, value) => MapEntry(key, value.toJson())),
    if (content != null)
      'content': content!.map((key, value) => MapEntry(key, value.toJson())),
  };
}

/// Request payloads indexed by media type.
final class OpenApiV30RequestBody({
  required Map<String, OpenApiV30MediaType> content,

  /// Description supplied by the document author.
  final String? description,

  /// Whether the caller must supply this input.
  final bool? isRequired,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Indexes the accepted representations by media type.
  this;

  /// Representations indexed by media type.
  final Map<String, OpenApiV30MediaType> content = Map.unmodifiable(content);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'content': content.map((key, value) => MapEntry(key, value.toJson())),
    'description': ?description,
    'required': ?isRequired,
  };
}

/// Schema, examples, and encoding for one media type.
final class OpenApiV30MediaType({
  /// Schema that describes the value.
  final OpenApiV30RefOr<OpenApiV30Schema>? schema,

  /// An inline example value.
  final JsonValue? example,
  Map<String, OpenApiV30RefOr<OpenApiV30Example>>? examples,
  Map<String, OpenApiV30Encoding>? encoding,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups the schema and examples for one representation.
  this;

  /// Named examples for this representation.
  final Map<String, OpenApiV30RefOr<OpenApiV30Example>>? examples =
      examples == null ? null : Map.unmodifiable(examples);

  /// Encoding rules indexed by request body property name.
  final Map<String, OpenApiV30Encoding>? encoding = encoding == null
      ? null
      : Map.unmodifiable(encoding);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    if (schema != null) 'schema': schema!.toJson(),
    if (example != null) 'example': example!.toJson(),
    if (examples != null)
      'examples': examples!.map((key, value) => MapEntry(key, value.toJson())),
    if (encoding != null)
      'encoding': encoding!.map((key, value) => MapEntry(key, value.toJson())),
  };
}

/// Serialization rules for one request body property.
final class OpenApiV30Encoding({
  /// Media type used to encode this property.
  final String? contentType,
  Map<String, OpenApiV30RefOr<OpenApiV30Header>>? headers,

  /// Serialization style for the parameter or property.
  final OpenApiV30Style? style,

  /// Whether to serialize array items or object properties separately.
  final bool? explode,

  /// Whether reserved URI characters can appear unescaped.
  final bool? allowReserved,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Sets the wire format of one request body property.
  this;

  /// Header definitions indexed by header name.
  final Map<String, OpenApiV30RefOr<OpenApiV30Header>>? headers =
      headers == null ? null : Map.unmodifiable(headers);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'contentType': ?contentType,
    if (headers != null)
      'headers': headers!.map((key, value) => MapEntry(key, value.toJson())),
    'style': ?style?.name,
    'explode': ?explode,
    'allowReserved': ?allowReserved,
  };
}

/// A documented response and its payload metadata.
final class OpenApiV30Response({
  /// Description supplied by the document author.
  required final String description,
  Map<String, OpenApiV30RefOr<OpenApiV30Header>>? headers,
  Map<String, OpenApiV30MediaType>? content,
  Map<String, OpenApiV30RefOr<OpenApiV30Link>>? links,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups the response description with its payload metadata.
  this;

  /// Header definitions indexed by header name.
  final Map<String, OpenApiV30RefOr<OpenApiV30Header>>? headers =
      headers == null ? null : Map.unmodifiable(headers);

  /// Representations indexed by media type.
  final Map<String, OpenApiV30MediaType>? content = content == null
      ? null
      : Map.unmodifiable(content);

  /// Links to related operations, indexed by name.
  final Map<String, OpenApiV30RefOr<OpenApiV30Link>>? links = links == null
      ? null
      : Map.unmodifiable(links);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'description': description,
    if (headers != null)
      'headers': headers!.map((key, value) => MapEntry(key, value.toJson())),
    if (content != null)
      'content': content!.map((key, value) => MapEntry(key, value.toJson())),
    if (links != null)
      'links': links!.map((key, value) => MapEntry(key, value.toJson())),
  };
}

/// An inline example or a link to an external example.
final class OpenApiV30Example({
  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// The inline example, including explicit JSON null.
  final JsonValue? value,

  /// URL of an external example.
  final String? externalValue,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Records an inline value or an external example URL.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'summary': ?summary,
    'description': ?description,
    if (value != null) 'value': value!.toJson(),
    'externalValue': ?externalValue,
  };
}

/// Inputs for another operation derived from this response.
final class OpenApiV30Link({
  /// URI reference to the target operation.
  final String? operationRef,

  /// Identifier used to refer to an operation.
  final String? operationId,
  Map<String, JsonValue>? parameters,

  /// Value or runtime expression for the target request body.
  final JsonValue? requestBody,

  /// Description supplied by the document author.
  final String? description,

  /// Server used for the linked operation.
  final OpenApiV30Server? server,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Defines a target operation and the values to pass to it.
  this;

  /// Values or runtime expressions indexed by target parameter name.
  final Map<String, JsonValue>? parameters = parameters == null
      ? null
      : Map.unmodifiable(parameters);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'operationRef': ?operationRef,
    'operationId': ?operationId,
    if (parameters != null)
      'parameters': parameters!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (requestBody != null) 'requestBody': requestBody!.toJson(),
    'description': ?description,
    if (server != null) 'server': server!.toJson(),
  };
}
