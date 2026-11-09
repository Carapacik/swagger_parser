part of 'swagger_v2_objects.dart';

/// Contact details for questions about the API.
final class SwaggerV2Contact({
  /// Name of the contact person or organization.
  final String? name,

  /// URL with contact information.
  final String? url,

  /// Contact email address.
  final String? email,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Records the contact methods supplied by the author.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': ?name,
    'url': ?url,
    'email': ?email,
  };
}

/// License terms for the API.
final class SwaggerV2License({
  /// License name supplied by the author.
  required final String name,

  /// URL of the license terms.
  final String? url,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Records the license by name.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': name,
    'url': ?url,
  };
}

/// Title, version, and publication details of the described API.
final class SwaggerV2Info({
  /// Human-readable title.
  required final String title,

  /// Version of the described API from `info.version`.
  required final String version,

  /// Description supplied by the document author.
  final String? description,

  /// URL for the API terms of service.
  final String? termsOfService,

  /// Contact details for the API.
  final SwaggerV2Contact? contact,

  /// License for use of the API.
  final SwaggerV2License? license,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Records the API title and its declared version.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'title': title,
    'version': version,
    'description': ?description,
    'termsOfService': ?termsOfService,
    if (contact != null) 'contact': contact!.toJson(),
    if (license != null) 'license': license!.toJson(),
  };
}

/// A link to additional documentation.
final class SwaggerV2ExternalDocumentation({
  /// URL of the related documentation.
  required final String url,

  /// Description supplied by the document author.
  final String? description,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Links to documentation at [url].
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'url': url,
    'description': ?description,
  };
}

/// XML element, attribute, and namespace rules for a property.
final class SwaggerV2Xml({
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
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Sets XML naming and serialization options for a property.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

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

/// Metadata for a group of operations.
final class SwaggerV2Tag({
  /// Tag name used by operations.
  required final String name,

  /// Description supplied by the document author.
  final String? description,

  /// A link to related documentation.
  final SwaggerV2ExternalDocumentation? externalDocs,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Names a group of operations for documentation.
  this;

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': name,
    'description': ?description,
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
  };
}
