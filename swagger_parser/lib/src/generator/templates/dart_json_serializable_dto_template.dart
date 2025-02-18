import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
}) {
  final className = dataClass.name.toPascal;
  return '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${ioImport(dataClass)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@JsonSerializable()
class $className {
  const $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, Object?> toJson() => _\$${className}ToJson(this);
}
''';
}

String _parametersInClass(List<UniversalType> parameters) => parameters
    .mapIndexed(
      (i, e) =>
          '\n${i != 0 && (e.description?.isNotEmpty ?? false) ? '\n' : ''}${descriptionComment(e.description, tab: '  ')}'
          '${_jsonKey(e)}  final ${e.toSuitableType(ProgrammingLanguage.dart)} ${e.name};',
    )
    .join();

String _parametersInConstructor(List<UniversalType> parameters) {
  final sortedByRequired = List<UniversalType>.from(
    parameters.sorted((a, b) => a.compareTo(b)),
  );
  return sortedByRequired
      .map((e) => '\n    ${_required(e)}this.${e.name}${_defaultValue(e)},')
      .join();
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t) {
  if (t.jsonKey == null || t.name == t.jsonKey) {
    return '';
  }
  return "  @JsonKey(name: '${protectJsonKey(t.jsonKey)}')\n";
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}'
    : '';
