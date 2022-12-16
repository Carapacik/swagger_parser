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
import 'package:freezed_annotation/freezed_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.freezed.dart';
part '${dataClass.name.toSnake}.g.dart';

@freezed
class $className with _\$$className {
  const factory $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersToString(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''}) = _$className;
  \n  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
}
''';
}

String _parametersToString(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .map(
        (e) => '${_jsonKey(e)}\n    ${e.isRequired ? 'required ' : ''}'
            '${toSuitableType(e, ProgrammingLanguage.dart, isRequired: e.isRequired)} ${e.name},',
      )
      .join();
}

String _jsonKey(UniversalType t) {
  final sb = StringBuffer();
  if ((t.jsonKey == null || t.name == t.jsonKey) && t.defaultValue == null) {
    return '';
  }
  sb.write('\n    @JsonKey(');
  if (t.defaultValue != null) {
    sb.write(
      'defaultValue: ${t.type.quoterForStringType()}${t.defaultValue}${t.type.quoterForStringType()}',
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
