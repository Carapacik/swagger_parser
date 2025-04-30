import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../model/json_serializer.dart';
import 'dart_import_dto_template.dart';

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
      markFileAsGenerated: markFileAsGenerated,
    );
  } else {
    final className = enumClass.name.toPascal;
    final jsonParam = unknownEnumValue || enumsToJson;

    final values =
        '${enumClass.items.mapIndexed((i, e) => _enumValue(i, enumClass.type, e, jsonParam: jsonParam)).join(',')}${unknownEnumValue ? ',' : ';'}';
    final unknownEnumValueStr = unknownEnumValue ? _unkownEnumValue() : '';
    final constructorStr = jsonParam ? _constructor(className) : '';
    final fromJsonStr = unknownEnumValue ? _fromJson(className, enumClass) : '';
    final jsonFieldStr = jsonParam ? _jsonField(enumClass) : '';
    final toJsonStr = enumsToJson ? _toJson(enumClass, className) : '';

    return '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${dartImportDtoTemplate(jsonSerializer)}

${descriptionComment(enumClass.description)}@JsonEnum()
enum $className {
$values$unknownEnumValueStr$constructorStr$fromJsonStr$jsonFieldStr$toJsonStr
}
''';
  }
}

String _dartEnumDartMappableTemplate(
  UniversalEnumClass enumClass, {
  required bool enumsToJson,
  required bool unknownEnumValue,
  required bool markFileAsGenerated,
}) {
  final className = enumClass.name.toPascal;
  final jsonParam = unknownEnumValue || enumsToJson;

  final values = [
    ...enumClass.items,
    if (unknownEnumValue)
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

  final toJson = enumsToJson ? 'dynamic toJson() => toValue();' : '';

  return '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${dartImportDtoTemplate(JsonSerializer.dartMappable)}

part '${enumClass.name.toSnake}.mapper.dart';

${descriptionComment(enumClass.description)}@MappableEnum($annotationParameters)
enum $className {
$values;
$toJson
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
