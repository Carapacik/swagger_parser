import '../../utils/type_utils.dart';
import 'programming_lang.dart';

/// Universal template for containing information about type
class UniversalType {
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

  /// Function for compare to put required named parameters first
  int compareTo(UniversalType other) {
    if (isRequired == other.isRequired && (other.defaultValue == null) == (defaultValue == null)) {
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
          nullable == other.nullable;

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
      nullable.hashCode;
}

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(ProgrammingLanguage lang) {
    if (arrayDepth == 0) {
      return _questionMark(lang);
    }
    final sb = StringBuffer();
    for (var i = 0; i < arrayDepth; i++) {
      sb.write('List<');
    }
    sb.write(_questionMark(lang));
    for (var i = 0; i < arrayDepth; i++) {
      sb.write('>');
    }
    if (nullable || (!isRequired && defaultValue == null)) {
      sb.write('?');
    }
    return sb.toString();
  }

  String _questionMark(ProgrammingLanguage lang) {
    final questionMark = isRequired && !nullable || arrayDepth > 0 || defaultValue != null ? '' : '?';
    switch (lang) {
      case ProgrammingLanguage.dart:
        return type.toDartType(format) + questionMark;
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + questionMark;
    }
  }
}
