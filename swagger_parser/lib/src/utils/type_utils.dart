import 'case_utils.dart';
import 'dart_keywords.dart';

extension StringTypeX on String {
  String toDartType([String? format]) {
    switch (this) {
      case 'integer':
        return 'int';
      case 'number':
        if (format == 'float' || format == 'double') {
          return 'double';
        }
        // This can happen
        if (format == 'string') {
          return 'String';
        }
        return 'num';
      case 'string':
        switch (format) {
          case 'binary':
            return 'File';
          case 'date':
          case 'date-time':
            return 'DateTime';
        }
        return 'String';
      case 'file':
        return 'File';
      case 'boolean':
        return 'bool';
      case 'object':
        return 'Object';
    }
    return this;
  }

  String toKotlinType([String? format]) {
    switch (this) {
      case 'integer':
        return 'Int';
      case 'number':
        if (format == 'float') {
          return 'Float';
        }
        // This can happen
        if (format == 'string') {
          return 'String';
        }
        return 'Double';
      case 'string':
        switch (format) {
          case 'binary':
            return 'MultipartBody.Part';
          case 'date':
          case 'date-time':
            return 'Date';
        }
        return 'String';
      case 'file':
        return 'MultipartBody.Part';
      case 'boolean':
        return 'Boolean';
      case 'object':
        return 'Any';
    }
    return this;
  }

  String quoterForStringType({bool dart = true}) => this == 'string'
      ? dart
          ? "'"
          : '"'
      : '';
}

String prefixForEnumItems(String type, String item, {bool dart = true}) {
  final startsWithNumber = RegExp(r'^\d');
  return type != 'string' ||
          dartKeywords.contains(item.toCamel) ||
          startsWithNumber.hasMatch(item)
      ? dart
          ? 'value ${item.startsWith('-') ? 'Minus' : ''} ${item.toCamel}'
              .toCamel
          : 'value ${item.toSnake}'.toSnake.toUpperCase()
      : dart
          ? item.toCamel
          : item.toSnake.toUpperCase();
}
