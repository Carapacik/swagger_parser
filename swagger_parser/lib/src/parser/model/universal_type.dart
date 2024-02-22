import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:swagger_parser/swagger_parser.dart';

import '../../utils/type_utils.dart';

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
    this.arrayValueNullable = false,
    this.enumType,
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
  /// List<List<Object>>
  final List<String> wrappingCollections;

  /// Whether or not this field is nullable
  final bool arrayValueNullable;

  /// Whether or not this field is nullable
  final bool nullable;

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
    List<String>? wrappingCollections,
    bool? nullable,
    bool? arrayValueNullable,
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
      arrayValueNullable: arrayValueNullable ?? this.arrayValueNullable,
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
      identical(this, other) ||
      other is UniversalType &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          name == other.name &&
          format == other.format &&
          jsonKey == other.jsonKey &&
          defaultValue == other.defaultValue &&
          isRequired == other.isRequired &&
          enumType == other.enumType &&
          const DeepCollectionEquality()
              .equals(wrappingCollections, other.wrappingCollections) &&
          nullable == other.nullable &&
          arrayValueNullable == other.arrayValueNullable;

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
      arrayValueNullable.hashCode;

  @override
  String toString() => 'UniversalType(type: $type, '
      'name: $name, '
      'format: $format, '
      'jsonKey: $jsonKey, '
      'defaultValue: $defaultValue, '
      'isRequired: $isRequired, '
      'enumType: $enumType, '
      'wrappingCollections: $wrappingCollections, '
      'arrayValueNullable: $arrayValueNullable, '
      'nullable: $nullable)';
}

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(ProgrammingLanguage lang) {
    if (wrappingCollections.isEmpty) {
      return _questionMark(lang);
    }
    final sb = StringBuffer();
    for (var i = 0; i < wrappingCollections.length; i++) {
      sb.write(wrappingCollections[i]);
    }
    sb.write(_questionMark(lang));
    for (var i = 0; i < wrappingCollections.length; i++) {
      sb.write('>');
    }
    if (nullable || (!isRequired && defaultValue == null)) {
      sb.write('?');
    }
    return sb.toString();
  }

  String _questionMark(ProgrammingLanguage lang) {
    final questionMark = (isRequired && !nullable ||
                wrappingCollections.isNotEmpty ||
                defaultValue != null) &&
            !arrayValueNullable
        ? ''
        : '?';
    switch (lang) {
      case ProgrammingLanguage.dart:
        return type.toDartType(format) + questionMark;
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + questionMark;
    }
  }
}
