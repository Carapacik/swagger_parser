part of 'open_api_v3_1_objects.dart';

/// A boolean or object schema with its effective dialect.
sealed class const OpenApiV31Schema() {
  /// Initializes a concrete subtype.
  this;

  /// URI of the OpenAPI 3.1 base dialect.
  static const oasDialect = 'https://spec.openapis.org/oas/3.1/dialect/base';

  /// URI of the JSON Schema 2020-12 dialect.
  static const draft202012 = 'https://json-schema.org/draft/2020-12/schema';

  /// Effective dialect URI for this schema.
  String get dialect;

  /// Returns the schema as a JSON boolean or object.
  Object toJson();
}

/// A schema that accepts every instance or none.
final class const OpenApiV31BooleanSchema({
  /// True accepts every instance. False rejects every instance.
  required final bool value,
  @override final String dialect = OpenApiV31Schema.oasDialect,
}) extends OpenApiV31Schema {
  /// Uses [value] as the validation result for every instance.
  this;

  @override
  bool toJson() => value;
}

/// Preserves keywords of a dialect the parser cannot interpret.
final class OpenApiV31ForeignSchema({
  @override required final String dialect,
  required Map<String, Object?> fields,
}) extends OpenApiV31Schema {
  /// Copies the dialect's keywords as immutable JSON values.
  this;

  /// Original keywords and values of the foreign dialect.
  final Map<String, JsonValue> keywords = Map.unmodifiable(
    fields.map((key, value) => MapEntry(key, JsonValue(value))),
  );
  @override
  Map<String, Object?> toJson() => {
    for (final entry in keywords.entries) entry.key: entry.value.toJson(),
  };
}

/// A type name accepted by OpenAPI 3.1.
enum OpenApiV31Type() {
  /// An ordered sequence of values.
  array,

  /// A true or false value.
  boolean,

  /// A number with no fractional part.
  integer,

  /// The JSON `null` type.
  nullValue,

  /// A numeric value, including an integer.
  number,

  /// A map of named properties.
  object,

  /// A sequence of characters.
  string;

  /// The type name used in the document.
  String get wireName => this == nullValue ? 'null' : name;
}

/// The single name or list used for the schema's `type`.
sealed class const OpenApiV31SchemaType() {
  /// Initializes a concrete subtype.
  this;

  /// Returns a type name or a list of type names.
  Object toJson();
}

/// A schema type written as one name.
final class const OpenApiV31SingleType(
  /// The type named by the scalar `type` keyword.
  final OpenApiV31Type value,
) extends OpenApiV31SchemaType {
  /// Preserves a type written as one name.
  this;

  @override
  String toJson() => value.wireName;
}

/// Schema types written as an array of names.
final class OpenApiV31TypeSet(List<OpenApiV31Type> values)
    extends OpenApiV31SchemaType {
  /// Preserves the order of the declared type names.
  this;

  /// Allowed types in declaration order.
  final List<OpenApiV31Type> values = List.unmodifiable(values);
  @override
  List<String> toJson() => values.map((type) => type.wireName).toList();
}

