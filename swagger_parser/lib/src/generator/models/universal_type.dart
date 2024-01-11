import '../../utils/type_utils.dart';
import 'programming_language.dart';

/// Universal template for containing information about type
final class UniversalType {
  /// Constructor for [UniversalType]
  const UniversalType({
    required this.type,
    this.name,
    this.description,
    this.format,
    this.jsonKey,
    this.defaultValue,
    this.isRequired = true,
    this.nullable = false,
    this.arrayDepth = 0,
    this.enumType,
    this.mapType,
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
  final int arrayDepth;

  /// Whether or not this field is nullable
  final bool nullable;

  /// If not null means this is map with key type
  final String? mapType;

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
    int? arrayDepth,
    bool? nullable,
    String? mapType,
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
      arrayDepth: arrayDepth ?? this.arrayDepth,
      nullable: nullable ?? this.nullable,
      mapType: mapType ?? this.mapType,
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
          description == other.description &&
          format == other.format &&
          jsonKey == other.jsonKey &&
          defaultValue == other.defaultValue &&
          isRequired == other.isRequired &&
          enumType == other.enumType &&
          arrayDepth == other.arrayDepth &&
          nullable == other.nullable &&
          mapType == other.mapType;

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
      arrayDepth.hashCode ^
      nullable.hashCode ^
      mapType.hashCode;

  @override
  String toString() =>
      'UniversalType(\ntype: $type,\nname: $name,\ndescription: $description,\nformat: $format,\njsonKey: $jsonKey,\ndefaultValue: $defaultValue,\nisRequired: $isRequired,\nenumType: $enumType,\narrayDepth: $arrayDepth,\nnullable: $nullable\n, mapType: $mapType\n)';
}

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(ProgrammingLanguage lang) {
    if (arrayDepth == 0 && mapType == null) {
      return _questionMark(lang);
    }
    final sb = StringBuffer();
    for (var i = 0; i < arrayDepth; i++) {
      sb.write('List<');
    }
    if (mapType != null) {
      sb.write(_mapStart(lang));
    }
    sb.write(_questionMark(lang));
    if (mapType != null) {
      sb.write('>');
    }
    for (var i = 0; i < arrayDepth; i++) {
      sb.write('>');
    }
    if (nullable || (!isRequired && defaultValue == null)) {
      sb.write('?');
    }
    return sb.toString();
  }

  String _questionMark(ProgrammingLanguage lang) {
    final questionMark =
        isRequired && !nullable || arrayDepth > 0 || defaultValue != null
            ? ''
            : '?';
    switch (lang) {
      case ProgrammingLanguage.dart:
        return type.toDartType(format) + questionMark;
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + questionMark;
    }
  }

  String _mapStart(ProgrammingLanguage lang) {
    switch (lang) {
      case ProgrammingLanguage.dart:
        return 'Map<${mapType!.toDartType(format)}, ';
      case ProgrammingLanguage.kotlin:
        return 'Map<${mapType!.toKotlinType(format)}, ';
    }
  }
}
