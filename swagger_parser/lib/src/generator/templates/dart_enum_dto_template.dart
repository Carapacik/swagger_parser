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
  required bool markFileAsGenerated,
}) {
  final className = enumClass.name.toPascal;
  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}import '${freezed ? 'package:freezed_annotation/freezed_annotation.dart' : 'package:json_annotation/json_annotation.dart'}';

${descriptionComment(enumClass.description)}@JsonEnum()
enum $className {
${enumClass.items.mapIndexed((i, e) => _jsonValue(i, enumClass.type, e)).join(',\n')};
${enumsToJson ? _toJson(enumClass, className) : '}'}
''';
}

String _jsonValue(
  int index,
  String type,
  UniversalEnumItem item,
) =>
    '''
${index != 0 && item.description != null ? '\n' : ''}${descriptionComment(item.description, tab: '  ')}  @JsonValue(${type == 'string' ? "'${item.jsonKey}'" : item.jsonKey})
  ${item.name.toCamel}''';

String _toJson(UniversalEnumClass enumClass, String className) => '''

  ${enumClass.type.toDartType()} toJson() => _\$${className}EnumMap[this]!;
}

const _\$${className}EnumMap = {
  ${enumClass.items.map(
          (e) => '$className.${e.name.toCamel}: '
              '${enumClass.type == 'string' ? "'" : ''}${e.jsonKey}${enumClass.type == 'string' ? "'" : ''}',
        ).join(',\n  ')},
};''';
