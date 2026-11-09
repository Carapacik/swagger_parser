part of 'open_api_v3_2_objects.dart';

/// Operations and shared parameters for one path.
final class OpenApiV32PathItem({
  Map<String, OpenApiV32Operation>? additionalOperations,

  /// The QUERY operation for this path.
  final OpenApiV32Operation? query,

  /// The URI reference from `$ref`.
  final String? ref,

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// The GET operation for this path.
  final OpenApiV32Operation? get,

  /// The PUT operation for this path.
  final OpenApiV32Operation? put,

  /// The POST operation for this path.
  final OpenApiV32Operation? post,

  /// The DELETE operation for this path.
  final OpenApiV32Operation? delete,

  /// The OPTIONS operation for this path.
  final OpenApiV32Operation? options,

  /// The HEAD operation for this path.
  final OpenApiV32Operation? head,

  /// The PATCH operation for this path.
  final OpenApiV32Operation? patch,

  /// The TRACE operation for this path.
  final OpenApiV32Operation? trace,
  List<OpenApiV32Server>? servers,
  List<OpenApiV32RefOr<OpenApiV32Parameter>>? parameters,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups operations and shared parameters for one path.
  this;

  /// Operations indexed by case-sensitive HTTP method.
  final Map<String, OpenApiV32Operation>? additionalOperations =
      additionalOperations == null
      ? null
      : Map.unmodifiable(additionalOperations);

  /// Base URLs for API calls in this scope.
  final List<OpenApiV32Server>? servers = servers == null
      ? null
      : List.unmodifiable(servers);

  /// Parameters shared by operations on this path.
  final List<OpenApiV32RefOr<OpenApiV32Parameter>>? parameters =
      parameters == null ? null : List.unmodifiable(parameters);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    if (additionalOperations != null)
      'additionalOperations': {
        for (final entry in additionalOperations!.entries)
          entry.key: entry.value.toJson(),
      },
    if (query != null) 'query': query!.toJson(),
    r'$ref': ?ref,
    'summary': ?summary,
    'description': ?description,
    if (get != null) 'get': get!.toJson(),
    if (put != null) 'put': put!.toJson(),
    if (post != null) 'post': post!.toJson(),
    if (delete != null) 'delete': delete!.toJson(),
    if (options != null) 'options': options!.toJson(),
    if (head != null) 'head': head!.toJson(),
    if (patch != null) 'patch': patch!.toJson(),
    if (trace != null) 'trace': trace!.toJson(),
    if (servers != null)
      'servers': servers!.map((value) => value.toJson()).toList(),
    if (parameters != null)
      'parameters': parameters!.map((value) => value.toJson()).toList(),
  };
}

/// The request and possible responses for one HTTP method.
final class OpenApiV32Operation({
  /// Possible results of the operation, indexed by response key.
  final OpenApiV32Responses? responses,
  List<String>? tags,

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// A link to related documentation.
  final OpenApiV32ExternalDocumentation? externalDocs,

  /// Identifier used to refer to an operation.
  final String? operationId,
  List<OpenApiV32RefOr<OpenApiV32Parameter>>? parameters,

  /// The body accepted by this operation.
  final OpenApiV32RefOr<OpenApiV32RequestBody>? requestBody,
  Map<String, OpenApiV32RefOr<OpenApiV32Callback>>? callbacks,

  /// Whether the author discourages new uses.
  final bool? deprecated,
  List<OpenApiV32SecurityRequirement>? security,
  List<OpenApiV32Server>? servers,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups request metadata and responses for one HTTP method.
  this;

  /// Names of the tags assigned to this operation.
  final List<String>? tags = tags == null ? null : List.unmodifiable(tags);

  /// Operation parameters that extend or override path parameters.
  final List<OpenApiV32RefOr<OpenApiV32Parameter>>? parameters =
      parameters == null ? null : List.unmodifiable(parameters);

  /// Callback definitions indexed by name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Callback>>? callbacks =
      callbacks == null ? null : Map.unmodifiable(callbacks);

  /// Operation-level alternatives that override document security.
  final List<OpenApiV32SecurityRequirement>? security = security == null
      ? null
      : List.unmodifiable(security);

  /// Base URLs for API calls in this scope.
  final List<OpenApiV32Server>? servers = servers == null
      ? null
      : List.unmodifiable(servers);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    if (responses != null) 'responses': responses!.toJson(),
    if (tags != null) 'tags': tags!.toList(),
    'summary': ?summary,
    'description': ?description,
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
    'operationId': ?operationId,
    if (parameters != null)
      'parameters': parameters!.map((value) => value.toJson()).toList(),
    if (requestBody != null) 'requestBody': requestBody!.toJson(),
    if (callbacks != null)
      'callbacks': callbacks!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    'deprecated': ?deprecated,
    if (security != null)
      'security': security!.map((value) => value.toJson()).toList(),
    if (servers != null)
      'servers': servers!.map((value) => value.toJson()).toList(),
  };
}

