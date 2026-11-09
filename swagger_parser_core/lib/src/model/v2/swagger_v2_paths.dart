part of 'swagger_v2_objects.dart';

/// The request and possible responses for one HTTP method.
final class SwaggerV2Operation({
  /// Possible results of the operation, indexed by response key.
  required final SwaggerV2Responses responses,
  List<String>? tags,

  /// Short description supplied by the document author.
  final String? summary,

  /// Description supplied by the document author.
  final String? description,

  /// A link to related documentation.
  final SwaggerV2ExternalDocumentation? externalDocs,

  /// Identifier used to refer to an operation.
  final String? operationId,
  List<String>? consumes,
  List<String>? produces,
  List<SwaggerV2RefOr<SwaggerV2Parameter>>? parameters,
  List<String>? schemes,

  /// Whether the author discourages new uses.
  final bool? deprecated,
  List<SwaggerV2SecurityRequirement>? security,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Groups request metadata and responses for one HTTP method.
  this;

  /// Names of the tags assigned to this operation.
  final List<String>? tags = tags == null ? null : List.unmodifiable(tags);

  /// Media types accepted in request bodies.
  final List<String>? consumes = consumes == null
      ? null
      : List.unmodifiable(consumes);

  /// Media types available in responses.
  final List<String>? produces = produces == null
      ? null
      : List.unmodifiable(produces);

  /// Operation parameters that extend or override path parameters.
  final List<SwaggerV2RefOr<SwaggerV2Parameter>>? parameters =
      parameters == null ? null : List.unmodifiable(parameters);

  /// Transport schemes, such as `https`.
  final List<String>? schemes = schemes == null
      ? null
      : List.unmodifiable(schemes);

  /// Operation-level alternatives that override document security.
  final List<SwaggerV2SecurityRequirement>? security = security == null
      ? null
      : List.unmodifiable(security);
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'responses': responses.toJson(),
    if (tags != null) 'tags': tags!.map((value) => value).toList(),
    'summary': ?summary,
    'description': ?description,
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
    'operationId': ?operationId,
    if (consumes != null) 'consumes': consumes!.map((value) => value).toList(),
    if (produces != null) 'produces': produces!.map((value) => value).toList(),
    if (parameters != null)
      'parameters': parameters!.map((value) => value.toJson()).toList(),
    if (schemes != null) 'schemes': schemes!.map((value) => value).toList(),
    'deprecated': ?deprecated,
    if (security != null)
      'security': security!.map((value) => value.toJson()).toList(),
  };
}

/// Operations and shared parameters for one path.
final class SwaggerV2PathItem({
  /// The URI reference from `$ref`.
  final String? ref,

  /// The GET operation for this path.
  final SwaggerV2Operation? get,

  /// The PUT operation for this path.
  final SwaggerV2Operation? put,

  /// The POST operation for this path.
  final SwaggerV2Operation? post,

  /// The DELETE operation for this path.
  final SwaggerV2Operation? delete,

  /// The OPTIONS operation for this path.
  final SwaggerV2Operation? options,

  /// The HEAD operation for this path.
  final SwaggerV2Operation? head,

  /// The PATCH operation for this path.
  final SwaggerV2Operation? patch,
  List<SwaggerV2RefOr<SwaggerV2Parameter>>? parameters,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Groups operations and shared parameters for one path.
  this;

  /// Parameters shared by operations on this path.
  final List<SwaggerV2RefOr<SwaggerV2Parameter>>? parameters =
      parameters == null ? null : List.unmodifiable(parameters);
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    r'$ref': ?ref,
    if (get != null) 'get': get!.toJson(),
    if (put != null) 'put': put!.toJson(),
    if (post != null) 'post': post!.toJson(),
    if (delete != null) 'delete': delete!.toJson(),
    if (options != null) 'options': options!.toJson(),
    if (head != null) 'head': head!.toJson(),
    if (patch != null) 'patch': patch!.toJson(),
    if (parameters != null)
      'parameters': parameters!.map((value) => value.toJson()).toList(),
  };
}

/// Path items indexed by relative API path.
final class SwaggerV2Paths({
  required Map<String, SwaggerV2PathItem> entries,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) with SwaggerV2Object {
  /// Indexes path items by their relative paths.
  this;

  /// Path items indexed by their relative paths.
  final Map<String, SwaggerV2PathItem> entries = Map.unmodifiable(entries);

  /// Returns the entry for the given key, or null if absent.
  SwaggerV2PathItem? operator [](String key) => entries[key];
  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    ...entries.map((key, value) => MapEntry(key, value.toJson())),
  };
}
