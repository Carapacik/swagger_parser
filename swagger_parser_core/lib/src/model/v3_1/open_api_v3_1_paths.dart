part of 'open_api_v3_1_objects.dart';

/// Operations and shared parameters for one path.
final class OpenApiV31PathItem({
  /// The URI reference from `$ref`.
  final String? ref,

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// The GET operation for this path.
  final OpenApiV31Operation? get,

  /// The PUT operation for this path.
  final OpenApiV31Operation? put,

  /// The POST operation for this path.
  final OpenApiV31Operation? post,

  /// The DELETE operation for this path.
  final OpenApiV31Operation? delete,

  /// The OPTIONS operation for this path.
  final OpenApiV31Operation? options,

  /// The HEAD operation for this path.
  final OpenApiV31Operation? head,

  /// The PATCH operation for this path.
  final OpenApiV31Operation? patch,

  /// The TRACE operation for this path.
  final OpenApiV31Operation? trace,
  List<OpenApiV31Server>? servers,
  List<OpenApiV31RefOr<OpenApiV31Parameter>>? parameters,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups operations and shared parameters for one path.
  this;

  /// Base URLs for API calls in this scope.
  final List<OpenApiV31Server>? servers = servers == null
      ? null
      : List.unmodifiable(servers);

  /// Parameters shared by operations on this path.
  final List<OpenApiV31RefOr<OpenApiV31Parameter>>? parameters =
      parameters == null ? null : List.unmodifiable(parameters);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
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
final class OpenApiV31Operation({
  /// Possible results of the operation, indexed by response key.
  final OpenApiV31Responses? responses,
  List<String>? tags,

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// A link to related documentation.
  final OpenApiV31ExternalDocumentation? externalDocs,

  /// Identifier used to refer to an operation.
  final String? operationId,
  List<OpenApiV31RefOr<OpenApiV31Parameter>>? parameters,

  /// The body accepted by this operation.
  final OpenApiV31RefOr<OpenApiV31RequestBody>? requestBody,
  Map<String, OpenApiV31RefOr<OpenApiV31Callback>>? callbacks,

  /// Whether the author discourages new uses.
  final bool? deprecated,
  List<OpenApiV31SecurityRequirement>? security,
  List<OpenApiV31Server>? servers,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups request metadata and responses for one HTTP method.
  this;

  /// Names of the tags assigned to this operation.
  final List<String>? tags = tags == null ? null : List.unmodifiable(tags);

  /// Operation parameters that extend or override path parameters.
  final List<OpenApiV31RefOr<OpenApiV31Parameter>>? parameters =
      parameters == null ? null : List.unmodifiable(parameters);

  /// Callback definitions indexed by name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Callback>>? callbacks =
      callbacks == null ? null : Map.unmodifiable(callbacks);

  /// Operation-level alternatives that override document security.
  final List<OpenApiV31SecurityRequirement>? security = security == null
      ? null
      : List.unmodifiable(security);

  /// Base URLs for API calls in this scope.
  final List<OpenApiV31Server>? servers = servers == null
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
final class OpenApiV31Components({
  Map<String, OpenApiV31Schema>? schemas,
  Map<String, OpenApiV31PathItem>? pathItems,
  Map<String, OpenApiV31RefOr<OpenApiV31Response>>? responses,
  Map<String, OpenApiV31RefOr<OpenApiV31Parameter>>? parameters,
  Map<String, OpenApiV31RefOr<OpenApiV31Example>>? examples,
  Map<String, OpenApiV31RefOr<OpenApiV31RequestBody>>? requestBodies,
  Map<String, OpenApiV31RefOr<OpenApiV31Header>>? headers,
  Map<String, OpenApiV31RefOr<OpenApiV31SecurityScheme>>? securitySchemes,
  Map<String, OpenApiV31RefOr<OpenApiV31Link>>? links,
  Map<String, OpenApiV31RefOr<OpenApiV31Callback>>? callbacks,
  super.extensions,
  super.extraFields,
}) extends _FixedObject {
  /// Groups reusable definitions by component type and name.
  this;

  /// Reusable schemas indexed by component name.
  final Map<String, OpenApiV31Schema>? schemas = schemas == null
      ? null
      : Map.unmodifiable(schemas);

  /// Reusable path items indexed by component name.
  final Map<String, OpenApiV31PathItem>? pathItems = pathItems == null
      ? null
      : Map.unmodifiable(pathItems);

  /// Reusable responses indexed by component name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Response>>? responses =
      responses == null ? null : Map.unmodifiable(responses);

  /// Reusable parameters indexed by component name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Parameter>>? parameters =
      parameters == null ? null : Map.unmodifiable(parameters);

  /// Reusable examples indexed by component name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Example>>? examples =
      examples == null ? null : Map.unmodifiable(examples);

  /// Reusable request bodies indexed by component name.
  final Map<String, OpenApiV31RefOr<OpenApiV31RequestBody>>? requestBodies =
      requestBodies == null ? null : Map.unmodifiable(requestBodies);

  /// Reusable headers indexed by component name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Header>>? headers =
      headers == null ? null : Map.unmodifiable(headers);

  /// Reusable security schemes indexed by component name.
  final Map<String, OpenApiV31RefOr<OpenApiV31SecurityScheme>>?
  securitySchemes = securitySchemes == null
      ? null
      : Map.unmodifiable(securitySchemes);

  /// Links to related operations, indexed by name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Link>>? links = links == null
      ? null
      : Map.unmodifiable(links);

  /// Callback definitions indexed by name.
  final Map<String, OpenApiV31RefOr<OpenApiV31Callback>>? callbacks =
      callbacks == null ? null : Map.unmodifiable(callbacks);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
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
