import 'package:collection/collection.dart';

import '../../utils/type_utils.dart';
import 'universal_type.dart';

part 'universal_component_class.dart';
part 'universal_enum_class.dart';

/// Universal template for containing information about component
sealed class UniversalDataClass {
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
