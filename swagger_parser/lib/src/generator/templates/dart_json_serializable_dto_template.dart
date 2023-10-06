import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_language.dart';
import '../models/universal_data_class.dart';
import '../models/universal_type.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
}) {
  final className = dataClass.name.toPascal;
  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}${ioImport(dataClass)}import 'package:json_annotation/json_annotation.dart';
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
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .map((e) => '\n    ${_required(e)}this.${e.name}${_defaultValue(e)},')
      .join();
}

/// if jsonKey is different from the name
String _jsonKey(UniversalType t) {
  if (t.jsonKey == null || t.name == t.jsonKey) {
    return '';
  }
  return "  @JsonKey(name: '${t.jsonKey}')\n";
}

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.arrayDepth > 0 ? 'const ' : ''}'
        '${t.type.quoterForStringType()}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue)?.toCamel}' : protectDefaultValue(t.defaultValue)}'
        '${t.type.quoterForStringType()}'
    : '';
