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

  /// Array depth, 0 if not a list
  /// if arrayDepth = 2
  /// List<List<Object>>
  final int arrayDepth;

  /// Whether or not this field is nullable
  final bool nullable;

  /// Function for compare to put required named parameters first
  int compareTo(UniversalType other) {
    if (isRequired == other.isRequired) {
      return 0;
    } else if (isRequired) {
      return -1;
    }
    return 1;
  }
}

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  String byLang(ProgrammingLanguage lang) {
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
}
