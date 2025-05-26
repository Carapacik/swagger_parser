part of 'universal_data_class.dart';

/// Universal template for enum
@immutable
final class UniversalEnumClass extends UniversalDataClass {
  /// Constructor for [UniversalEnumClass]
  const UniversalEnumClass({
    required super.name,
    required this.type,
    required this.items,
    final String? originalName,
    this.defaultValue,
    super.description,
  }) : originalName = originalName ?? name;

  /// Enum original name (without suffix number for duplicates)
  final String originalName;

  /// Enum type
  final String type;

  /// Enum items
  final Set<UniversalEnumItem> items;

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
  String toString() => 'UniversalEnumClass(type: $type, '
      'items: $items, '
      'defaultValue: $defaultValue)';
}

/// Universal template for enum item
@immutable
class UniversalEnumItem {
  /// Constructor for [UniversalEnumItem]
  const UniversalEnumItem({
    required this.name,
    required this.jsonKey,
    this.description,
  });

  /// Enum item name
  final String name;

  /// Enum item json key
  final String jsonKey;

  /// Enum item description
  final String? description;

  /// Convert list of strings to set of [UniversalEnumItem]
  /// Only for testing
  static Set<UniversalEnumItem> listFromNames(Iterable<String> names) {
    return protectEnumItemsNames(names);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UniversalEnumItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          jsonKey == other.jsonKey &&
          description == other.description;

  @override
  int get hashCode => name.hashCode ^ jsonKey.hashCode ^ description.hashCode;

  @override
  String toString() =>
      'UniversalEnumItem(name: $name, jsonKey: $jsonKey, description: $description)';
}
