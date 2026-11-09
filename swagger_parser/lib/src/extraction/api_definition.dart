import 'package:swagger_parser_core/swagger_parser_core.dart';

/// HTTP operations and schemas extracted from one API description.
class ApiDefinition({
  /// Title from the entry document.
  required final String title,

  /// Application version from `info.version`.
  required final String apiVersion,

  /// OpenAPI version of the entry document.
  required final OpenApiVersion specVersion,

  /// Entry document URI used to resolve mapping selectors.
  final Uri? sourceUri,

  Iterable<ApiOperation> operations = const [],
  Iterable<ApiOperation> webhooks = const [],
  Map<ReferenceLocation, List<ApiOperation>> callbacks = const {},
  Iterable<JsonValue> servers = const [],
  Iterable<JsonValue> security = const [],
  Map<String, JsonValue> securitySchemes = const {},
  Map<String, ReferenceLocation> namedSchemas = const {},
  Map<ReferenceLocation, ApiSchema> schemas = const {},
  Map<(Uri, String), ReferenceLocation> dynamicAnchors = const {},
}) {
  /// Copies the extracted routes and schema indexes.
  this;

  /// Operations mounted in the entry document.
  final List<ApiOperation> operations = List.unmodifiable(operations);

  /// Incoming webhook operations keyed by their path name in each operation.
  final List<ApiOperation> webhooks = List.unmodifiable(webhooks);

  /// Callback operations by physical callback definition. Links can form cycles.
  final Map<ReferenceLocation, List<ApiOperation>> callbacks = Map.unmodifiable(
    callbacks.map(
      (id, operations) =>
          MapEntry(id, List<ApiOperation>.unmodifiable(operations)),
    ),
  );

  /// Entry server definitions, including URL templates and variables.
  final List<JsonValue> servers = List.unmodifiable(servers);

  /// Entry security alternatives. Each object lists schemes used together.
  final List<JsonValue> security = List.unmodifiable(security);

  /// Security schemes by entry name.
  final Map<String, JsonValue> securitySchemes = Map.unmodifiable(
    securitySchemes,
  );

  /// All named schemas in the entry document, including unused schemas.
  final Map<String, ReferenceLocation> namedSchemas = Map.unmodifiable(
    namedSchemas,
  );

  /// Entry, inline, and reachable external schemas by physical identity.
  final Map<ReferenceLocation, ApiSchema> schemas = Map.unmodifiable(schemas);

  /// Reachable dynamic anchors by canonical resource URI and name.
  final Map<(Uri, String), ReferenceLocation> dynamicAnchors = Map.unmodifiable(
    dynamicAnchors,
  );
}

/// One HTTP method mounted at a path template.
final class ApiOperation({
  /// HTTP method in wire case.
  required final String method,

  /// Path template at the mount.
  required final String path,

  /// Physical operation declaration.
  required final ReferenceLocation source,
  required Iterable<ApiParameter> parameters,
  required Map<String, ApiResponse> responses,

  /// Body after parameter and media type inheritance.
  final ApiRequestBody? requestBody,
  Map<String, ReferenceLocation> callbacks = const {},
  Iterable<JsonValue> servers = const [],
  Iterable<JsonValue> security = const [],

  /// Operation ID as declared in the source.
  final String? operationId,

  /// External documentation URL declared on the operation.
  final String? externalDocsUrl,

  /// Short description from the author.
  final String? summary,

  /// Full description from the author.
  final String? description,
  Iterable<String> tags = const [],

  /// Whether the author deprecated the operation.
  final bool deprecated = false,
}) {
  /// Copies the effective parameters and responses.
  this;

  /// Original operation tags.
  final List<String> tags = List.unmodifiable(tags);

  /// Parameters after operation overrides.
  final List<ApiParameter> parameters = List.unmodifiable(parameters);

  /// Callback definitions by local name.
  final Map<String, ReferenceLocation> callbacks = Map.unmodifiable(callbacks);

  /// Effective servers for this mount.
  final List<JsonValue> servers = List.unmodifiable(servers);

  /// Effective security alternatives for this operation.
  final List<JsonValue> security = List.unmodifiable(security);

  /// Responses keyed by exact status, range, or `default`.
  final Map<String, ApiResponse> responses = Map.unmodifiable(responses);
}

/// A parameter on an extracted operation.
final class ApiParameter({
  /// Name sent on the wire.
  required final String name,

  /// Request location, such as `path` or `query`.
  required final String location,

  /// Whether the caller must supply the parameter.
  required final bool isRequired,

  /// Effective serialization in the declaring OpenAPI family.
  required final ParameterSerialization serialization,

  /// Physical parameter definition.
  required final ReferenceLocation source,

  /// Source parameter description.
  final String? description,

  /// Whether the source parameter is deprecated.
  final bool deprecated = false,

  /// Whether reserved URI characters can appear in a query value.
  final bool allowReserved = false,

  /// Schema in the API registry.
  final ReferenceLocation? schema,
  Map<String?, ApiMediaType> content = const {},
}) {
  /// Records the wire identity, presence rule, and serialization.
  this;

  /// Representations for content-based parameters.
  final Map<String?, ApiMediaType> content = Map.unmodifiable(content);
}

