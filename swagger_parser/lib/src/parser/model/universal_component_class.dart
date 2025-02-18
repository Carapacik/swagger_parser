part of 'universal_data_class.dart';

/// Universal template for containing information about component
@immutable
final class UniversalComponentClass extends UniversalDataClass {
  /// Constructor for [UniversalComponentClass]
  const UniversalComponentClass({
    required super.name,
    required this.imports,
    required this.parameters,
    this.allOf,
    this.typeDef = false,
    this.discriminator,
    super.description,
  });

  /// List of additional references to components
  final Set<String> imports;

  /// List of class fields
  final List<UniversalType> parameters;

  /// Temp field for containing info about `allOf` for future processing
  final ({List<String> refs, List<UniversalType> properties})? allOf;

  /// When using a discriminated oneOf, this contains the information about the property name, the mapping of the ref to the property name, and the properties of each of the oneOf variants
  final ({
    // The name of the property that is used to discriminate the oneOf variants
    String propertyName,

    // The mapping of the property value to the ref
    Map<String, String> discriminatorValueToRefMapping,

    // The list of properties stored for each ref
    Map<String, List<UniversalType>> refProperties,
  })? discriminator;

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
  String toString() => 'UniversalComponentClass(imports: $imports, '
      'parameters: $parameters, '
      'allOf: $allOf, '
      'typeDef: $typeDef)';
}
