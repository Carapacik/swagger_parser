import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/universal_enum_class.dart';

/// Provides template for generating dart enum DTO
String dartEnumDtoTemplate(
  UniversalEnumClass enumClass, {
  bool freezed = false,
}) {
  final className = enumClass.name.toPascal;
  return '''
import '${freezed ? 'package:freezed_annotation/freezed_annotation.dart' : 'package:json_annotation/json_annotation.dart'}';

${descriptionComment(enumClass.description)}@JsonEnum()
enum $className {
${enumClass.items.map((e) => _jsonValue(enumClass.type, e)).join(',\n')};
}
''';
}

String _jsonValue(String type, String item) => '''
  @JsonValue(${type == 'string' ? "'$item'" : item})
  ${prefixForEnumItems(type, item)}''';
