import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_component_class.dart';
import '../models/universal_type.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(UniversalComponentClass dataClass) {
  final className = dataClass.name.toPascal;
  return '''
${fileImport(dataClass)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

@JsonSerializable()
class $className {
  const $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, dynamic> toJson() => _\$${className}ToJson(this);
}
''';
}

String _parametersInClass(List<UniversalType> parameters) => parameters
    .map(
      (e) =>
          '${_jsonKey(e)}\n  final ${toSuitableType(e, ProgrammingLanguage.dart)} ${e.name};',
    )
    .join();

String _parametersInConstructor(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .map((e) => sortedByRequired
          .map((e) => '\n    ${e.isRequired ? 'required ' : ''}this.${e.name},')
          .join())
      .join();
}

String _jsonKey(UniversalType t) {
  final sb = StringBuffer();
  if ((t.jsonKey == null || t.name == t.jsonKey) && t.defaultValue == null) {
    return '';
  }
  sb.write('\n  @JsonKey(');
  if (t.defaultValue != null) {
    sb.write(
      'defaultValue: ${t.type.quoterForStringType()}'
      '${t.defaultValue}${t.type.quoterForStringType()}',
    );
  }

  if (t.defaultValue != null && (t.jsonKey != null && t.name != t.jsonKey)) {
    sb.write(', ');
  }
  if (t.jsonKey != null && t.name != t.jsonKey) {
    sb.write("name: '${t.jsonKey}'");
  }
  sb.write(')');
  return sb.toString();
}