/// The effective request payload.
final class ApiRequestBody({
  /// Physical body declaration or operation for a group of form fields.
  required final ReferenceLocation source,

  /// Whether the request must include the body.
  required final bool isRequired,
  required Map<String?, ApiMediaType> content,
  Iterable<ApiParameter> formFields = const [],

  /// Author's description.
  final String? description,
}) {
  /// Copies body representations and Swagger form fields.
  this;

  /// Representations keyed by the declared media type.
  final Map<String?, ApiMediaType> content = Map.unmodifiable(content);

  /// Swagger form parameters with their wire names and collection formats.
  final List<ApiParameter> formFields = List.unmodifiable(formFields);
}

/// A response for one status selector.
final class ApiResponse({
  /// Physical response definition.
  required final ReferenceLocation source,
  required Map<String?, ApiMediaType> content,

  /// Description supplied by the author.
  final String? description,
  Map<String, ApiParameter> headers = const {},
  Map<String, JsonValue> links = const {},
}) {
  /// Copies the representations described for this status.
  this;

  /// Response headers keyed by wire name.
  final Map<String, ApiParameter> headers = Map.unmodifiable(headers);

  /// Resolved OpenAPI Link Objects by name.
  final Map<String, JsonValue> links = Map.unmodifiable(links);

  /// Representations by media type. A null key means Swagger omitted the type.
  final Map<String?, ApiMediaType> content = Map.unmodifiable(content);
}

/// Schemas for one payload representation.
final class ApiMediaType({
  /// Schema for the complete body.
  final ReferenceLocation? schema,

  /// Schema for one item of a sequential payload.
  final ReferenceLocation? itemSchema,
  Map<String, ApiEncoding> encodings = const {},
}) {
  /// Records the body schema and optional stream item schema.
  this;

  /// Encoding by relative JSON Pointer, including positional encodings.
  final Map<String, ApiEncoding> encodings = Map.unmodifiable(encodings);
}

/// Multipart encoding for one property or sequential item.
final class ApiEncoding({
  /// Source encoding fields, including nested encodings.
  required final JsonValue definition,
  required Map<String, ApiParameter> headers,
}) {
  /// Records wire options and resolved part headers.
  this;

  /// Part headers by wire name.
  final Map<String, ApiParameter> headers = Map.unmodifiable(headers);
}

/// A schema in the registry. Links retain recursive schema identity.
final class ApiSchema({
  /// OpenAPI family at the schema definition.
  required final OpenApiFamily family,

  /// Complete immutable schema, including dialect-specific constraints.
  required final JsonValue definition,
  required Iterable<String> types,
  required Map<String, ReferenceLocation> properties,
  required Iterable<String> requiredProperties,

  /// Effective JSON Schema dialect for 3.1 and 3.2.
  final String? dialect,

  /// Schema for array items after [prefixItems].
  final ReferenceLocation? items,
  Iterable<ReferenceLocation> prefixItems = const [],

  /// Schema used to count matching array items.
  final ReferenceLocation? contains,

  /// Schema for values under undeclared property names.
  final ReferenceLocation? additionalProperties,
  Iterable<ReferenceLocation> allOf = const [],
  Iterable<ReferenceLocation> oneOf = const [],
  Iterable<ReferenceLocation> anyOf = const [],

  /// Tag used to select an explicit alternative.
  final ApiDiscriminator? discriminator,

  /// Target of a static schema reference.
  final ReferenceLocation? reference,

  /// Initial target and anchor of a dynamic reference.
  final ResolvedReference? dynamicReference,

  /// Canonical JSON Schema resource URI for dynamic scope selection.
  final Uri? resourceUri,
}) {
  /// Copies schema constraints, property links, and presence rules.
  this;

  /// Declared types, including null for Swagger x-nullable or OpenAPI nullable.
  final Set<String> types = Set.unmodifiable(types);

  /// Property schemas keyed by wire name.
  final Map<String, ReferenceLocation> properties = Map.unmodifiable(
    properties,
  );

  /// Property names that must be present.
  final Set<String> requiredProperties = Set.unmodifiable(requiredProperties);

  /// Positional array schemas in wire order.
  final List<ReferenceLocation> prefixItems = List.unmodifiable(prefixItems);

  /// Schema branches that apply together.
  final List<ReferenceLocation> allOf = List.unmodifiable(allOf);

  /// Alternatives that require exactly one match.
  final List<ReferenceLocation> oneOf = List.unmodifiable(oneOf);

  /// Alternatives that allow multiple matches.
  final List<ReferenceLocation> anyOf = List.unmodifiable(anyOf);
}

/// Resolved tag mappings for a schema union.
final class ApiDiscriminator(
  /// JSON property used for dispatch.
  final String propertyName,
  Map<String, ReferenceLocation> mapping, {

  /// Target for a missing or unmapped tag.
  final ReferenceLocation? defaultMapping,
}) {
  /// Copies explicit mappings and the optional OpenAPI 3.2 fallback.
  this;

  /// Schema targets by wire value.
  final Map<String, ReferenceLocation> mapping = Map.unmodifiable(mapping);
}
