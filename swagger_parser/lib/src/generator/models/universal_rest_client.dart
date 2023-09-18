import 'universal_request.dart';

/// Universal template for containing information about Rest client
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
}
