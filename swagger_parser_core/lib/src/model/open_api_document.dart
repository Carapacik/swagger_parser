import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/model/v2/swagger_v2_objects.dart';
import 'package:swagger_parser_core/src/model/v3_0/open_api_v3_0_objects.dart';
import 'package:swagger_parser_core/src/model/v3_1/open_api_v3_1_objects.dart';
import 'package:swagger_parser_core/src/model/v3_2/open_api_v3_2_objects.dart';

part 'v3_0/open_api_v3_0_document.dart';
part 'v3_1/open_api_v3_1_document.dart';
part 'v3_2/open_api_v3_2_document.dart';

/// A parsed document that preserves its declared specification version.
sealed class const OpenApiDocument() {
  /// Initializes a concrete subtype.
  this;

  /// The specification family and exact version in the source.
  OpenApiVersion get version;

  /// Returns a detached JSON representation.
  Map<String, Object?> toJson();
}

/// Root of the Swagger 2.0 document tree.
final class SwaggerV2Document({
  /// Title, API version, and publication details.
  required final SwaggerV2Info info,

  /// Operations indexed by relative API path.
  required final SwaggerV2Paths paths,

  /// Host name and optional port for API requests.
  final String? host,

  /// Path prefix for all API operations.
  final String? basePath,
  List<String>? schemes,
  List<String>? consumes,
  List<String>? produces,
  Map<String, SwaggerV2Schema>? definitions,
  Map<String, SwaggerV2Parameter>? parameters,
  Map<String, SwaggerV2Response>? responses,
  Map<String, SwaggerV2SecurityScheme>? securityDefinitions,
  List<SwaggerV2SecurityRequirement>? security,
  List<SwaggerV2Tag>? tags,

  /// A link to related documentation.
  final SwaggerV2ExternalDocumentation? externalDocs,
  Map<String, JsonValue> extensions = const {},
  Map<String, JsonValue> extraFields = const {},
}) extends OpenApiDocument with SwaggerV2Object {
  /// Copies the root fields into an immutable Swagger 2.0 document.
  this;

  /// Transport schemes, such as `https`.
  final List<String>? schemes = schemes == null
      ? null
      : List.unmodifiable(schemes);

  /// Media types accepted in request bodies.
  final List<String>? consumes = consumes == null
      ? null
      : List.unmodifiable(consumes);

  /// Media types available in responses.
  final List<String>? produces = produces == null
      ? null
      : List.unmodifiable(produces);

  /// Reusable schemas indexed by name.
  final Map<String, SwaggerV2Schema>? definitions = definitions == null
      ? null
      : Map.unmodifiable(definitions);

  /// Reusable parameters indexed by name.
  final Map<String, SwaggerV2Parameter>? parameters = parameters == null
      ? null
      : Map.unmodifiable(parameters);

  /// Reusable responses indexed by name.
  final Map<String, SwaggerV2Response>? responses = responses == null
      ? null
      : Map.unmodifiable(responses);

  /// Reusable security schemes indexed by name.
  final Map<String, SwaggerV2SecurityScheme>? securityDefinitions =
      securityDefinitions == null
      ? null
      : Map.unmodifiable(securityDefinitions);

  /// Default security requirements for operations.
  final List<SwaggerV2SecurityRequirement>? security = security == null
      ? null
      : List.unmodifiable(security);

  /// Tag definitions in the author's display order.
  final List<SwaggerV2Tag>? tags = tags == null
      ? null
      : List.unmodifiable(tags);

  @override
  final Map<String, JsonValue> extensions = Map.unmodifiable(extensions);
  @override
  final Map<String, JsonValue> extraFields = Map.unmodifiable(extraFields);
  @override
  OpenApiVersion get version =>
      const OpenApiVersion(family: OpenApiFamily.swaggerV2, value: '2.0');

  @override
  Map<String, Object?> toJson() => {
    ...extraToJson(),
    'swagger': '2.0',
    'info': info.toJson(),
    'paths': paths.toJson(),
    'host': ?host,
    'basePath': ?basePath,
    if (schemes != null) 'schemes': schemes!.map((value) => value).toList(),
    if (consumes != null) 'consumes': consumes!.map((value) => value).toList(),
    if (produces != null) 'produces': produces!.map((value) => value).toList(),
    if (definitions != null)
      'definitions': definitions!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (parameters != null)
      'parameters': parameters!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (responses != null)
      'responses': responses!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (securityDefinitions != null)
      'securityDefinitions': securityDefinitions!.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    if (security != null)
      'security': security!.map((value) => value.toJson()).toList(),
    if (tags != null) 'tags': tags!.map((value) => value.toJson()).toList(),
    if (externalDocs != null) 'externalDocs': externalDocs!.toJson(),
  };
}
