import 'package:collection/collection.dart';

import 'universal_request_type.dart';
import 'universal_type.dart';

/// Universal template for containing information about Request
class UniversalRequest {
  const UniversalRequest({
    required this.name,
    required this.requestType,
    required this.route,
    required this.returnType,
    required this.parameters,
    this.isMultiPart = false,
  });

  /// Request name
  final String name;

  /// HTTP type of request
  final HTTPRequestType requestType;

  /// Request route
  final String route;

  /// Request return type
  final UniversalType? returnType;

  /// Request parameters
  final List<UniversalRequestType> parameters;

  /// Whether or not request is multipart
  final bool isMultiPart;
}

enum HTTPRequestType {
  get,
  post,
  head,
  put,
  delete,
  patch,
  connect,
  options,
  trace;

  const HTTPRequestType();

  static HTTPRequestType? fromString(final String type) =>
      HTTPRequestType.values.firstWhereOrNull((e) => e.name == type);
}
