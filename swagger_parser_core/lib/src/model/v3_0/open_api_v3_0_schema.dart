part of 'open_api_v3_0_objects.dart';

/// The structure, constraints, and annotations of a payload.
final class OpenApiV30Schema({
  /// Human-readable title.
  final String? title,

  /// Description supplied by the document author.
  final String? description,

  /// Allowed instance type.
  final OpenApiV30Type? type,

  /// Format identifier that refines the declared type.
  final String? format,

  /// Whether the declared type also accepts null.
  final bool? nullable,

  /// The default value declared by the author.
  final JsonValue? defaultValue,

  /// An inline example value.
  final JsonValue? example,
  List<JsonValue>? enumValues,

  /// Valid numbers must be multiples of this positive value.
  final num? multipleOf,

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

  /// Maximum number of object properties.
  final int? maxProperties,

  /// Minimum number of object properties.
  final int? minProperties,
  List<String>? requiredProperties,

  /// Schema that the instance must fail to match.
  final OpenApiV30RefOr<OpenApiV30Schema>? not,
  List<OpenApiV30RefOr<OpenApiV30Schema>>? allOf,
  List<OpenApiV30RefOr<OpenApiV30Schema>>? oneOf,
  List<OpenApiV30RefOr<OpenApiV30Schema>>? anyOf,

  /// Rules for the elements of an array.
  final OpenApiV30RefOr<OpenApiV30Schema>? items,
  Map<String, OpenApiV30RefOr<OpenApiV30Schema>>? properties,

  /// Rule for properties outside the declared property schemas.
  final OpenApiV30AdditionalProperties? additionalProperties,

  /// The property used to select a more specific schema.
  final OpenApiV30Discriminator? discriminator,

  /// Marks a property for use in responses.
  final bool? readOnly,

  /// Marks a property for use in requests.
  final bool? writeOnly,

  /// XML serialization rules.
  final OpenApiV30Xml? xml,

  /// A link to related documentation.
  final OpenApiV30ExternalDocumentation? externalDocs,

  /// Whether the author discourages new uses.
  final bool? deprecated,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Sets the constraints and annotations for a payload.
  this;

  /// Allowed values from `enum`, in source order.
  final List<JsonValue>? enumValues = enumValues == null
      ? null
      : List.unmodifiable(enumValues);

  /// Property names that an object must contain.
  final List<String>? requiredProperties = requiredProperties == null
      ? null
      : List.unmodifiable(requiredProperties);

  /// Schemas that must all match the instance.
  final List<OpenApiV30RefOr<OpenApiV30Schema>>? allOf = allOf == null
      ? null
      : List.unmodifiable(allOf);

  /// Exactly one of these schemas must match the instance.
  final List<OpenApiV30RefOr<OpenApiV30Schema>>? oneOf = oneOf == null
      ? null
      : List.unmodifiable(oneOf);

  /// At least one of these schemas must match the instance.
  final List<OpenApiV30RefOr<OpenApiV30Schema>>? anyOf = anyOf == null
      ? null
      : List.unmodifiable(anyOf);

  /// Schemas indexed by property name.
  final Map<String, OpenApiV30RefOr<OpenApiV30Schema>>? properties =
      properties == null ? null : Map.unmodifiable(properties);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'title': ?title,
    'description': ?description,
    'type': ?type?.name,
    'format': ?format,
    'nullable': ?nullable,
    if (defaultValue != null) 'default': defaultValue!.toJson(),
    if (example != null) 'example': example!.toJson(),
    if (enumValues != null)
      'enum': enumValues!.map((value) => value.toJson()).toList(),
    'multipleOf': ?multipleOf,
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
    'maxProperties': ?maxProperties,
    'minProperties': ?minProperties,
    if (requiredProperties != null) 'required': requiredProperties!.toList(),
    if (not != null) 'not': not!.toJson(),
    if (allOf != null) 'allOf': allOf!.map((value) => value.toJson()).toList(),
    if (oneOf != null) 'oneOf': oneOf!.map((value) => value.toJson()).toList(),
    if (anyOf != null) 'anyOf': anyOf!.map((value) => value.toJson()).toList(),
    if (items != null) 'items': items!.toJson(),
    if (properties != null)
      'properties': properties!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (additionalProperties != null)
      'additionalProperties': additionalProperties!.toJson(),
    if (discriminator != null) 'discriminator': discriminator!.toJson(),
    'readOnly': ?readOnly,
    'writeOnly': ?writeOnly,
    if (xml != null) 'xml': xml!.toJson(),
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
    'deprecated': ?deprecated,
  };
}

/// A property that selects a schema for a payload.
final class OpenApiV30Discriminator({
  /// Name of the property that selects the schema.
  required final String propertyName,
  Map<String, String>? mapping,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Selects a schema by property value and optional mapping.
  this;

  /// Schema names or references indexed by discriminator value.
  final Map<String, String>? mapping = mapping == null
      ? null
      : Map.unmodifiable(mapping);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'propertyName': propertyName,
    if (mapping != null) 'mapping': Map<String, String>.of(mapping!),
  };
}

/// XML element, attribute, and namespace rules for a property.
final class OpenApiV30Xml({
  /// Element or attribute name to use in XML.
  final String? name,

  /// Namespace URI for the XML element.
  final String? namespace,

  /// Namespace prefix for the XML name.
  final String? prefix,

  /// Whether to serialize the property as an XML attribute.
  final bool? attribute,

  /// Whether to enclose array elements in a wrapper element.
  final bool? wrapped,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Sets XML naming and serialization options for a property.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': ?name,
    'namespace': ?namespace,
    'prefix': ?prefix,
    'attribute': ?attribute,
    'wrapped': ?wrapped,
  };
}
