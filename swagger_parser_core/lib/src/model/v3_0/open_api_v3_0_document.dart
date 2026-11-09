part of '../open_api_document.dart';

/// Root of the OpenAPI 3.0 document tree.
final class OpenApiV30Document({
  /// Title, API version, and publication details.
  required final OpenApiV30Info info,

  /// Operations indexed by relative API path.
  required final OpenApiV30Paths paths,

  /// Specification version as written in the document.
  final String openapi = '3.0.4',
  List<OpenApiV30Server>? servers,

  /// Definitions that other parts of the document can reference.
  final OpenApiV30Components? components,
  List<OpenApiV30SecurityRequirement>? security,
  List<OpenApiV30Tag>? tags,

  /// A link to related documentation.
  final OpenApiV30ExternalDocumentation? externalDocs,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends OpenApiDocument with OpenApiV30Object {
  /// Copies the root fields into an immutable OpenAPI 3.0 document.
  this;

  /// Base URLs for API calls in this scope.
  final List<OpenApiV30Server>? servers = servers == null
      ? null
      : List.unmodifiable(servers);

  /// Default security requirements for operations.
  final List<OpenApiV30SecurityRequirement>? security = security == null
      ? null
      : List.unmodifiable(security);

  /// Tag definitions in the author's display order.
  final List<OpenApiV30Tag>? tags = tags == null
      ? null
      : List.unmodifiable(tags);

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  OpenApiVersion get version =>
      OpenApiVersion(family: OpenApiFamily.v30, value: openapi);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'openapi': openapi,
    'info': info.toJson(),
    'paths': paths.toJson(),
    if (servers != null)
      'servers': servers!.map((value) => value.toJson()).toList(),
    if (components != null) 'components': components!.toJson(),
    if (security != null)
      'security': security!.map((value) => value.toJson()).toList(),
    if (tags != null) 'tags': tags!.map((value) => value.toJson()).toList(),
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
  };
}
