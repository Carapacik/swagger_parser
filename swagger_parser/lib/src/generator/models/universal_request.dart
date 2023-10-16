import 'package:collection/collection.dart';

import 'universal_request_type.dart';
import 'universal_type.dart';

/// Universal template for containing information about Request
final class UniversalRequest {
  /// Constructor for [UniversalRequest]
  const UniversalRequest({
    required this.name,
    required this.requestType,
    required this.route,
    required this.returnType,
    required this.parameters,
    final HttpContentType? contentType,
    this.description,
    this.isDeprecated = false,
  }) : contentType = contentType ?? HttpContentType.applicationJson;

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

  final HttpContentType contentType;

  /// Request has Content-Type 'multipart/form-data'
  bool get isMultiPart => contentType.isMultipart;

  /// Request type 'application/x-www-form-urlencoded'
  bool get isFormUrlEncoded =>
      contentType == HttpContentType.applicationXWwwFormUrlencoded;

  /// if is application/json or multipart/form-data or application/x-www-form-urlencoded do not add header
  bool get shouldAddContentTypeHeader =>
      !(contentType == HttpContentType.applicationJson ||
          isMultiPart ||
          isFormUrlEncoded);

  /// Value indicating whether this request is deprecated
  final bool isDeprecated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalRequest &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          requestType == other.requestType &&
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
      parameters.hashCode ^
      isMultiPart.hashCode ^
      isFormUrlEncoded.hashCode;
}

/// Request type
enum HttpRequestType {
  /// {@nodoc}
  get,

  /// {@nodoc}
  post,

  /// {@nodoc}
  head,

  /// {@nodoc}
  put,

  /// {@nodoc}
  delete,

  /// {@nodoc}
  patch,

  /// {@nodoc}
  connect,

  /// {@nodoc}
  options,

  /// {@nodoc}
  trace;

  /// Constructor for [HttpRequestType]
  const HttpRequestType();

  /// Get type from string
  static HttpRequestType? fromString(String type) =>
      HttpRequestType.values.firstWhereOrNull((e) => e.name == type);
}

/// Content-Type header of request
enum HttpContentType {
  applicationOctetStream('application/octet-stream'),
  applicationJson('application/json'),
  applicationXml('application/xml'),
  applicationJsonPatch('application/json-patch+json'),
  applicationXWwwFormUrlencoded('application/x-www-form-urlencoded'),
  applicationPdf('application/pdf'),
  multipartFormData('multipart/form-data'),
  imageGif('image/gif'),
  imageJpeg('image/jpeg'),
  imagePng('image/png'),
  textPlain('text/plain'),
  textXml('text/xml'),
  textHtml('text/html');

  const HttpContentType(this.value);

  /// The Content-Type value, e.g. "application/json".
  final String value;

  static HttpContentType? fromString(String? type) =>
      HttpContentType.values.firstWhereOrNull(
        (e) => e.value == type,
      );

  bool get isApplication => value.startsWith('application/');

  bool get isMultipart => value.startsWith('multipart/');

  bool get isText => value.startsWith('text/');

  bool get isImage => value.startsWith('image/');
}
