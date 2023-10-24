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
${enumClass.items.mapIndexed((i, e) => _enumValue(i, enumClass.type, e)).join(',\n')},

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  \$unknown(null);

  const $className(this.json);

  factory $className.fromJson(${enumClass.type.toDartType()} json) => values.firstWhere(
        (e) => e.json == json,
        orElse: () => \$unknown,
      );

  final ${enumClass.type.toDartType()}? json;${enumsToJson ? _toJson(enumClass, className) : ''}
}
''';
}

String _enumValue(
  int index,
  String type,
  UniversalEnumItem item,
) =>
    '''
${index != 0 ? '\n' : ''}${descriptionComment(item.description, tab: '  ')}  @JsonValue(${type == 'string' ? "'${item.jsonKey}'" : item.jsonKey})
  ${item.name.toCamel}(${type == 'string' ? "'${item.jsonKey}'" : item.jsonKey})''';

String _toJson(UniversalEnumClass enumClass, String className) =>
    '\n\n  ${enumClass.type.toDartType()}? toJson() => json;';
