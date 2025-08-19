import '../model/normalized_identifier.dart';
import '../model/universal_data_class.dart';
import 'dart_keywords.dart';

/// Extension for utils
extension StringTypeX on String {
  /// Convert string to dart type
  String toDartType({String? format, bool useMultipartFile = false}) =>
      switch (this) {
        'integer' => 'int',
        'number' => switch (format) {
            'float' || 'double' => 'double',
            // This can happen
            'string' => 'String',
            _ => 'num',
          },
        'string' => switch (format) {
            'binary' => useMultipartFile ? 'MultipartFile' : 'File',
            'date' || 'date-time' => 'DateTime',
            _ => 'String',
          },
        'file' => useMultipartFile ? 'MultipartFile' : 'File',
        'boolean' => 'bool',
        // https://github.com/trevorwang/retrofit.dart/issues/631
        // https://github.com/Carapacik/swagger_parser/issues/110
        'object' || 'null' => 'dynamic',
        _ => startsWith('[') ? _parseTypeList(this) : this,
      };

  String _parseTypeList(String types) {
    final typesList = types.replaceAll(RegExp(r'[\[\] ]'), '').split(',');
    if (typesList.length == 2 && typesList.contains('null')) {
      final type = typesList.firstWhere((e) => e != 'null').toDartType();
      return '$type?';
    }
    return 'dynamic';
  }

  /// Convert string to kotlin type
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
        _ => this,
      };
}

const _valueConst = 'value';
const _enumConst = 'enum';
const _objectConst = 'object';

int _uniqueObjectCounter = 0;
int _uniqueEnumCounter = 0;

/// In general, it is worth putting the processing of class names, methods, fields.
/// in some separate layer from the parser and templates, so as not to write such crutches with a reset
/// The reset itself is needed to update the status during tests.
void resetUniqueNameCounters() {
  _uniqueObjectCounter = 0;
  _uniqueEnumCounter = 0;
}

/// Unique name for object classes
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

final _enumNameRegExp = RegExp(r'^[a-zA-Z\d_\s-]*$');
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

  String leadingDashToMinus(String name) {
    if (name.startsWith('-')) {
      return 'minus ${name.substring(1)}';
    }
    return name;
  }

  for (final name in names) {
    final (newName, renameDescription) = switch (name) {
      _
          when _startWithNumberRegExp.hasMatch(name) &&
              _enumNameRegExp.hasMatch(numberEnumItemName(name).toCamel) =>
        (numberEnumItemName(name), null),
      _ when !_enumNameRegExp.hasMatch(name) => (
          uniqueEnumItemName(),
          'Incorrect name has been replaced. Original name: `$name`.',
        ),
      _ when dartEnumMemberKeywords.contains(name.toCamel) => (
          '$_valueConst ${leadingDashToMinus(name)}',
          'The name has been replaced because it contains a keyword. Original name: `$name`.',
        ),
      _ => (leadingDashToMinus(name), null),
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

/// Protect enum items names from incorrect symbols, keywords, etc.
Set<UniversalEnumItem> protectEnumItemsNamesAndValues(
  Iterable<String> names,
  Iterable<String> values,
) {
  final items = <UniversalEnumItem>{};
  final nameList = names.toList();
  final valueList = values.toList();

  for (var i = 0; i < nameList.length; i++) {
    items.add(UniversalEnumItem(name: nameList[i], jsonKey: valueList[i]));
  }

  return items;
}

final _nameRegExp = RegExp(r'^[a-zA-Z_-][a-zA-Z\d_-]*$');

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
            'Name not received and was auto-generated.',
          )
        : (null, null),
    // https://github.com/Carapacik/swagger_parser/issues/262
    _
        when name.startsWith(r'$') &&
            name
                    .split('')
                    .where(
                      (e) => e == r'$',
                    )
                    .length ==
                1 =>
      (
        name.substring(1),
        'Incorrect name has been replaced. Original name: `$name`.',
      ),
    _ when !_nameRegExp.hasMatch(name) => (
        uniqueName(isEnum: isEnum),
        'Incorrect name has been replaced. Original name: `$name`.',
      ),
    _ when dartKeywords.contains(name.toCamel) => (
        '$name ${isEnum ? _enumConst : _valueConst}',
        'The name has been replaced because it contains a keyword. Original name: `$name`.',
      ),
    _ => (name, null),
  };

  return (
    newName,
    switch ((description, error)) {
      (null, null) => null,
      (null, _) => error,
      (_, null) => description,
      (_, _) => '$description\n$error',
    },
  );
}

/// Protect JsonKeys from incorrect symbols, keywords, etc.
String? protectJsonKey(String? name) => name?.replaceAll(r'$', r'\$');
