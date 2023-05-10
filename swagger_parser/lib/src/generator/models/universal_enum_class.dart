import 'universal_data_class.dart';

/// Universal template for enum
class UniversalEnumClass extends UniversalDataClass {
  const UniversalEnumClass({
    required super.name,
    required this.type,
    required this.items,
    this.defaultValue,
    super.description,
  });

  /// Enum type
  final String type;

  /// Enum items
  final Set<String> items;

  /// Holding enum default value
  final String? defaultValue;
}
