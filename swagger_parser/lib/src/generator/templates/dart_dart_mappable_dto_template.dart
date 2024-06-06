import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/json_serializer.dart';
import '../model/programming_language.dart';
import 'dart_import_dto_template.dart';

String dartDartMappableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
}) {
  final className = dataClass.name.toPascal;
  return '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}
${dartImportDtoTemplate(JsonSerializer.dartMappable)}
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.mapper.dart';

${descriptionComment(dataClass.description)}@MappableClass()
class $className with ${className}Mappable {

${indentation(2)}const $className(${getParameters(dataClass)});

${getFields(dataClass)}

${indentation(
    2,
  )}static $className fromJson(Map<String, dynamic> json) => ${className}Mapper.ensureInitialized().decodeMap<$className>(json);
}
''';
}

String getParameters(UniversalComponentClass dataClass) {
  if (dataClass.parameters.isNotEmpty) {
    return '{\n${_parametersToString(dataClass.parameters)}\n${indentation(2)}}';
  } else {
    return '';
  }
}

String getFields(UniversalComponentClass dataClass) {
  if (dataClass.parameters.isNotEmpty) {
    return '${_fieldsToString(dataClass.parameters)}\n';
  } else {
    return '';
  }
}

String _fieldsToString(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '${_jsonKey(e)}${indentation(2)}final ${e.toSuitableType(ProgrammingLanguage.dart)} ${e.name};',
      )
      .join('\n');
}

String _parametersToString(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .mapIndexed(
        (i, e) =>
            '${indentation(4)}${_required(e)}this.${e.name}${getDefaultValue(e)},',
      )
      .join('\n');
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t) {
  if (t.jsonKey == null || t.name == t.jsonKey) {
    return '';
  }
  return "${indentation(2)}@MappableField(key: '${protectJsonKey(t.jsonKey)}')\n";
}

String getDefaultValue(UniversalType t) {
  if (t.defaultValue == null) {
    return '';
  }
  return ' = ${_defaultValue(t)}';
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) =>
    '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(
        t.defaultValue,
        type: t.type,
      )}';
