import '../generator/models/universal_data_class.dart';
import 'case_utils.dart';
import 'dart_keywords.dart';

extension StringTypeX on String {
  String toDartType([String? format]) => switch (this) {
        'integer' => 'int',
        'number' => switch (format) {
            'float' || 'double' => 'double',
            // This can happen
            'string' => 'String',
            _ => 'num',
          },
        'string' => switch (format) {
            'binary' => 'File',
            'date' || 'date-time' => 'DateTime',
            _ => 'String',
          },
        'file' => 'File',
        'boolean' => 'bool',
        'object' || 'null' => 'Object',
        _ => this
      };

  String toKotlinType([String? format]) => switch (this) {
        'integer' => 'Int',
        'number' => switch (format) {
            'float' => 'Float',
            // This can happen
            'string' => 'String',
            _ => 'Double',
          },
        'string' => switch (format) {
            'binary' => 'MultipartBody.Part',
            'date' || 'date-time' => 'Date',
            _ => 'String',
          },
        'file' => 'MultipartBody.Part',
        'boolean' => 'Boolean',
        'object' => 'Any',
        _ => this
      };
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

final _enumNameRegExp = RegExp(r'^[a-zA-Z\d_-\s]*$');
final _startWithNumberRegExp = RegExp(r'^-?\d+');

/// Protect default enum value from incorrect symbols, keywords, etc.
String? protectDefaultEnum(Object? name) =>
    protectDefaultValue(name, isEnum: true);

/// Protect default value from incorrect symbols, keywords, etc.
String? protectDefaultValue(
  Object? name, {
  String? type,
  bool isEnum = false,
  bool isArray = false,
  bool dart = true,
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

  if (isEnum) {
    return protectEnumItemsNames([nameStr]).first.name;
  }

  if (isArray) {
    return null;
  }

  if (type == 'string') {
    final quote = dart ? "'" : '"';
    return '$quote${nameStr.replaceAll(quote, dart ? r"\'" : r'\"')}$quote';
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
    final (newName, renameDescription) = switch (name) {
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
        description: renameDescription,
      ),
    );
  }

  return items;
}

final nameRegExp = RegExp(r'^[a-zA-Z_][a-zA-Z\d_]*$');

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
    _ when !nameRegExp.hasMatch(name) => (
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
