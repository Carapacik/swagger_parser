/// Universal template for containing information about component
abstract base class UniversalDataClass {
  /// Constructor for [UniversalDataClass]
  const UniversalDataClass({
    required this.name,
    this.description,
  });

  /// Name of the class
  final String name;

  /// Description of the class
  final String? description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalDataClass &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          description == other.description;

  @override
  int get hashCode => name.hashCode ^ description.hashCode;
}
