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
    this.contentType = 'application/json',
    this.description,
    this.isDeprecated = false,
  });

  /// Request name
  final String name;

  /// Request description
  final String? description;

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
          const DeepCollectionEquality().equals(parameters, other.parameters) &&
          isMultiPart == other.isMultiPart &&
          isFormUrlEncoded == other.isFormUrlEncoded;

  @override
  int get hashCode =>
      name.hashCode ^
      requestType.hashCode ^
      route.hashCode ^
      returnType.hashCode ^
      contentType.hashCode ^
      parameters.hashCode ^
      isMultiPart.hashCode ^
      isFormUrlEncoded.hashCode;

  @override
  String toString() => 'UniversalRequest(name: $name, '
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
