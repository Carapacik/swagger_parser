import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:swagger_parser/src/parser/model/universal_request.dart';

/// Universal template for containing information about Rest client
@immutable
final class UniversalRestClient {
  /// Constructor for [UniversalRestClient]
  const UniversalRestClient({
    required this.name,
    required this.imports,
    required this.requests,
  });

  /// Client name
  final String name;

  ///List of imports
  final Set<String> imports;

  /// List of requests
  final List<UniversalRequest> requests;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalRestClient &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          const DeepCollectionEquality().equals(imports, other.imports) &&
          const DeepCollectionEquality().equals(requests, other.requests);

  @override
  int get hashCode => name.hashCode ^ imports.hashCode ^ requests.hashCode;

  @override
  String toString() => 'UniversalRestClient(name: $name, requests: $requests)';
}
