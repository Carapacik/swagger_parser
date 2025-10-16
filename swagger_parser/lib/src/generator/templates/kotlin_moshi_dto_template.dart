import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

/// Provides template for generating kotlin DTO using Moshi
String kotlinMoshiDtoTemplate(UniversalComponentClass dataClass) {
  return '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

${descriptionComment(dataClass.description)}@JsonClass(generateAdapter = true)
data class ${dataClass.name.toPascal}(${_parameters(dataClass.parameters)}${dataClass.parameters.isNotEmpty ? '\n)' : ')'}
''';
}

String _parameters(Set<UniversalType> parameters) => parameters
    .map(
      (e) => '\n${descriptionComment(e.description, tab: '    ')}'
          '${e.jsonKey != null && e.name != e.jsonKey ? '    @Json("${protectJsonKey(e.jsonKey)}")\n' : ''}    '
          'var ${e.name}: ${e.toSuitableType(ProgrammingLanguage.kotlin, useMultipartFile: false)}'
          '${e.defaultValue != null ? ' = ${protectDefaultValue(e.defaultValue, type: e.type, dart: false)}' : ''},',
    )
    .join();
