part of 'swagger_v2_objects.dart';

/// A named input to an operation.
sealed class SwaggerV2Parameter() with SwaggerV2Object {
  /// Initializes a concrete subtype.
  this;

  /// Parameter name in its declared request location.
  String get name;

  /// Description supplied by the document author.
  String? get description;

  /// Whether the caller must supply this input.
  bool? get isRequired;

  /// Where the request carries this value.
  SwaggerV2ParameterLocation get location;
}

/// An operation parameter that describes the request body.
final class SwaggerV2BodyParameter({
  @override required final String name,

  /// Schema that describes the value.
  required final SwaggerV2Schema schema,
  @override final String? description,
  @override final bool? isRequired,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends SwaggerV2Parameter {
  /// Associates the request body with its schema.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  SwaggerV2ParameterLocation get location => SwaggerV2ParameterLocation.body;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'in': 'body',
    'name': name,
    'schema': schema.toJson(),
    'description': ?description,
    'required': ?isRequired,
  };
}

/// A primitive, array, or file parameter outside the request body.
final class SwaggerV2ValueParameter({
  @override required final String name,
  @override required final SwaggerV2ParameterLocation location,

  /// Type of the request parameter.
  required final SwaggerV2Type type,
  @override final String? description,
  @override final bool? isRequired,

  /// Format identifier that refines the declared type.
  final String? format,

  /// Whether a query parameter can have an empty value.
  final bool? allowEmptyValue,

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
}) extends SwaggerV2Parameter {
  /// Sets the location, type, and constraints of a request value.
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
    'name': name,
    'in': location.name,
    'type': type.wireName,
    'description': ?description,
    'required': ?isRequired,
    'format': ?format,
    'allowEmptyValue': ?allowEmptyValue,
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

/// The element type and constraints of an array parameter or header.
final class SwaggerV2Items({
  /// Type of each array element.
  required final SwaggerV2Type type,

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
  /// Describes the element type of an array parameter or header.
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
