import '../../parser/model/normalized_identifier.dart';
import '../../parser/swagger_parser_core.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

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
