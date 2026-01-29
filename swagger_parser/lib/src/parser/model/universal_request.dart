import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:swagger_parser/src/parser/model/universal_request_type.dart';
import 'package:swagger_parser/src/parser/model/universal_type.dart';

/// Universal template for containing information about Request
@immutable
final class UniversalRequest {
  /// Constructor for [UniversalRequest]
  const UniversalRequest({
    required this.name,
    required this.requestType,
    required this.route,
    required this.returnType,
    required this.parameters,
    this.tags = const [],
    this.operationId,
    this.externalDocsUrl,
    this.contentType = 'application/json',
    this.description,
    this.isDeprecated = false,
    this.configExtension = const UniversalRequestConfigExtension(),
  });

  /// Request name
  final String name;

  /// Request description
  final String? description;

  /// Original OpenAPI tags
  final List<String> tags;

  /// Original OpenAPI operationId
  final String? operationId;

  /// Optional OpenAPI externalDocs url
  final String? externalDocsUrl;

  /// HTTP type of request
  final HttpRequestType requestType;

  /// Request route
  final String route;

  /// Request return type
  final UniversalType? returnType;

  /// Request parameters
  final List<UniversalRequestType> parameters;

  /// Request content-type
  final String contentType;

  /// Request has Content-Type 'multipart/form-data'
  bool get isMultiPart => contentType == 'multipart/form-data';

  /// Request type 'application/x-www-form-urlencoded'
  bool get isFormUrlEncoded =>
      contentType == 'application/x-www-form-urlencoded';

  /// Value indicating whether this request is deprecated
  final bool isDeprecated;

  final UniversalRequestConfigExtension configExtension;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalRequest &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          requestType == other.requestType &&
          contentType == other.contentType &&
          route == other.route &&
          returnType == other.returnType &&
          const DeepCollectionEquality().equals(tags, other.tags) &&
          operationId == other.operationId &&
          externalDocsUrl == other.externalDocsUrl &&
          const DeepCollectionEquality().equals(parameters, other.parameters) &&
          isMultiPart == other.isMultiPart &&
          isFormUrlEncoded == other.isFormUrlEncoded;

  @override
  int get hashCode =>
      name.hashCode ^
      requestType.hashCode ^
      route.hashCode ^
      returnType.hashCode ^
      tags.hashCode ^
      operationId.hashCode ^
      externalDocsUrl.hashCode ^
      contentType.hashCode ^
      parameters.hashCode ^
      isMultiPart.hashCode ^
      isFormUrlEncoded.hashCode;

  @override
  String toString() => 'UniversalRequest(name: $name, '
      'tags: $tags, '
      'operationId: $operationId, '
      'externalDocsUrl: $externalDocsUrl, '
      'requestType: $requestType, '
      'route: $route, '
      'parameters: $parameters, '
      'contentType: $contentType)';
}

/// Request type
enum HttpRequestType {
  /// GET
  get,

  /// POST
  post,

  /// HEAD
  head,

  /// PUT
  put,

  /// DELETE
  delete,

  /// PATCH
  patch,

  /// CONNECT
  connect,

  /// OPTIONS
  options,

  /// TRACE
  trace;

  /// Constructor for [HttpRequestType]
  const HttpRequestType();

  /// Get type from string
  static HttpRequestType? fromString(String type) =>
      HttpRequestType.values.firstWhereOrNull((e) => e.name == type);
}

@immutable
final class UniversalRequestConfigExtension {
  const UniversalRequestConfigExtension({
    bool? isCancelable,
  }) : isCancelable = isCancelable ?? false;

  factory UniversalRequestConfigExtension.parse(
    Map<String, dynamic> requestConfig,
  ) {
    final xDart = requestConfig[_xDartSection] as Map<String, dynamic>?;
    return UniversalRequestConfigExtension(
      isCancelable: bool.tryParse(xDart?[_isCancelableKey]?.toString() ?? ''),
    );
  }

  static const _xDartSection = 'x-dart';

  /// Whether or not the request should be cancelable.
  ///
  /// True if the `cancelable` flag in the `x-dart` section has been set to
  /// `true` for the specific request.
  ///
  /// ## Example
  ///
  /// ```yaml
  /// paths:
  ///   /path/variant4:
  ///     get:
  ///       x-dart:
  ///         cancelable: true
  ///       tags:
  ///         - sse
  ///       responses:
  ///         200:
  ///           content:
  ///             application/octect-stream:
  ///               schema:
  ///                 type: integer
  ///                 format: binary
  /// ```
  final bool isCancelable;
  static const _isCancelableKey = 'cancelable';

  @override
  int get hashCode => isCancelable.hashCode;

  @override
  bool operator ==(Object other) =>
      other is UniversalRequestConfigExtension &&
      other.isCancelable == isCancelable;

  @override
  String toString() => 'UniversalRequestConfigExtension('
      'isCancelable: $isCancelable'
      ')';
}
