/// Universal template for containing information about component
abstract class UniversalDataClass {
  const UniversalDataClass({
    required this.name,
    this.description,
  });

  /// Name of the class
  final String name;

  /// Description of the class
  final String? description;
}
