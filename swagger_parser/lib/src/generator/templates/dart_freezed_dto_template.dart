import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_data_class.dart';
import '../models/universal_type.dart';

/// Provides template for generating dart DTO using freezed
String dartFreezedDtoTemplate(UniversalDataClass dataClass) {
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

String _parametersToString(List<UniversalType> parameters) => parameters
    .map(
      (e) =>
          '${e.jsonKey != null && e.name != e.jsonKey ? "\n    @JsonKey(name: '${e.jsonKey}') " : '\n    '}'
          'required ${toSuitableType(e, ProgrammingLanguage.dart)} ${e.name},',
    )
    .join();
