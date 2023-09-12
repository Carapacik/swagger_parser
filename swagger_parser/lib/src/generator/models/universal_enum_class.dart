import 'package:collection/collection.dart';

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
}
