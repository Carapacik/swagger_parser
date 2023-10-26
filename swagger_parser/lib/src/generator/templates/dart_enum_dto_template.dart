import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/universal_data_class.dart';

/// Provides template for generating dart enum DTO
String dartEnumDtoTemplate(
  UniversalEnumClass enumClass, {
  required bool freezed,
  required bool enumsToJson,
  required bool unknownEnumValue,
  required bool markFileAsGenerated,
}) {
  final className = enumClass.name.toPascal;
  final jsonParam = unknownEnumValue || enumsToJson;

  final values =
      '${enumClass.items.mapIndexed((i, e) => _enumValue(i, enumClass.type, e, jsonParam: jsonParam)).join(',\n')}${unknownEnumValue ? ',' : ';'}';
  final unkownEnumValueStr = unknownEnumValue ? _unkownEnumValue() : '';
  final constructorStr = jsonParam ? _constructor(className) : '';
  final fromJsonStr = unknownEnumValue ? _fromJson(className, enumClass) : '';
  final jsonFieldStr = jsonParam ? _jsonField(enumClass) : '';
  final toJsonStr = enumsToJson ? _toJson(enumClass, className) : '';

  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}import '${freezed ? 'package:freezed_annotation/freezed_annotation.dart' : 'package:json_annotation/json_annotation.dart'}';

${descriptionComment(enumClass.description)}@JsonEnum()
enum $className {
$values$unkownEnumValueStr$constructorStr$fromJsonStr$jsonFieldStr$toJsonStr
}
''';
}

String _constructor(String className) => '\n\n  const $className(this.json);\n';

String _jsonField(UniversalEnumClass enumClass) =>
    '\n  final ${enumClass.type.toDartType()}? json;';

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
}) =>
    '''
${index != 0 ? '\n' : ''}${descriptionComment(item.description, tab: '  ')}  @JsonValue(${type == 'string' ? "'${item.jsonKey}'" : item.jsonKey})
  ${item.name.toCamel}${jsonParam ? '(${type == 'string' ? "'${item.jsonKey}'" : item.jsonKey})' : ''}''';

String _toJson(UniversalEnumClass enumClass, String className) =>
    '\n\n  ${enumClass.type.toDartType()}? toJson() => json;';
