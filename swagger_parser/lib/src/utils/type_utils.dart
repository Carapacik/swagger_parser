import '../generator/model/programming_language.dart';
import '../parser/swagger_parser_core.dart';
import 'case_utils.dart';
import 'dart_keywords.dart';

/// Converts [UniversalType] to type from specified language
extension UniversalTypeX on UniversalType {
  /// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
  String toSuitableType(ProgrammingLanguage lang) {
    if (wrappingCollections.isEmpty) {
      return _questionMark(lang);
    }
    final sb = StringBuffer();
    for (var i = 0; i < wrappingCollections.length; i++) {
      sb.write(wrappingCollections[i].collectionsString);
    }
    sb.write(_questionMark(lang));
    for (var i = 0; i < wrappingCollections.length; i++) {
      sb.write('>');
    }
    if (nullable || (!isRequired && defaultValue == null)) {
      sb.write('?');
    }
    return sb.toString();
  }

  String _questionMark(ProgrammingLanguage lang) {
    final questionMark = (isRequired && !nullable ||
                wrappingCollections.isNotEmpty ||
                defaultValue != null) &&
            !arrayValueNullable
        ? ''
        : '?';
    switch (lang) {
      case ProgrammingLanguage.dart:
        // https://github.com/trevorwang/retrofit.dart/issues/631
        // https://github.com/Carapacik/swagger_parser/issues/110
        return type.toDartType(format) +
            (type.toDartType(format) == 'dynamic' ? '' : questionMark);
      case ProgrammingLanguage.kotlin:
        return type.toKotlinType(format) + questionMark;
    }
  }
}

/// Extension for utils
extension StringTypeX on String {
  /// Convert string to dart type
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
        // https://github.com/trevorwang/retrofit.dart/issues/631
        // https://github.com/Carapacik/swagger_parser/issues/110
        'object' || 'null' => 'dynamic',
        _ => this
      };

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
        _ => this
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
        (
          numberEnumItemName(name),
          null,
        ),
      _ when !_enumNameRegExp.hasMatch(name) => (
          uniqueEnumItemName(),
          'Incorrect name has been replaced. Original name: `$name`.'
        ),
      _ when dartEnumMemberKeywords.contains(name.toCamel) => (
          '$_valueConst ${leadingDashToMinus(name)}',
          'The name has been replaced because it contains a keyword. Original name: `$name`.'
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
      (_, _) => '$description\n$error',
    },
  );
}
