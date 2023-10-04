part of 'universal_data_class.dart';

/// Universal template for enum
final class UniversalEnumClass extends UniversalDataClass {
  /// Constructor for [UniversalEnumClass]
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is UniversalEnumClass &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          const DeepCollectionEquality().equals(items, other.items) &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode =>
      super.hashCode ^ type.hashCode ^ items.hashCode ^ defaultValue.hashCode;

  @override
  String toString() {
    return 'UniversalEnumClass(\ntype: $type,\nitems: $items,\ndefaultValue: $defaultValue\n)';
  }
}
