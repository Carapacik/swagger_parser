import '../generator/models/universal_data_class.dart';
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

const _valueConst = 'value';
const _enumConst = 'enum';
const _objectConst = 'object';

int _uniqueObjectCounter = 0;
int _uniqueEnumCounter = 0;

String uniqueName({bool isEnum = false}) {
  final String name;
  if (isEnum) {
    name = '$_enumConst$_uniqueEnumCounter';
    _uniqueEnumCounter++;
  } else {
    name = '$_objectConst$_uniqueObjectCounter';
    _uniqueObjectCounter++;
  }
  return name;
}

final _enumNameRegExp = RegExp(r'^[a-zA-Z\d_-]*$');
final _startWithNumberRegExp = RegExp(r'^-?\d+');

/// Protect default enum value from incorrect symbols, keywords, etc.
String? protectDefaultEnum(Object? name) =>
    protectDefaultValue(name, isEnum: true);

/// Protect default value from incorrect symbols, keywords, etc.
String? protectDefaultValue(
  Object? name, {
  bool isEnum = false,
  bool isArray = false,
}) {
  final nameStr = name?.toString();
  if (nameStr == null) {
    return null;
  }

  /// Json is not supported
  if (nameStr.startsWith('{') && nameStr.endsWith('}')) {
    return null;
  }

  if (nameStr.startsWith('[') && nameStr.endsWith(']')) {
    return nameStr;
  }

  if (isArray) {
    return null;
  }

  if (isEnum) {
    return protectEnumItemsNames([nameStr]).first.name;
  }

  return nameStr;
}

/// Protect enum items names from incorrect symbols, keywords, etc.
Set<UniversalEnumItem> protectEnumItemsNames(Iterable<String> names) {
  var counter = 0;
  final items = <UniversalEnumItem>{};

  String uniqueEnumItemName() {
    final newName = 'undefined $counter';
    counter++;
    return newName;
  }

  String numberEnumItemName(String name) {
    final startsWithMinus = name.startsWith('-');
    final newName = 'value ${startsWithMinus ? 'minus' : ''} $name';
    return newName;
  }

  for (final name in names) {
    final (newName, error) = switch (name) {
      _
          when _startWithNumberRegExp.hasMatch(name) &&
              _enumNameRegExp.hasMatch(numberEnumItemName(name).toCamel) =>
        (
          numberEnumItemName(name),
          null,
        ),
      _ when !_enumNameRegExp.hasMatch(name) => (
          uniqueEnumItemName(),
          'Incorrect name has been replaced. Original name: `$name`.'
        ),
      _ when dartKeywords.contains(name.toCamel) => (
          '$_valueConst $name',
          'The name has been replaced because it contains a keyword. Original name: `$name`.'
        ),
      _ => (name, null),
    };
    items.add(
      UniversalEnumItem(
        name: newName,
        jsonKey: name,
        description: error,
      ),
    );
  }

  return items;
}

final _nameRegExp = RegExp(r'^[a-zA-Z_][a-zA-Z\d_]*$');

/// Protect name from incorrect symbols, keywords, etc.
(String? newName, String? description) protectName(
  String? name, {
  String? description,
  bool uniqueIfNull = false,
  bool isEnum = false,
  bool isMethod = false,
}) {
  final (newName, error) = switch (name) {
    null || '' => uniqueIfNull
        ? (
            uniqueName(isEnum: isEnum),
            'Name not received and was auto-generated.'
          )
        : (null, null),
    _ when !_nameRegExp.hasMatch(name) => (
        uniqueName(isEnum: isEnum),
        'Incorrect name has been replaced. Original name: `$name`.'
      ),
    _ when dartKeywords.contains(name.toCamel) => (
        '$name ${isEnum ? _enumConst : _valueConst}',
        'The name has been replaced because it contains a keyword. Original name: `$name`.'
      ),
    _ => (name, null),
  };

  return (
    newName,
    switch ((description, error)) {
      (null, null) => null,
      (null, _) => error,
      (_, null) => description,
      (_, _) => '$description\n\n$error',
    },
  );
}
