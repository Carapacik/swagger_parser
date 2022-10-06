import 'universal_type.dart';

/// Used for processing allOf in components
class AllOf {
  const AllOf({required this.refs, required this.properties});

  /// List of references to other components
  final List<String> refs;

  /// List of additional properties
  final List<UniversalType> properties;
}
