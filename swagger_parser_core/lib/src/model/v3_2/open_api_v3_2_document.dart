part of '../open_api_document.dart';

/// Root of the OpenAPI 3.2 document tree.
final class OpenApiV32Document({
  /// Title, API version, and publication details.
  required final OpenApiV32Info info,

  /// Base URI reference declared by `$self`.
  final String? self,

  /// Operations indexed by relative API path.
  final OpenApiV32Paths? paths,

  /// Default schema dialect URI declared by the document.
  final String? jsonSchemaDialect,
  Map<String, OpenApiV32PathItem>? webhooks,

  /// Specification version as written in the document.
  final String openapi = '3.2.1',
  List<OpenApiV32Server>? servers,

  /// Definitions that other parts of the document can reference.
  final OpenApiV32Components? components,
  List<OpenApiV32SecurityRequirement>? security,
  List<OpenApiV32Tag>? tags,

  /// A link to related documentation.
  final OpenApiV32ExternalDocumentation? externalDocs,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends OpenApiDocument with OpenApiV32Object {
  /// Copies the root fields into an immutable OpenAPI 3.2 document.
  this;

  /// Incoming webhook path items indexed by event name.
  final Map<String, OpenApiV32PathItem>? webhooks = webhooks == null
      ? null
      : Map.unmodifiable(webhooks);

  /// Base URLs for API calls in this scope.
  final List<OpenApiV32Server>? servers = servers == null
      ? null
      : List.unmodifiable(servers);

  /// Default security requirements for operations.
  final List<OpenApiV32SecurityRequirement>? security = security == null
      ? null
      : List.unmodifiable(security);

  /// Tag definitions in the author's display order.
  final List<OpenApiV32Tag>? tags = tags == null
      ? null
      : List.unmodifiable(tags);

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  OpenApiVersion get version =>
      OpenApiVersion(family: OpenApiFamily.v32, value: openapi);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    r'$self': ?self,
    'openapi': openapi,
    'info': info.toJson(),
    if (paths != null) 'paths': paths!.toJson(),
    'jsonSchemaDialect': ?jsonSchemaDialect,
    if (webhooks != null)
      'webhooks': {
        for (final entry in webhooks!.entries) entry.key: entry.value.toJson(),
      },
    if (servers != null)
      'servers': servers!.map((value) => value.toJson()).toList(),
    if (components != null) 'components': components!.toJson(),
    if (security != null)
      'security': security!.map((value) => value.toJson()).toList(),
    if (tags != null) 'tags': tags!.map((value) => value.toJson()).toList(),
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
  };
}
