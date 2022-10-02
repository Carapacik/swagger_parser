import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:swagger_parser/src/utils/case_utils.dart';
import 'package:swagger_parser/src/utils/utils.dart';

/// Provides template for generating dart DTO using JSON serializable
String dartJsonSerializableDtoTemplate({
  required final UniversalDataClass dataClass,
}) {
  final className = dataClass.name.toPascal;
  return '''
import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

@JsonSerializable()
class $className {
  const $className({${_parametersInConstructor(dataClass.parameters)}
  });
  
  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters)}
  
  Map<String, dynamic> toJson() => _\$${className}ToJson(this);
}
''';
}

String _parametersInClass(final List<UniversalType> parameters) => parameters
    .map(
      (e) =>
          '${e.name != e.jsonKey ? "\n  @JsonKey(name: '${e.jsonKey}')" : ''}\n  final '
          '${toSuitableType(e, ProgrammingLanguage.dart)} ${e.name};',
    )
    .join();

String _parametersInConstructor(final List<UniversalType> parameters) =>
    parameters.map((e) => '\n    required this.${e.name},').join();
