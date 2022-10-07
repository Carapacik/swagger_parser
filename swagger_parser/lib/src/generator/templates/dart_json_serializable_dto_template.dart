import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_data_class.dart';
import '../models/universal_type.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate(UniversalDataClass dataClass) {
  final className = dataClass.name.toPascal;
  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

@JsonSerializable()
class $className {
  $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, dynamic> toJson() => _\$${className}ToJson(this);
}
''';
}

String _parametersInClass(List<UniversalType> parameters) => parameters
    .map(
      (e) =>
          '${e.jsonKey != null && e.name != e.jsonKey ? "\n  @JsonKey(name: '${e.jsonKey}')" : ''}\n'
          '  final ${toSuitableType(e, ProgrammingLanguage.dart)} ${e.name};',
    )
    .join();

String _parametersInConstructor(List<UniversalType> parameters) =>
    parameters.map((e) => '\n    required this.${e.name},').join();
