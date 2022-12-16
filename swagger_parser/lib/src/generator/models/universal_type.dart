import '../../utils/type_utils.dart';
import 'programming_lang.dart';

/// Universal template for containing information about type
class UniversalType {
  const UniversalType({
    required this.type,
    this.format,
    this.name,
    this.jsonKey,
    this.defaultValue,
    this.isRequired = true,
    this.arrayDepth = 0,
  });

  /// Object type
  final String type;

  /// Format for object
  /// Example: type = number, format = double
  final String? format;

  /// Object name
  final String? name;

  /// Object json key
  final String? jsonKey;

  /// Holding object default value
  final String? defaultValue;

  /// Whether or not this field is required.
  final bool isRequired;

  /// Array depth, 0 if not a list
  /// Example: arrayDepth = 2 -> List<List<Object>>
  final int arrayDepth;

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
extension SuitableType on UniversalType {
  String byLang(ProgrammingLanguage lang, {bool isRequired = true}) {
    switch (lang) {
      case ProgrammingLanguage.dart:
        return type.toDartType(format) + (isRequired ? '' : '?');
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + (isRequired ? '' : '?');
    }
  }
}
