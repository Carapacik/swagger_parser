import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:swagger_parser/src/parser/model/universal_collections.dart';

/// Universal template for containing information about type
@immutable
final class UniversalType {
  /// Constructor for [UniversalType]
  const UniversalType({
    required this.type,
    required this.isRequired,
    this.name,
    this.description,
    this.format,
    this.jsonKey,
    this.defaultValue,
    this.nullable = false,
    this.wrappingCollections = const [],
    this.enumType,
    this.min,
    this.max,
    this.minItems,
    this.maxItems,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.uniqueItems,
    this.deprecated = false,
    this.referencedNullable = false,
  });

  /// Object type
  final String type;

  /// Object name
  final String? name;

  /// Object description
  final String? description;

  /// Format for object
  /// "Digit": {
  ///   "type": "number",
  ///   "format": "double"
  /// }
  ///  must be `double`
  final String? format;

  /// Object json key
  final String? jsonKey;

  /// Holding object default value
  final String? defaultValue;

  /// Whether or not this field is required
  final bool isRequired;

  /// If this type is enum
  final String? enumType;

  /// Array depth, 0 if not a list
  /// if arrayDepth = 2
  /// `List<List<Object>>`
  final List<UniversalCollections> wrappingCollections;

  /// Whether or not this field is nullable
  final bool nullable;
  final double? min;
  final double? max;
  final int? minItems;
  final int? maxItems;
  final int? minLength;
  final int? maxLength;
  final String? pattern;
  final bool? uniqueItems;

  /// Whether or not this field is deprecated
  final bool deprecated;

  /// Whether this property references a nullable schema
  final bool referencedNullable;

  /// Copy of [UniversalType] with new values
  UniversalType copyWith({
    String? type,
    String? name,
    String? description,
    String? format,
    String? jsonKey,
    String? defaultValue,
    bool? isRequired,
    String? enumType,
    List<UniversalCollections>? wrappingCollections,
    bool? nullable,
    double? min,
    double? max,
    int? minItems,
    int? maxItems,
    int? minLength,
    int? maxLength,
    String? pattern,
    bool? uniqueItems,
    bool? deprecated,
    bool? referencedNullable,
  }) {
    return UniversalType(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      format: format ?? this.format,
      jsonKey: jsonKey ?? this.jsonKey,
      defaultValue: defaultValue ?? this.defaultValue,
      isRequired: isRequired ?? this.isRequired,
      enumType: enumType ?? this.enumType,
      wrappingCollections: wrappingCollections ?? this.wrappingCollections,
      nullable: nullable ?? this.nullable,
      min: min ?? this.min,
      max: max ?? this.max,
      minItems: minItems ?? this.minItems,
      maxItems: maxItems ?? this.maxItems,
      minLength: minLength ?? this.minLength,
      maxLength: maxLength ?? this.maxLength,
      pattern: pattern ?? this.pattern,
      uniqueItems: uniqueItems ?? this.uniqueItems,
      deprecated: deprecated ?? this.deprecated,
      referencedNullable: referencedNullable ?? this.referencedNullable,
    );
  }

  /// Function for compare to put required named parameters first
  int compareTo(UniversalType other) {
    if (isRequired == other.isRequired &&
        (other.defaultValue == null) == (defaultValue == null)) {
      return 0;
    } else if (isRequired && defaultValue == null) {
      return -1;
    }
    return 1;
  }

  @override
  bool operator ==(Object other) =>
      other is UniversalType &&
      runtimeType == other.runtimeType &&
      type == other.type &&
      name == other.name &&
      format == other.format &&
      jsonKey == other.jsonKey &&
      defaultValue == other.defaultValue &&
      isRequired == other.isRequired &&
      enumType == other.enumType &&
      const DeepCollectionEquality().equals(
        wrappingCollections,
        other.wrappingCollections,
      ) &&
      nullable == other.nullable &&
      min == other.min &&
      max == other.max &&
      minItems == other.minItems &&
      maxItems == other.maxItems &&
      minLength == other.minLength &&
      maxLength == other.maxLength &&
      pattern == other.pattern &&
      uniqueItems == other.uniqueItems &&
      deprecated == other.deprecated;

  @override
  int get hashCode =>
      type.hashCode ^
      name.hashCode ^
      description.hashCode ^
      format.hashCode ^
      jsonKey.hashCode ^
      defaultValue.hashCode ^
      isRequired.hashCode ^
      enumType.hashCode ^
      wrappingCollections.hashCode ^
      nullable.hashCode ^
      min.hashCode ^
      max.hashCode ^
      minItems.hashCode ^
      maxItems.hashCode ^
      minLength.hashCode ^
      maxLength.hashCode ^
      pattern.hashCode ^
      uniqueItems.hashCode ^
      deprecated.hashCode;

  @override
  String toString() => 'UniversalType(type: $type, '
      'name: $name, '
      'format: $format, '
      'jsonKey: $jsonKey, '
      'defaultValue: $defaultValue, '
      'isRequired: $isRequired, '
      'enumType: $enumType, '
      'wrappingCollections: $wrappingCollections, '
      'nullable: $nullable, '
      'min: $min, '
      'max: $max, '
      'minItems: $minItems, '
      'maxItems: $maxItems, '
      'minLength: $minLength, '
      'maxLength: $maxLength, '
      'pattern: $pattern, '
      'uniqueItems: $uniqueItems, '
      'deprecated: $deprecated)';
}
