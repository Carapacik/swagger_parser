import 'package:swagger_parser/src/generator/models/programming_lang.dart';

/// Universal template for containing information about type
class UniversalType {
  const UniversalType({
    required this.type,
    this.isRequired = false,
    this.arrayDepth = 0,
    this.name,
    this.jsonKey,
    this.format,
  });

  final String type;
  final int arrayDepth;
  final bool isRequired;
  final String? name;
  final String? jsonKey;
  final String? format;
}

/// Converts [UniversalType] to type from specified language
extension SuitableType on UniversalType {
  String byLang(ProgrammingLanguage lang) {
    switch (lang) {
      case ProgrammingLanguage.dart:
        return dartType;
      case ProgrammingLanguage.kotlin:
        return kotlinType;
    }
  }

  String get dartType {
    switch (type) {
      case 'integer':
        return 'int';
      case 'string':
        if (format != null && format == 'binary') {
          return 'MultipartFile';
        }
        return 'String';
      case 'boolean':
        return 'bool';
      case 'file':
        return 'MultipartFile';
    }
    return type;
  }

  String get kotlinType {
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
