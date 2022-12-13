import 'programming_lang.dart';

/// Universal template for containing information about type
class UniversalType {
  const UniversalType({
    required this.type,
    this.isRequired = true,
    this.arrayDepth = 0,
    this.name,
    this.jsonKey,
    this.format,
  });

  /// Object type
  final String type;

  /// Array depth, 0 if not a list
  /// Example: arrayDepth = 2 -> List<List<Object>>
  final int arrayDepth;

  /// Whether or not this field is required.
  final bool isRequired;

  /// Object name
  final String? name;

  /// Object json key
  final String? jsonKey;

  /// Object format
  /// example: type = String, format = binary
  final String? format;

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
        return _dartType + (isRequired ? '' : '?');
      case ProgrammingLanguage.kotlin:
        return _kotlinType + (isRequired ? '' : '?');
    }
  }

  String get _dartType {
    switch (type) {
      case 'object':
        return 'Object';
      case 'number':
        return 'double';
      case 'integer':
        return 'int';
      case 'string':
        // if (format != null && format == 'binary') {
        //   return 'MultipartFile';
        // }
        return 'String';
      case 'boolean':
        return 'bool';
      case 'file':
        return 'MultipartFile';
    }
    return type;
  }

  String get _kotlinType {
    switch (type) {
      case 'integer':
        return 'Int';
      case 'string':
        return 'String';
      case 'boolean':
        return 'Boolean';
    }
    return type;
  }
}
