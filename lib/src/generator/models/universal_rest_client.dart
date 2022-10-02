import 'package:swagger_parser/src/generator/models/universal_request.dart';

/// Universal template for containing information about Rest client
class UniversalRestClient {
  UniversalRestClient({
    required this.name,
    required this.requests,
    required this.imports,
  });

  final String name;
  final List<UniversalRequest> requests;
  final Set<String> imports;
}
