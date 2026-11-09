part of 'swagger_v2_objects.dart';

/// A boolean or schema for extra object properties.
sealed class const SwaggerV2AdditionalProperties() {
  /// Initializes a concrete subtype.
  this;

  /// Returns the boolean rule or the property schema as JSON.
  Object toJson();
}

/// A boolean rule for extra object properties.
final class const SwaggerV2AdditionalPropertiesAllowed({
  /// Whether the object accepts extra properties.
  required final bool allowed,
}) extends SwaggerV2AdditionalProperties {
  /// Sets whether the schema accepts extra property names.
  this;

  @override
  bool toJson() => allowed;
}

/// A schema that constrains extra object properties.
final class const SwaggerV2AdditionalPropertiesSchema(
  /// Schema that describes the value.
  final SwaggerV2Schema schema,
) extends SwaggerV2AdditionalProperties {
  /// Applies [schema] to each extra property value.
  this;

  @override
  Map<String, Object?> toJson() => schema.toJson();
}

/// The single name or list used for the schema's `type`.
sealed class const SwaggerV2SchemaType() {
  /// Initializes a concrete subtype.
  this;

  /// Returns a type name or a list of type names.
  Object toJson();
}

/// A schema type written as one name.
final class const SwaggerV2SingleType(
  /// The type named by the scalar `type` keyword.
  final SwaggerV2Type value,
) extends SwaggerV2SchemaType {
  /// Preserves a type written as one name.
  this;

  @override
  String toJson() => value.wireName;
}

/// Schema types written as an array of names.
final class SwaggerV2TypeSet(Iterable<SwaggerV2Type> values)
    extends SwaggerV2SchemaType {
  /// Preserves the order of the declared type names.
  this;

  /// Allowed types in declaration order.
  final List<SwaggerV2Type> values = List.unmodifiable(values);
  @override
  List<String> toJson() => values.map((value) => value.wireName).toList();
}

/// One schema for all items or one schema per tuple position.
sealed class const SwaggerV2SchemaItems() {
  /// Initializes a concrete subtype.
  this;

  /// Returns a schema or a list of tuple schemas.
  Object toJson();
}

/// A schema that applies to every item in an array.
final class const SwaggerV2SingleItems(
  /// Schema that describes the value.
  final SwaggerV2Schema schema,
) extends SwaggerV2SchemaItems {
  /// Applies one schema to every array element.
  this;

  @override
  Map<String, Object?> toJson() => schema.toJson();
}

/// Schemas that apply to successive array positions.
final class SwaggerV2TupleItems(Iterable<SwaggerV2Schema> schemas)
    extends SwaggerV2SchemaItems {
  /// Copies schemas in array position order.
  this;

  /// Schemas indexed by array position.
  final List<SwaggerV2Schema> schemas = List.unmodifiable(schemas);
  @override
  List<Object?> toJson() => schemas.map((schema) => schema.toJson()).toList();
}

/// The structure, constraints, and annotations of a payload.
final class SwaggerV2Schema({
  /// The URI reference from `$ref`.
  final String? ref,

  /// Allowed instance type.
  final SwaggerV2SchemaType? type,

  /// Format identifier that refines the declared type.
  final String? format,

  /// Human-readable title.
  final String? title,

  /// Description supplied by the document author.
  final String? description,

  /// Rules for the elements of an array.
  final SwaggerV2SchemaItems? items,
  List<SwaggerV2Schema>? allOf,
  Map<String, SwaggerV2Schema>? properties,

  /// Rule for properties outside the declared property schemas.
  final SwaggerV2AdditionalProperties? additionalProperties,
  List<String>? requiredProperties,

  /// Maximum number of object properties.
  final int? maxProperties,

  /// Minimum number of object properties.
  final int? minProperties,

  /// The property used to select a more specific schema.
  final String? discriminator,

  /// Marks a property for use in responses.
  final bool? readOnly,

  /// XML serialization rules.
  final SwaggerV2Xml? xml,

  /// A link to related documentation.
  final SwaggerV2ExternalDocumentation? externalDocs,

  /// An inline example value.
  final JsonValue? example,

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
  /// Sets the constraints and annotations for a payload.
  this;

  /// Schemas that must all match the instance.
  final List<SwaggerV2Schema>? allOf = allOf == null
      ? null
      : List.unmodifiable(allOf);

  /// Schemas indexed by property name.
  final Map<String, SwaggerV2Schema>? properties = properties == null
      ? null
      : Map.unmodifiable(properties);

  /// Property names that an object must contain.
  final List<String>? requiredProperties = requiredProperties == null
      ? null
      : List.unmodifiable(requiredProperties);

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
    r'$ref': ?ref,
    if (type != null) 'type': type!.toJson(),
    'format': ?format,
    'title': ?title,
    'description': ?description,
    if (items != null) 'items': items!.toJson(),
    if (allOf != null) 'allOf': allOf!.map((value) => value.toJson()).toList(),
    if (properties != null)
      'properties': properties!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (additionalProperties != null)
      'additionalProperties': additionalProperties!.toJson(),
    if (requiredProperties != null)
      'required': requiredProperties!.map((value) => value).toList(),
    'maxProperties': ?maxProperties,
    'minProperties': ?minProperties,
    'discriminator': ?discriminator,
    'readOnly': ?readOnly,
    if (xml != null) 'xml': xml!.toJson(),
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
    if (example != null) 'example': example!.toJson(),
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
