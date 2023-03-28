import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
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
${dataClass.items.map((e) => _valuePrefixForEnumValueItems(dataClass.type, e)).join(',\n')};

  ${dataClass.type.toDartType()} toJson() => _\$${className}EnumMap[this]!;
}

const _\$${className}EnumMap = {
  ${dataClass.items.map(
            (e) => '$className.${_valuePrefixForEnumItems(dataClass.type, e)}: '
                '${dataClass.type.quoterForStringType()}$e${dataClass.type.quoterForStringType()}',
          ).join(',\n  ')},
};
''';
}

String _valuePrefixForEnumValueItems(String type, String item) {
  return '''
  @JsonValue(${type == 'string' ? "'$item'" : item})
  ${_valuePrefixForEnumItems(type, item)}''';
}

String _valuePrefixForEnumItems(String type, String item) =>
    type != 'string' ? 'value$item'.toCamel : item.toCamel;
