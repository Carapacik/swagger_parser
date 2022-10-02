import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/models/universal_request_type.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';

/// Universal template for containing information about Request
class UniversalRequest {
  UniversalRequest({
    required this.name,
    required this.requestType,
    required this.route,
    required this.returnType,
    required this.parameters,
    this.isMultiPart = false,
  });

  final String name;
  final HTTPRequestType requestType;
  final String route;
  final UniversalType? returnType;
  final List<UniversalRequestType> parameters;
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