/// JSON Schema keywords and annotations for a 3.1 schema object.
final class OpenApiV31ObjectSchema({
  @override final String dialect = OpenApiV31Schema.oasDialect,

  /// Dialect URI declared by `$schema` on this resource.
  final String? schemaDialect,

  /// Schema resource identifier from `$id`.
  final String? id,

  /// The URI reference from `$ref`.
  final String? ref,

  /// Plain name used to reference this schema within its resource.
  final String? anchor,

  /// Reference resolved against the active dynamic scope.
  final String? dynamicRef,

  /// Name available for dynamic reference resolution.
  final String? dynamicAnchor,
  Map<String, bool>? vocabulary,

  /// Author comment from `$comment`.
  final String? comment,
  Map<String, OpenApiV31Schema>? defs,

  /// Allowed JSON instance type or types.
  final OpenApiV31SchemaType? type,

  /// Human-readable title.
  final String? title,

  /// Description supplied by the document author.
  final String? description,

  /// The default value declared by the author.
  final JsonValue? defaultValue,

  /// Whether the author discourages new uses.
  final bool? deprecated,

  /// Marks a property for use in responses.
  final bool? readOnly,

  /// Marks a property for use in requests.
  final bool? writeOnly,
  List<JsonValue>? examples,

  /// The single value permitted by `const`.
  final JsonValue? constValue,
  List<JsonValue>? enumValues,

  /// Valid numbers must be multiples of this positive value.
  final num? multipleOf,

  /// Lower numeric bound.
  final num? minimum,

  /// Upper numeric bound.
  final num? maximum,

  /// Lower bound that valid numbers must exceed.
  final num? exclusiveMinimum,

  /// Upper bound that valid numbers must be less than.
  final num? exclusiveMaximum,

  /// Minimum string length in Unicode code points.
  final int? minLength,

  /// Maximum string length in Unicode code points.
  final int? maxLength,

  /// Regular expression that a string must match.
  final String? pattern,

  /// Format identifier that refines the declared type.
  final String? format,

  /// Minimum number of array elements.
  final int? minItems,

  /// Maximum number of array elements.
  final int? maxItems,

  /// Whether all array elements must be distinct.
  final bool? uniqueItems,

  /// Minimum number of elements that must match `contains`.
  final int? minContains,

  /// Maximum number of elements that can match `contains`.
  final int? maxContains,

  /// Minimum number of object properties.
  final int? minProperties,

  /// Maximum number of object properties.
  final int? maxProperties,
  List<String>? requiredProperties,
  Map<String, List<String>>? dependentRequired,
  List<OpenApiV31Schema>? allOf,
  List<OpenApiV31Schema>? anyOf,
  List<OpenApiV31Schema>? oneOf,

  /// Schema that the instance must fail to match.
  final OpenApiV31Schema? not,

  /// Condition that selects the `then` or `else` schema.
  final OpenApiV31Schema? ifSchema,

  /// Schema applied when `if` matches.
  final OpenApiV31Schema? thenSchema,

  /// Schema applied when `if` does not match.
  final OpenApiV31Schema? elseSchema,

  /// Schema for elements after the `prefixItems` positions.
  final OpenApiV31Schema? items,
  List<OpenApiV31Schema>? prefixItems,

  /// Schema used to count matching array elements.
  final OpenApiV31Schema? contains,

  /// Schema for elements left unevaluated by other keywords.
  final OpenApiV31Schema? unevaluatedItems,
  Map<String, OpenApiV31Schema>? properties,
  Map<String, OpenApiV31Schema>? patternProperties,

  /// Schema applied to each property name.
  final OpenApiV31Schema? propertyNames,

  /// Schema for properties outside `properties` and `patternProperties`.
  final OpenApiV31Schema? additionalProperties,
  Map<String, OpenApiV31Schema>? dependentSchemas,

  /// Schema for properties left unevaluated by other keywords.
  final OpenApiV31Schema? unevaluatedProperties,

  /// Encoding of the data carried by a string.
  final String? contentEncoding,

  /// Media type of the data carried by a string.
  final String? contentMediaType,

  /// Schema describing the decoded string content.
  final OpenApiV31Schema? contentSchema,

  /// The property used to select a more specific schema.
  final OpenApiV31Discriminator? discriminator,

  /// XML serialization rules.
  final OpenApiV31Xml? xml,

  /// A link to related documentation.
  final OpenApiV31ExternalDocumentation? externalDocs,

  /// An inline example value.
  final JsonValue? example,
  super.extensions,
  super.extraFields,
}) extends _FixedObject implements OpenApiV31Schema {
  /// Copies keyword collections and records the effective dialect.
  this;

  /// Vocabulary URIs mapped to their required flags.
  final Map<String, bool>? vocabulary = vocabulary == null
      ? null
      : Map.unmodifiable(vocabulary);

  /// Local schemas indexed by their `$defs` names.
  final Map<String, OpenApiV31Schema>? defs = defs == null
      ? null
      : Map.unmodifiable(defs);

  /// Example instances supplied by the schema author.
  final List<JsonValue>? examples = examples == null
      ? null
      : List.unmodifiable(examples);

  /// Allowed values from `enum`, in source order.
  final List<JsonValue>? enumValues = enumValues == null
      ? null
      : List.unmodifiable(enumValues);

  /// Property names that an object must contain.
  final List<String>? requiredProperties = requiredProperties == null
      ? null
      : List.unmodifiable(requiredProperties);

  /// Required property names indexed by the triggering property.
  final Map<String, List<String>>? dependentRequired = dependentRequired == null
      ? null
      : Map.unmodifiable(
          dependentRequired.map(
            (key, names) => MapEntry(key, List<String>.unmodifiable(names)),
          ),
        );

  /// Schemas that must all match the instance.
  final List<OpenApiV31Schema>? allOf = allOf == null
      ? null
      : List.unmodifiable(allOf);

  /// At least one of these schemas must match the instance.
  final List<OpenApiV31Schema>? anyOf = anyOf == null
      ? null
      : List.unmodifiable(anyOf);

  /// Exactly one of these schemas must match the instance.
  final List<OpenApiV31Schema>? oneOf = oneOf == null
      ? null
      : List.unmodifiable(oneOf);

  /// Schemas for the first array elements, in order.
  final List<OpenApiV31Schema>? prefixItems = prefixItems == null
      ? null
      : List.unmodifiable(prefixItems);

  /// Schemas indexed by property name.
  final Map<String, OpenApiV31Schema>? properties = properties == null
      ? null
      : Map.unmodifiable(properties);

  /// Property schemas indexed by regular expression.
  final Map<String, OpenApiV31Schema>? patternProperties =
      patternProperties == null ? null : Map.unmodifiable(patternProperties);

  /// Schemas applied when the named property is present.
  final Map<String, OpenApiV31Schema>? dependentSchemas =
      dependentSchemas == null ? null : Map.unmodifiable(dependentSchemas);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    r'$schema': ?schemaDialect,
    r'$id': ?id,
    r'$ref': ?ref,
    r'$anchor': ?anchor,
    r'$dynamicRef': ?dynamicRef,
    r'$dynamicAnchor': ?dynamicAnchor,
    if (vocabulary != null) r'$vocabulary': Map<String, bool>.of(vocabulary!),
    r'$comment': ?comment,
    if (defs != null)
      r'$defs': {
        for (final entry in defs!.entries) entry.key: entry.value.toJson(),
      },
    if (type != null) 'type': type!.toJson(),
    'title': ?title,
    'description': ?description,
    if (defaultValue != null) 'default': defaultValue!.toJson(),
    'deprecated': ?deprecated,
    'readOnly': ?readOnly,
    'writeOnly': ?writeOnly,
    if (examples != null)
      'examples': [for (final item in examples!) item.toJson()],
    if (constValue != null) 'const': constValue!.toJson(),
    if (enumValues != null)
      'enum': [for (final item in enumValues!) item.toJson()],
    'multipleOf': ?multipleOf,
    'minimum': ?minimum,
    'maximum': ?maximum,
    'exclusiveMinimum': ?exclusiveMinimum,
    'exclusiveMaximum': ?exclusiveMaximum,
    'minLength': ?minLength,
    'maxLength': ?maxLength,
    'pattern': ?pattern,
    'format': ?format,
    'minItems': ?minItems,
    'maxItems': ?maxItems,
    'uniqueItems': ?uniqueItems,
    'minContains': ?minContains,
    'maxContains': ?maxContains,
    'minProperties': ?minProperties,
    'maxProperties': ?maxProperties,
    if (requiredProperties != null) 'required': requiredProperties!.toList(),
    if (dependentRequired != null)
      'dependentRequired': {
        for (final entry in dependentRequired!.entries)
          entry.key: entry.value.toList(),
      },
    if (allOf != null) 'allOf': [for (final item in allOf!) item.toJson()],
    if (anyOf != null) 'anyOf': [for (final item in anyOf!) item.toJson()],
    if (oneOf != null) 'oneOf': [for (final item in oneOf!) item.toJson()],
    if (not != null) 'not': not!.toJson(),
    if (ifSchema != null) 'if': ifSchema!.toJson(),
    if (thenSchema != null) 'then': thenSchema!.toJson(),
    if (elseSchema != null) 'else': elseSchema!.toJson(),
    if (items != null) 'items': items!.toJson(),
    if (prefixItems != null)
      'prefixItems': [for (final item in prefixItems!) item.toJson()],
    if (contains != null) 'contains': contains!.toJson(),
    if (unevaluatedItems != null)
      'unevaluatedItems': unevaluatedItems!.toJson(),
    if (properties != null)
      'properties': {
        for (final entry in properties!.entries)
          entry.key: entry.value.toJson(),
      },
    if (patternProperties != null)
      'patternProperties': {
        for (final entry in patternProperties!.entries)
          entry.key: entry.value.toJson(),
      },
    if (propertyNames != null) 'propertyNames': propertyNames!.toJson(),
    if (additionalProperties != null)
      'additionalProperties': additionalProperties!.toJson(),
    if (dependentSchemas != null)
      'dependentSchemas': {
        for (final entry in dependentSchemas!.entries)
          entry.key: entry.value.toJson(),
      },
    if (unevaluatedProperties != null)
      'unevaluatedProperties': unevaluatedProperties!.toJson(),
    'contentEncoding': ?contentEncoding,
    'contentMediaType': ?contentMediaType,
    if (contentSchema != null) 'contentSchema': contentSchema!.toJson(),
    if (discriminator != null) 'discriminator': discriminator!.toJson(),
    if (xml != null) 'xml': xml!.toJson(),
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
    if (example != null) 'example': example!.toJson(),
  };
}

/// A property that selects a schema for a payload.
final class OpenApiV31Discriminator({
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
final class OpenApiV31Xml({
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