/// Named definitions for use elsewhere in the document.
final class OpenApiV32Components({
  Map<String, OpenApiV32RefOr<OpenApiV32MediaType>>? mediaTypes,
  Map<String, OpenApiV32Schema>? schemas,
  Map<String, OpenApiV32PathItem>? pathItems,
  Map<String, OpenApiV32RefOr<OpenApiV32Response>>? responses,
  Map<String, OpenApiV32RefOr<OpenApiV32Parameter>>? parameters,
  Map<String, OpenApiV32RefOr<OpenApiV32Example>>? examples,
  Map<String, OpenApiV32RefOr<OpenApiV32RequestBody>>? requestBodies,
  Map<String, OpenApiV32RefOr<OpenApiV32Header>>? headers,
  Map<String, OpenApiV32RefOr<OpenApiV32SecurityScheme>>? securitySchemes,
  Map<String, OpenApiV32RefOr<OpenApiV32Link>>? links,
  Map<String, OpenApiV32RefOr<OpenApiV32Callback>>? callbacks,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups reusable definitions by component type and name.
  this;

  /// Reusable media types indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32MediaType>>? mediaTypes =
      mediaTypes == null ? null : Map.unmodifiable(mediaTypes);

  /// Reusable schemas indexed by component name.
  final Map<String, OpenApiV32Schema>? schemas = schemas == null
      ? null
      : Map.unmodifiable(schemas);

  /// Reusable path items indexed by component name.
  final Map<String, OpenApiV32PathItem>? pathItems = pathItems == null
      ? null
      : Map.unmodifiable(pathItems);

  /// Reusable responses indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Response>>? responses =
      responses == null ? null : Map.unmodifiable(responses);

  /// Reusable parameters indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Parameter>>? parameters =
      parameters == null ? null : Map.unmodifiable(parameters);

  /// Reusable examples indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Example>>? examples =
      examples == null ? null : Map.unmodifiable(examples);

  /// Reusable request bodies indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32RequestBody>>? requestBodies =
      requestBodies == null ? null : Map.unmodifiable(requestBodies);

  /// Reusable headers indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Header>>? headers =
      headers == null ? null : Map.unmodifiable(headers);

  /// Reusable security schemes indexed by component name.
  final Map<String, OpenApiV32RefOr<OpenApiV32SecurityScheme>>?
  securitySchemes = securitySchemes == null
      ? null
      : Map.unmodifiable(securitySchemes);

  /// Links to related operations, indexed by name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Link>>? links = links == null
      ? null
      : Map.unmodifiable(links);

  /// Callback definitions indexed by name.
  final Map<String, OpenApiV32RefOr<OpenApiV32Callback>>? callbacks =
      callbacks == null ? null : Map.unmodifiable(callbacks);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    if (mediaTypes != null)
      'mediaTypes': {
        for (final entry in mediaTypes!.entries)
          entry.key: entry.value.toJson(),
      },
    if (pathItems != null)
      'pathItems': {
        for (final entry in pathItems!.entries) entry.key: entry.value.toJson(),
      },
    if (schemas != null)
      'schemas': schemas!.map((key, value) => MapEntry(key, value.toJson())),
    if (responses != null)
      'responses': responses!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (parameters != null)
      'parameters': parameters!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (examples != null)
      'examples': examples!.map((key, value) => MapEntry(key, value.toJson())),
    if (requestBodies != null)
      'requestBodies': requestBodies!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (headers != null)
      'headers': headers!.map((key, value) => MapEntry(key, value.toJson())),
    if (securitySchemes != null)
      'securitySchemes': securitySchemes!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (links != null)
      'links': links!.map((key, value) => MapEntry(key, value.toJson())),
    if (callbacks != null)
      'callbacks': callbacks!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
  };
}
