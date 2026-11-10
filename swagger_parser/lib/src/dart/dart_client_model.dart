part of 'dart_generation_model.dart';

/// Payload codecs for generated clients.
enum DartHttpMedia() {
  /// A JSON value.
  json,

  /// A UTF-8 text body.
  text,

  /// An event stream.
  events,

  /// One JSON value per line.
  jsonLines,

  /// A form data set.
  form,

  /// A multipart form.
  multipart,

  /// Uninterpreted bytes.
  bytes;

  /// Selects a codec from the media type without its parameters.
  static DartHttpMedia parse(String? value) {
    final String mime = value?.split(';').first.trim().toLowerCase() ?? '';
    return switch (mime) {
      'application/json' => json,
      'text/event-stream' => events,
      'application/jsonl' ||
      'application/jsonlines' ||
      'application/x-ndjson' ||
      'application/ndjson' => jsonLines,
      'application/x-www-form-urlencoded' => form,
      'multipart/form-data' => multipart,
      _ when mime.endsWith('+json') => json,
      _ when mime.startsWith('text/') => text,
      _ => bytes,
    };
  }
}

/// One outbound HTTP method.
final class DartClientOperation({
  /// Public Dart method name.
  required final String name,

  /// HTTP method.
  required final String method,

  /// Mounted OpenAPI path template.
  required final String path,

  /// Selected success status in first-success mode, if present.
  required final int? status,

  /// Selected payload type. Bodyless statuses do not change its codec.
  required final DartTypeReference response,

  /// Whether the factory accepts a JSON object.
  required final bool objectResponse,
  required Iterable<DartClientParameter> parameters,

  /// Operation ID declared in the source, or null when absent.
  final String? operationId,

  /// Original operation tags.
  final List<String> tags = const [],

  /// External documentation URL declared on the operation.
  final String? externalDocsUrl,

  /// Operation description for Dartdoc.
  final String? description,

  /// Operation summary for Dartdoc.
  final String? summary,

  /// Whether the source operation is deprecated.
  final bool deprecated = false,

  /// Request payload.
  final DartClientBody? body,

  /// Media type of the selected success response.
  final String mediaType = 'application/json',

  /// Effective server and security settings for Dio interceptors.
  final Map<String, Object?> extra = const {},

  /// DTOs with a JSON object factory.
  final Set<String> objectTypes = const {},
  Map<String, DartStatusVariant> variants = const {},
  Iterable<int> emptySuccessStatuses = const [],
}) {
  /// Copies parameters in declaration order.
  this;

  /// Result variants for status-specific responses.
  final Map<String, DartStatusVariant> variants = Map.unmodifiable(variants);

  /// Declared exact 2xx statuses without content in first-success mode.
  /// Empty by default. Buffered methods return null for these statuses.
  /// Streaming methods return an empty stream.
  final List<int> emptySuccessStatuses = List.unmodifiable(
    emptySuccessStatuses,
  );

  /// Public result type before Future or transport-response wrapping.
  /// Buffered payloads become nullable when a success status has no content.
  DartTypeReference get returnType =>
      emptySuccessStatuses.isEmpty ||
          response.isNullable ||
          const {'void', 'Null', 'Stream'}.contains(response.symbol)
      ? response
      : DartTypeReference(
          symbol: response.symbol,
          importUrl: response.importUrl,
          scalarCodec: response.scalarCodec,
          typeArguments: response.typeArguments,
          isNullable: true,
        );

  /// Path, query, and header parameters.
  final List<DartClientParameter> parameters = List.unmodifiable(parameters);
}

/// One HTTP status in a sealed result.
final class const DartStatusVariant(
  /// Generated class name.
  final String name,

  /// DTO type, or null for a response without content.
  final DartTypeReference? type, {

  /// Whether the DTO factory accepts a JSON object.
  required final bool objectPayload,

  /// Response media type.
  final String mediaType = 'application/json',
}) {
  /// Sets the class name and optional JSON payload.
  this;
}

/// A request body.
final class const DartClientBody({
  /// Argument type when the caller supplies the body.
  required final DartTypeReference type,

  /// Whether the request must include the body.
  required final bool isRequired,

  /// Whether the DTO encodes a JSON object.
  required final bool isObjectDto,

  /// Parameter documentation and deprecation.
  final DartDocumentation documentation = const DartDocumentation(),

  /// Request media type.
  final String mediaType = 'application/json',

  /// Named form fields in declaration order.
  final List<DartFormField> fields = const [],
}) {
  /// Records the Dart type and wire requirements.
  this;

  /// Whether omission and JSON null are both valid.
  bool get allowsAbsentAndNull =>
      DartHttpMedia.parse(mediaType) == DartHttpMedia.json &&
      !isRequired &&
      (type.isNullable || type.symbol == 'Null');
}

