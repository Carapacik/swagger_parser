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

  final formatDateToJsonFunction =
      dataClass.parameters.any((p) => p.format == 'date')
          ? '''

String _formatDateToJson(DateTime dateTime) {
  return DateFormat('yyyy-MM-dd').format(dateTime);
}
'''
          : '';

  return '''
${fileImport(dataClass)}${intlImport(dataClass)}import 'package:json_annotation/json_annotation.dart';
${dartImports(imports: dataClass.imports)}
part '${dataClass.name.toSnake}.g.dart';

@JsonSerializable()
class $className {
  const $className(${dataClass.parameters.isNotEmpty ? '{' : ''}${_parametersInConstructor(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n  }' : ''});
  
  factory $className.fromJson(Map<String, dynamic> json) => _\$${className}FromJson(json);
  ${_parametersInClass(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n' : ''}
  Map<String, dynamic> toJson() => _\$${className}ToJson(this);
}
$formatDateToJsonFunction''';
}

String _parametersInClass(List<UniversalType> parameters) => parameters
    .map(
      (e) =>
          '${_jsonKey(e)}\n  final ${toSuitableType(e, ProgrammingLanguage.dart, isRequired: e.isRequired)} ${e.name};',
    )
    .join();

String _parametersInConstructor(List<UniversalType> parameters) {
  final sortedByRequired =
      List<UniversalType>.from(parameters.sorted((a, b) => a.compareTo(b)));
  return sortedByRequired
      .map((e) => '\n    ${e.isRequired ? 'required ' : ''}this.${e.name},')
      .join();
}

String _jsonKey(UniversalType t) {
  final hasDefaultValue = t.defaultValue != null;
  final hasJsonKeyAndDifferentFromName =
      t.jsonKey != null && t.name != t.jsonKey;
  final hasStringAsDate = t.type == 'string' && t.format == 'date';

  if (!hasDefaultValue && !hasJsonKeyAndDifferentFromName && !hasStringAsDate) {
    return '';
  }

  final quote = t.type.quoterForStringType();
  final jsonKeyAttr = <String>[
    if (hasDefaultValue) 'defaultValue: $quote${t.defaultValue}$quote',
    if (hasJsonKeyAndDifferentFromName) "name: '${t.jsonKey}'",
    if (hasStringAsDate) 'toJson: _formatDateToJson'
  ];

  return jsonKeyAttr.isNotEmpty
      ? '\n  @JsonKey(${jsonKeyAttr.join(', ')})'
      : '';
}
