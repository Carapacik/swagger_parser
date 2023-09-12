import 'package:collection/collection.dart';

import 'universal_type.dart';

/// Used for processing allOf in components
class AllOf {
  const AllOf({required this.refs, required this.properties});

  /// List of references to other components
  final List<String> refs;

  /// List of additional properties
  final List<UniversalType> properties;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AllOf &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(refs, other.refs) &&
          const DeepCollectionEquality().equals(properties, other.properties);

  @override
  int get hashCode => refs.hashCode ^ properties.hashCode;
}