/// One form field.
typedef DartFormField = ({
  DartDocumentation documentation,
  String name,
  String key,
  DartTypeReference type,
  bool required,
  String? contentType,
  String? separator,
  bool file,
  DartArgumentDefault? defaultValue,
});

/// Wire location of an HTTP argument.
enum DartClientParameterLocation() {
  /// A path template argument.
  path,

  /// A query parameter.
  query,

  /// A request header.
  header,

  /// A Cookie header field.
  cookie,

  /// The complete encoded query string.
  querystring,
}

/// Expansion style for a path parameter.
enum DartPathStyle() {
  /// Insert the value into the template.
  simple,

  /// Prefix the value with a dot.
  label,

  /// Prefix the value with a semicolon and its wire name.
  matrix,
}

/// Wire format for a scalar query array.
enum DartQueryListFormat() {
  /// Repeat the parameter name for each item.
  multi,

  /// Separate items with a comma.
  csv,

  /// Separate items with a space.
  ssv,

  /// Separate items with a tab.
  tsv,

  /// Separate items with a pipe.
  pipes,
}

/// Property types of an object parameter.
enum DartParameterObjectShape() {
  /// All property types are scalar.
  flat,

  /// The schema allows properties of unknown type.
  open,
}

/// Property types of a deepObject query parameter.
typedef DartQueryObjectShape = DartParameterObjectShape;

/// A typed HTTP argument and its wire name.
final class const DartClientParameter.at({
  /// Dart parameter name.
  required final String name,

  /// Name in the HTTP request.
  required final String wireName,

  /// Argument type before optional parameter nullability.
  required final DartTypeReference type,

  /// Wire location.
  required final DartClientParameterLocation location,

  /// Whether callers must supply this argument.
  required final bool isRequired,

  /// Parameter documentation and deprecation.
  final DartDocumentation documentation = const DartDocumentation(),

  /// Optional constant default. Null preserves omission.
  final DartArgumentDefault? defaultValue,

  /// Style for path expansion.
  final DartPathStyle pathStyle = DartPathStyle.simple,
  final bool _explodePath = false,
  final bool? _explode,

  /// Separator for a path or header array.
  final String? listSeparator,

  /// Array format for this query parameter.
  final DartQueryListFormat? queryListFormat,

  /// Whether the caller supplies cookie-safe values.
  final bool rawCookie = false,

  /// Whether reserved characters can pass through percent encoding.
  final bool allowReserved = false,

  /// Media type for a content-based parameter.
  final String? contentType,

  /// Whether the declared scalar has a JSON codec.
  final bool scalarCodec = false,

  /// Whether a query object uses form serialization.
  final bool isFormQueryObject = false,
  final DartQueryObjectShape? _queryObjectShape,
  final DartParameterObjectShape? _objectShape,
}) {
  /// Creates a path or query argument.
  const new({
    required String name,
    required String wireName,
    required DartTypeReference type,
    required bool isPath,
    required bool isRequired,
  }) : this.at(
         name: name,
         wireName: wireName,
         type: type,
         isRequired: isRequired,
         location: isPath
             ? DartClientParameterLocation.path
             : DartClientParameterLocation.query,
       );

  /// Creates an argument at its wire location.
  this;

  /// Whether this argument replaces a path expression.
  bool get isPath => location == DartClientParameterLocation.path;

  /// Whether to expand each path array item separately.
  bool get explodePath => isPath && explode;

  /// Whether the style expands each property or array item separately.
  bool get explode => _explode ?? _explodePath;

  /// Shape of a deepObject query parameter.
  DartQueryObjectShape? get queryObjectShape =>
      location == DartClientParameterLocation.query && !isFormQueryObject
      ? objectShape
      : null;

  /// Property types for object serialization.
  DartParameterObjectShape? get objectShape =>
      _objectShape ?? _queryObjectShape;
}

/// A schema default and its constant Dart expression.
final class const DartArgumentDefault({
  /// Original JSON value, including an explicit null.
  required final JsonValue value,

  /// Source document for diagnostics. Null for an unnamed source.
  required final Uri? sourceUri,

  /// Schema pointer for diagnostics.
  required final String documentPath,

  /// Resolved constant expression. Null before default resolution.
  final String? expression,

  /// Referenced model symbols and imported constants.
  final Set<String> dependencies = const {},
}) {
  /// Records the default and its source.
  this;
}
