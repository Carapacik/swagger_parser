part of 'universal_data_class.dart';

typedef Discriminator = ({
// The name of the property that is used to discriminate the oneOf variants
  String propertyName,

// The mapping of the property value to the ref
  Map<String, String> discriminatorValueToRefMapping,

// The list of properties stored for each ref
  Map<String, List<UniversalType>> refProperties,
});

typedef DiscriminatorValue = ({
// The name of the property that is used to discriminate the oneOf variants
  String propertyValue,
  String parentClass,
});

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
    this.discriminatorValue,
    super.description,
  });

  /// List of additional references to components
  final Set<String> imports;

  /// The import of this class
  String get import => name.toPascal;

  /// List of class fields
  final List<UniversalType> parameters;

  /// Temp field for containing info about `allOf` for future processing
  final ({List<String> refs, List<UniversalType> properties})? allOf;

  /// When using a discriminated oneOf, this contains the information about the property name, the mapping of the ref to the property name, and the properties of each of the oneOf variants
  final Discriminator? discriminator;

  /// When using a discriminated oneOf, where this class is one of the discriminated values, this field contains the information about the parent
  final DiscriminatorValue? discriminatorValue;

  /// Whether or not this schema is a basic type
  /// "Date": {
  ///   "type": "string",
  ///   "format": "date"
  /// }
  ///  must be DateTime instead of its own class
  final bool typeDef;

  /// Creates a copy of this [UniversalComponentClass] but with the given fields replaced with the new values.
  UniversalComponentClass copyWith({
    String? name,
    Set<String>? imports,
    List<UniversalType>? parameters,
    ({List<String> refs, List<UniversalType> properties})? allOf,
    bool? typeDef,
    Discriminator? discriminator,
    DiscriminatorValue? discriminatorValue,
    String? description,
  }) {
    return UniversalComponentClass(
      name: name ?? super.name,
      imports: imports ?? this.imports,
      parameters: parameters ?? this.parameters,
      allOf: allOf ?? this.allOf,
      typeDef: typeDef ?? this.typeDef,
      discriminator: discriminator ?? this.discriminator,
      discriminatorValue: discriminatorValue ?? this.discriminatorValue,
      description: description ?? super.description,
    );
  }

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
