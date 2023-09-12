import 'package:collection/collection.dart';

import 'all_of.dart';
import 'universal_data_class.dart';
import 'universal_type.dart';

/// Universal template for containing information about component
class UniversalComponentClass extends UniversalDataClass {
  const UniversalComponentClass({
    required super.name,
    required this.imports,
    required this.parameters,
    this.allOf,
    this.typeDef = false,
    super.description,
  });

  /// List of additional references to components
  final Set<String> imports;

  /// List of class fields
  final List<UniversalType> parameters;

  /// Temp field for containing info about `allOf` for future processing
  final AllOf? allOf;

  /// Whether or not this schema is a basic type
  /// "Date": {
  ///   "type": "string",
  ///   "format": "date"
  /// }
  ///  must be DateTime instead of its own class
  final bool typeDef;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalComponentClass &&
          runtimeType == other.runtimeType &&
          const DeepCollectionEquality().equals(imports, other.imports) &&
          const DeepCollectionEquality().equals(parameters, other.parameters) &&
          allOf == other.allOf &&
          typeDef == other.typeDef;

  @override
  int get hashCode =>
      imports.hashCode ^
      parameters.hashCode ^
      allOf.hashCode ^
      typeDef.hashCode;
}
