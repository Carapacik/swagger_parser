part of 'universal_data_class.dart';

/// Universal template for containing information about component
final class UniversalComponentClass extends UniversalDataClass {
  /// Constructor for [UniversalComponentClass]
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
  final ({List<String> refs, List<UniversalType> properties})? allOf;

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

  @override
  String toString() =>
      'UniversalComponentClass(\nimports: $imports,\nparameters: $parameters,\nallOf: $allOf,\ntypeDef: $typeDef\n)';
}
