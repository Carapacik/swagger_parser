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

    final values = '${enumClass.items.mapIndexed(
          (i, e) => _enumValue(i, enumClass.type, e, jsonParam: jsonParam),
        ).join(',')}${unknownEnumValue ? ',' : ';'}';
    final unknownEnumValueStr = unknownEnumValue ? _unkownEnumValue() : '';
    final constructorStr = jsonParam ? _constructor(className) : '';
    final fromJsonStr = unknownEnumValue ? _fromJson(className, enumClass) : '';
    final jsonFieldStr =
        jsonParam ? _jsonField(enumClass, unknownEnumValue) : '';
    final toJsonStr =
        enumsToJson ? _toJson(enumClass, className, unknownEnumValue) : '';

    return '''
${generatedFileComment(
      markFileAsGenerated: markFileAsGenerated,
    )}${dartImportDtoTemplate(jsonSerializer)}

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

  final values =
      '${enumClass.items.mapIndexed((i, e) => _enumValueDartMappable(i, enumClass.type, e, jsonParam: jsonParam)).join(',\n')}${unknownEnumValue ? ',' : ';'}';
  final unknownEnumValueStr = unknownEnumValue ? _unkownEnumValue(true) : '';
  final jsonFieldStr = jsonParam ? _jsonField(enumClass, unknownEnumValue) : '';
  final constructorStr = jsonParam ? _constructor(className) : '';
  final toJsonStr =
      enumsToJson ? _toJson(enumClass, className, unknownEnumValue) : '';

  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}${dartImportDtoTemplate(JsonSerializer.dartMappable)}

part '${enumClass.name.toSnake}.mapper.dart';

${descriptionComment(enumClass.description)}@MappableEnum()
enum $className {
$values$unknownEnumValueStr$jsonFieldStr$constructorStr$toJsonStr
}
''';
}

String _constructor(String className) =>
    '\n\n${indentation(1)} const $className(this.value);';

String _jsonField(UniversalEnumClass enumClass, bool unknownEnumValue) =>
    '\n\n${indentation(1)} final ${enumClass.type.toDartType()}${_hasNullItem(enumClass, unknownEnumValue) ? '?' : ''} value;';

String _unkownEnumValue([bool mappable = false]) {
  if (mappable) {
    return r'''
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  @MappableValue(null)
  $unknown(null);''';
  }

  return r'''
  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);''';
}

String _fromJson(String className, UniversalEnumClass enumClass) => '''

  factory $className.fromJson(${enumClass.type.toDartType()} json) => values.firstWhere(
        (e) => e.value == json,
        orElse: () => \$unknown,
      );''';

bool _hasNullItem(UniversalEnumClass enumClass, bool unknownEnumValue) =>
    unknownEnumValue || enumClass.items.any((e) => e.jsonKey == 'null');

String _enumValue(
  int index,
  String type,
  UniversalEnumItem item, {
  required bool jsonParam,
}) {
  final protectedJsonKey = protectJsonKey(item.jsonKey);
  return '''
${index != 0 ? '\n' : ''}${descriptionComment(item.description, tab: '  ')}  @JsonValue(${type == 'string' ? "'$protectedJsonKey'" : protectedJsonKey})
  ${item.name.toCamel}${jsonParam ? '(${type == 'string' ? "'$protectedJsonKey'" : protectedJsonKey})' : ''}''';
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
${indentation(2)}${item.name.toCamel}${jsonParam ? '(${type == 'string' ? "'$protectedJsonKey'" : protectedJsonKey})' : ''}''';
}

String _toJson(
  UniversalEnumClass enumClass,
  String className,
  bool unknownEnumValue,
) =>
    '\n\n${indentation(1)} ${enumClass.type.toDartType()}${_hasNullItem(enumClass, unknownEnumValue) ? '?' : ''} toJson() => value;';
