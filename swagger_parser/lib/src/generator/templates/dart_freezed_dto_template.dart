import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_component_class.dart';
import '../models/universal_type.dart';

/// Provides template for generating dart DTO using freezed
String dartFreezedDtoTemplate(UniversalComponentClass dataClass) {
  final className = dataClass.name.toPascal;
  return '''
${ioImport(dataClass)}import 'package:freezed_annotation/freezed_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.freezed.dart';
part '${dataClass.name.toSnake}.g.dart';

${descriptionComment(dataClass.description)}@Freezed()
class $className with _\$$className {
  const factory $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersToString(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''}) = _$className;
  \n  factory $className.fromJson(Map<String, Object?> json) => _\$${className}FromJson(json);
}
''';
}

String _parametersToString(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .map(
        (e) => '\n${descriptionComment(e.description, tab: '    ')}'
            '${_jsonKey(e)}    ${_r(e)}'
            '${e.toSuitableType(ProgrammingLanguage.dart)} ${e.name},',
      )
      .join();
}

String _jsonKey(UniversalType t) {
  final sb = StringBuffer();
  if ((t.jsonKey == null || t.name == t.jsonKey) && t.defaultValue == null) {
    return '';
  }
  if (t.jsonKey != null && t.name != t.jsonKey) {
    sb.write("    @JsonKey(name: '${t.jsonKey}')\n");
  }
  if (t.defaultValue != null) {
    sb.write('    @Default(${_d(t)})\n');
  }

  return sb.toString();
}

/// return required if isRequired
String _r(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _d(UniversalType t) => '${t.type.quoterForStringType()}'
    '${t.enumType != null ? '${t.type}.${prefixForEnumItems(t.enumType!, t.defaultValue!)}' : t.defaultValue}'
    '${t.type.quoterForStringType()}';
