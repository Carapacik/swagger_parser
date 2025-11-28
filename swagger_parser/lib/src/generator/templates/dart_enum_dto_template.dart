import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/json_serializer.dart';
import 'package:swagger_parser/src/generator/templates/dart_import_dto_template.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';

/// Provides template for generating dart enum DTO
String dartEnumDtoTemplate(
  UniversalEnumClass enumClass, {
  required JsonSerializer jsonSerializer,
  required bool enumsToJson,
  required bool unknownEnumValue,
  required bool markFileAsGenerated,
}) {
  if (jsonSerializer == JsonSerializer.dartMappable) {
    return _dartEnumDartMappableTemplate(
      enumClass,
      enumsToJson: enumsToJson,
      unknownEnumValue: unknownEnumValue,
    );
  } else {
    final className = enumClass.name.toPascal;
    final jsonParam = unknownEnumValue || enumsToJson;

    final values =
        '${enumClass.items.mapIndexed((i, e) => _enumValue(i, enumClass.type, e, jsonParam: jsonParam)).join(',')}${unknownEnumValue ? ',' : ';'}';

    final enumBodyParts = [
      values,
      if (unknownEnumValue) _unkownEnumValue(),
      if (jsonParam) _constructor(className),
      if (unknownEnumValue) _fromJson(className, enumClass),
      if (jsonParam) _jsonField(enumClass),
      if (enumsToJson) _toJson(enumClass, className),
      if (jsonParam) _toString(),
      if (unknownEnumValue) _valuesDefined(className),
    ];

    return '''
${dartImportDtoTemplate(jsonSerializer)}

${descriptionComment(enumClass.description)}@JsonEnum()
enum $className {
${enumBodyParts.join()}
}
''';
  }
}

String _dartEnumDartMappableTemplate(
  UniversalEnumClass enumClass, {
  required bool enumsToJson,
  required bool unknownEnumValue,
}) {
  final className = enumClass.name.toPascal;
  final jsonParam = unknownEnumValue || enumsToJson;

  final values = [
    ...enumClass.items,
    if (unknownEnumValue &&
        !enumClass.items.any(
          (item) =>
              item.name.toLowerCase() == 'unknown' ||
              item.jsonKey.toLowerCase() == 'unknown',
        ))
      const UniversalEnumItem(name: 'unknown', jsonKey: 'unknown'),
  ]
      .mapIndexed(
        (i, e) =>
            _enumValueDartMappable(i, enumClass.type, e, jsonParam: jsonParam),
      )
      .join(',\n');

  final annotationParameters = [
    if (unknownEnumValue) "defaultValue: 'unknown'",
  ].join(', ');

  final enumBodyParts = [
    '$values;',
    if (enumsToJson) '\n\n  String toJson() => toValue().toString();',
    _toStringDartMappable(),
    if (unknownEnumValue) _valuesDefinedDartMappable(className),
  ];

  return '''
${dartImportDtoTemplate(JsonSerializer.dartMappable)}

part '${enumClass.name.toSnake}.mapper.dart';

${descriptionComment(enumClass.description)}@MappableEnum($annotationParameters)
enum $className {
${enumBodyParts.join()}
}
''';
}

String _constructor(String className) => '\n\n  const $className(this.json);\n';

String _jsonField(UniversalEnumClass enumClass) {
  final dartType = enumClass.type.toDartType();
  return '\n  final $dartType${_nullableSign(dartType)} json;';
}

String _nullableSign(String dartType) {
  if (dartType.endsWith('?')) {
    return '';
  }
  final isDynamic = dartType == 'dynamic';
  final nullableSign = isDynamic ? '' : '?';
  return nullableSign;
}

String _unkownEnumValue() => r'''

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);''';

String _fromJson(String className, UniversalEnumClass enumClass) => '''

  factory $className.fromJson(${enumClass.type.toDartType()} json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => \$unknown,
      );
''';

String _enumValue(
  int index,
  String type,
  UniversalEnumItem item, {
  required bool jsonParam,
}) {
  final protectedJsonKey = protectJsonKey(item.jsonKey);

  final String? value;
  if (type == 'string') {
    value = "'$protectedJsonKey'";
  } else {
    if (protectedJsonKey?.isEmpty ?? true) {
      value = "''";
    } else {
      if (protectedJsonKey == 'null') {
        value = null;
      } else {
        final isNumber = RegExp(
          r'^-?\d+(\.\d+)?$',
        ).hasMatch(protectedJsonKey ?? '');
        if (isNumber) {
          value = protectedJsonKey;
        } else {
          value = "'$protectedJsonKey'";
        }
      }
    }
  }

  final name = item.name.isEmpty ? 'empty' : item.name;
  return '''
${index != 0 ? '\n' : ''}${descriptionComment(item.description, tab: '  ')}  @JsonValue($value)
  ${name.toCamel}${jsonParam ? '($value)' : ''}''';
}

String _enumValueDartMappable(
  int index,
  String type,
  UniversalEnumItem item, {
  required bool jsonParam,
}) {
  final protectedJsonKey = protectJsonKey(item.jsonKey);
  return '''
${index != 0 ? '\n' : ''}${descriptionComment(item.description, tab: '  ')}${indentation(2)}@MappableValue(${type == 'string' ? "'$protectedJsonKey'" : protectedJsonKey}) 
${indentation(2)}${item.name.toCamel}''';
}

String _toJson(UniversalEnumClass enumClass, String className) {
  final dartType = enumClass.type.toDartType();
  return '\n\n  $dartType${_nullableSign(dartType)} toJson() => json;';
}

String _toString() =>
    '\n\n  @override\n  String toString() => json?.toString() ?? super.toString();';

String _toStringDartMappable() =>
    '\n\n  @override\n  String toString() => toValue().toString();\n';

String _valuesDefined(String className) => '''

  /// Returns all defined enum values excluding the \$unknown value.
  static List<$className> get \$valuesDefined => values.where((value) => value != \$unknown).toList();''';

String _valuesDefinedDartMappable(String className) => '''

  /// Returns all defined enum values excluding the unknown value.
  static List<$className> get \$valuesDefined => values.where((value) => value != $className.unknown).toList();''';
