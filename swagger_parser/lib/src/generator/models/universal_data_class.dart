import 'all_of.dart';
import 'universal_type.dart';

/// Universal template for containing information about Rest component
class UniversalDataClass {
  const UniversalDataClass({
    required this.name,
    required this.imports,
    required this.parameters,
    this.allOf,
  });

  /// Name of the class
  final String name;

  /// List of additional references to components
  final Set<String> imports;

  /// List of class fields
  final List<UniversalType> parameters;

  /// Temp field for containing info about allOf for future processing
  final AllOf? allOf;
}
