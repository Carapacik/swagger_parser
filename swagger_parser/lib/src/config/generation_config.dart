import 'package:swagger_parser/src/config/naming_config.dart';
import 'package:swagger_parser/src/config/operation_filter_config.dart';
import 'package:swagger_parser/src/config/parameter_exclusion.dart';
import 'package:swagger_parser/src/config/type_mapping.dart';

/// Selects the generated HTTP client implementation.
enum HttpClientBackend() {
  /// Use Retrofit annotations and Dio fallbacks.
  retrofit,

  /// Generate concrete clients that call Dio directly.
  dio,

  /// Generate clients that use package:http.
  http,
}

/// Selects the generated DTO codec.
enum DtoSerializer() {
  /// Generate standalone Dart codecs.
  plain,

  /// Build codecs with json_serializable.
  jsonSerializable,

  /// Build Freezed value classes and JSON codecs.
  freezed,

  /// Build dart_mappable mappers.
  dartMappable,
}

/// Selects the HTTP response API.
enum ResponseMode() {
  /// Return the payload for the lowest declared exact 2xx status.
  firstSuccess,

  /// Return a sealed variant for each declared response.
  allStatuses,
}

/// Selects public operation metadata and request attachment.
enum ApiMetadataMode() {
  /// Omit operation metadata files and the facade operation list.
  none,

  /// Generate operation constants without attaching them to requests.
  generate,

  /// Generate constants and attach them to request extras.
  generateAndAttach,
}

/// Handles unknown enum values or discriminator tags.
enum UnknownValueMode() {
  /// Reject unknown values. This is the default.
  reject,

  /// Preserve the original scalar or JSON object.
  preserve,
}

/// Generation options for generated Dart source.
final class const GenerationConfig({
  /// Public facade class. Its snake_case name sets the entry filename.
  final String rootApiClassName = 'Api',

  /// Full class name for untagged operations. Defaults to ApiClient.
  final String fallbackClientName = 'ApiClient',

  /// Suffix before .dart in internal files. Defaults to an empty string.
  /// Public entry and exports filenames stay unchanged.
  final String fileSuffix = '',

  /// Selects operation metadata output. Defaults to none.
  /// The API title and versions remain available in all modes.
  final ApiMetadataMode apiMetadata = ApiMetadataMode.none,

  /// Generated name replacements and casing.
  final NamingConfig naming = const NamingConfig(),

  /// Uses HTTP methods and paths instead of operationId. Defaults to false.
  /// Name replacements and collision checks still apply.
  final bool usePathForMethodNames = false,

  /// Outbound operation selection. Includes all operations by default.
  final OperationFilterConfig operationFilters = const OperationFilterConfig(),

  /// Parameter exclusion rules. Empty by default. Path exclusions fail.
  final List<ParameterExclusion> excludeParameters = const [],

  /// Retains only client dependencies and [keepModels]. Defaults to false.
  final bool pruneUnusedModels = false,

  /// Local named schema references retained with their dependencies.
  /// Unknown references fail. Empty by default.
  final List<String> keepModels = const [],

  /// Scalar and object replacements. Empty by default.
  final List<TypeMapping> typeMappings = const [],

  /// Preferred line width for formatted Dart source.
  final int pageWidth = 80,

  /// Codec for generated DTOs.
  final DtoSerializer serializer = DtoSerializer.plain,

  /// Unknown enum values. Defaults to [UnknownValueMode.reject].
  final UnknownValueMode unknownEnumValues = UnknownValueMode.reject,

  /// Unknown discriminator tags. Defaults to [UnknownValueMode.reject].
  final UnknownValueMode unknownDiscriminatorValues = UnknownValueMode.reject,

  /// Copy schema and operation text to Dartdoc. Defaults to true.
  /// Deprecation annotations do not depend on this option.
  final bool generateDocs = true,

  /// Return binary responses as a stream of byte chunks.
  final bool streamBinaryResponses = false,

  /// Decodes buffered JSON responses in an isolate on VM. Defaults to false.
  /// Web runs inline. Streams keep their existing decoding path.
  final bool decodeResponsesInBackground = false,

  /// Make required whole-body arguments positional. Defaults to false.
  /// Optional bodies and individual form fields stay named.
  final bool bodyPositional = false,

  /// Wraps first-success payloads with transport metadata. Defaults to false.
  /// Has no effect in all-status mode.
  final bool originalHttpResponse = false,

  /// Applies constant defaults to optional HTTP arguments. Defaults to false.
  /// Required arguments, whole bodies, and DTO defaults are unchanged.
  final bool applyParameterDefaults = false,

  /// Infers non-nullable fields without defaults when required is absent.
  /// Defaults to true. Explicit required lists, including empty lists, win.
  final bool inferMissingRequired = true,

  /// Generates explicit DTO validation with field paths. Defaults to false.
  /// Unsupported assertions fail generation. Encoding errors propagate.
  final bool generateValidators = false,

  /// Uses records for optional nullable fields without defaults.
  /// Defaults to false. Records distinguish absent fields from explicit null.
  final bool usePresenceRecords = false,

  /// HTTP client backend. Defaults to [HttpClientBackend.retrofit].
  final HttpClientBackend httpClient = HttpClientBackend.retrofit,

  /// HTTP response API. Defaults to [ResponseMode.firstSuccess].
  final ResponseMode responseMode = ResponseMode.firstSuccess,
}) {
  /// Configures the output libraries.
  this;
}
