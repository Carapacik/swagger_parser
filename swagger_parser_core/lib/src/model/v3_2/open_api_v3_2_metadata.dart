part of 'open_api_v3_2_objects.dart';

/// Title, version, and publication details of the described API.
final class OpenApiV32Info({
  /// Human-readable title.
  required final String title,

  /// Version of the described API from `info.version`.
  required final String version,

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// URL for the API terms of service.
  final String? termsOfService,

  /// Contact details for the API.
  final OpenApiV32Contact? contact,

  /// License for use of the API.
  final OpenApiV32License? license,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Records the API title and its declared version.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'title': title,
    'version': version,
    'summary': ?summary,
    'description': ?description,
    'termsOfService': ?termsOfService,
    if (contact != null) 'contact': contact!.toJson(),
    if (license != null) 'license': license!.toJson(),
  };
}

/// Contact details for questions about the API.
final class OpenApiV32Contact({
  /// Name of the contact person or organization.
  final String? name,

  /// URL with contact information.
  final String? url,

  /// Contact email address.
  final String? email,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Records the contact methods supplied by the author.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': ?name,
    'url': ?url,
    'email': ?email,
  };
}

/// License terms for the API.
final class OpenApiV32License({
  /// License name supplied by the author.
  required final String name,

  /// URL of the license terms.
  final String? url,

  /// SPDX license expression.
  final String? identifier,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Records the license by name.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': name,
    'url': ?url,
    'identifier': ?identifier,
  };
}

/// A link to additional documentation.
final class OpenApiV32ExternalDocumentation({
  /// URL of the related documentation.
  required final String url,

  /// Description supplied by the document author.
  final String? description,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Links to documentation at [url].
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'url': url,
    'description': ?description,
  };
}

/// Metadata for a group of operations.
final class OpenApiV32Tag({
  /// Tag name used by operations.
  required final String name,

  /// Category of the tag, such as `nav`.
  final String? kind,

  /// Name of the parent tag.
  final String? parent,

  /// Short label for the tag.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// A link to related documentation.
  final OpenApiV32ExternalDocumentation? externalDocs,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Names a group of operations for documentation.
  this;

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'kind': ?kind,
    'parent': ?parent,
    'summary': ?summary,
    'name': name,
    'description': ?description,
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
  };
}

/// A base URL with optional template variables.
final class OpenApiV32Server({
  /// Server URL, which can contain template variables.
  required final String url,

  /// Name used to identify this server.
  final String? name,

  /// Description supplied by the document author.
  final String? description,
  Map<String, OpenApiV32ServerVariable>? variables,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Associates a base URL template with its variables.
  this;

  /// Variable definitions indexed by URL template variable name.
  final Map<String, OpenApiV32ServerVariable>? variables = variables == null
      ? null
      : Map.unmodifiable(variables);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'name': ?name,
    'url': url,
    'description': ?description,
    if (variables != null)
      'variables': variables!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
  };
}

/// A substitution for a variable in a server URL.
final class OpenApiV32ServerVariable({
  /// The default value declared by the author.
  required final String defaultValue,
  List<String>? enumValues,

  /// Description supplied by the document author.
  final String? description,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Sets the default substitution and optional allowed values.
  this;

  /// Allowed values from `enum`, in source order.
  final List<String>? enumValues = enumValues == null
      ? null
      : List.unmodifiable(enumValues);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'default': defaultValue,
    if (enumValues != null) 'enum': enumValues!.toList(),
    'description': ?description,
  };
}
