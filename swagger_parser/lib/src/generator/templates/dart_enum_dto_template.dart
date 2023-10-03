import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/universal_data_class.dart';

/// Provides template for generating dart enum DTO
String dartEnumDtoTemplate(
  UniversalEnumClass enumClass, {
  required bool freezed,
  required bool enumsToJson,
  required bool markFileAsGenerated,
}) {
  final className = enumClass.name.toPascal;
  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}import '${freezed ? 'package:freezed_annotation/freezed_annotation.dart' : 'package:json_annotation/json_annotation.dart'}';

${descriptionComment(enumClass.description)}@JsonEnum()
enum $className {
${enumClass.items.map((e) => _jsonValue(enumClass.type, e)).join(',\n')};
${enumsToJson ? _toJson(enumClass, className) : '}'}
''';
}

String _jsonValue(String type, String item) => '''
  @JsonValue(${type == 'string' ? "'$item'" : item})
  ${prefixForEnumItems(type, item)}''';

String _toJson(UniversalEnumClass enumClass, String className) => '''

  ${enumClass.type.toDartType()} toJson() => _\$${className}EnumMap[this]!;
}

const _\$${className}EnumMap = {
  ${enumClass.items.map(
          (e) => '$className.${prefixForEnumItems(enumClass.type, e)}: '
              '${enumClass.type.quoterForStringType()}$e${enumClass.type.quoterForStringType()}',
        ).join(',\n  ')},
};''';
