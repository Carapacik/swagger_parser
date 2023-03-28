import '../../utils/case_utils.dart';
import '../models/universal_enum_class.dart';

/// Provides template for generating dart enum DTO
String dartEnumDtoTemplate(
  UniversalEnumClass dataClass, {
  bool freezed = false,
}) {
  final className = dataClass.name.toPascal;
  return '''
import '${freezed ? 'package:freezed_annotation/freezed_annotation.dart' : 'package:json_annotation/json_annotation.dart'}';

@JsonEnum()
enum $className {
${dataClass.items.map((e) => _valuePrefixForEnumItems(dataClass.type, e)).join(',\n')};
}
''';
}

String _valuePrefixForEnumItems(String type, String item) {
  return '''
  @JsonValue(${type == 'string' ? "'${item}'" : item})
  ${item.toCamel}''';
}
