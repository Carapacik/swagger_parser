part of 'swagger_v2_objects.dart';

/// The value and serialization rules for an HTTP header.
final class SwaggerV2Header({
  /// Type of the header value.
  required final SwaggerV2Type type,

  /// Description supplied by the document author.
  final String? description,

  /// Format identifier that refines the declared type.
  final String? format,

  /// Rules for the elements of an array.
  final SwaggerV2Items? items,

  /// How to serialize an array of values.
  final SwaggerV2CollectionFormat? collectionFormat,

  /// Upper numeric bound.
  final num? maximum,

  /// Whether values must be less than the upper bound.
  final bool? exclusiveMaximum,

  /// Lower numeric bound.
  final num? minimum,

  /// Whether values must exceed the lower bound.
  final bool? exclusiveMinimum,

  /// Maximum string length in Unicode code points.
  final int? maxLength,

  /// Minimum string length in Unicode code points.
  final int? minLength,

  /// Regular expression that a string must match.
  final String? pattern,

  /// Maximum number of array elements.
  final int? maxItems,

  /// Minimum number of array elements.
  final int? minItems,

  /// Whether all array elements must be distinct.
  final bool? uniqueItems,
  List<JsonValue>? enumValues,

  /// Valid numbers must be multiples of this positive value.
  final num? multipleOf,

  /// The default value declared by the author.
  final JsonValue? defaultValue,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Sets the value constraints and wire format for a header.
  this;

  /// Allowed values from `enum`, in source order.
  final List<JsonValue>? enumValues = enumValues == null
      ? null
      : List.unmodifiable(enumValues);

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'type': type.wireName,
    'description': ?description,
    'format': ?format,
    if (items != null) 'items': items!.toJson(),
    if (collectionFormat != null) 'collectionFormat': collectionFormat!.name,
    'maximum': ?maximum,
    'exclusiveMaximum': ?exclusiveMaximum,
    'minimum': ?minimum,
    'exclusiveMinimum': ?exclusiveMinimum,
    'maxLength': ?maxLength,
    'minLength': ?minLength,
    'pattern': ?pattern,
    'maxItems': ?maxItems,
    'minItems': ?minItems,
    'uniqueItems': ?uniqueItems,
    if (enumValues != null)
      'enum': enumValues!.map((value) => value.toJson()).toList(),
    'multipleOf': ?multipleOf,
    if (defaultValue != null) 'default': defaultValue!.toJson(),
  };
}

/// A documented response and its payload metadata.
final class SwaggerV2Response({
  /// Description supplied by the document author.
  required final String description,

  /// Schema that describes the value.
  final SwaggerV2Schema? schema,
  Map<String, SwaggerV2Header>? headers,
  Map<String, JsonValue>? examples,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Groups the response description with its payload metadata.
  this;

  /// Header definitions indexed by header name.
  final Map<String, SwaggerV2Header>? headers = headers == null
      ? null
      : Map.unmodifiable(headers);

  /// Example response bodies indexed by media type.
  final Map<String, JsonValue>? examples = examples == null
      ? null
      : Map.unmodifiable(examples);
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'description': description,
    if (schema != null) 'schema': schema!.toJson(),
    if (headers != null)
      'headers': headers!.map((key, value) => MapEntry(key, value.toJson())),
    if (examples != null)
      'examples': examples!.map((key, value) => MapEntry(key, value.toJson())),
  };
}

/// Responses indexed by status code or `default`.
final class SwaggerV2Responses({
  required Map<String, SwaggerV2RefOr<SwaggerV2Response>> entries,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Copies response definitions and preserves their keys.
  this;

  /// Responses indexed by status code or `default`.
  final Map<String, SwaggerV2RefOr<SwaggerV2Response>> entries =
      Map.unmodifiable(entries);

  /// Returns the entry for the given key, or null if absent.
  SwaggerV2RefOr<SwaggerV2Response>? operator [](String key) => entries[key];
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    ...entries.map((key, value) => MapEntry(key, value.toJson())),
  };
}
