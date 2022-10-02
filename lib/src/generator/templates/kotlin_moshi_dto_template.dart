import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_data_class.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:swagger_parser/src/utils/case_utils.dart';
import 'package:swagger_parser/src/utils/utils.dart';

/// Provides template for generating kotlin DTO using Moshi
String kotlinMoshiDtoTemplate({
  required final UniversalDataClass dataClass,
}) {
  return '''
import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class ${dataClass.name.toPascal}(${_parameters(dataClass.parameters)}
)
''';
}

String _parameters(final List<UniversalType> parameters) => parameters
    .map(
      (e) => '${e.name != e.jsonKey ? '\n    @Json("${e.jsonKey}")' : ''}\n    '
          'var ${e.name}: ${toSuitableType(e, ProgrammingLanguage.kotlin)}',
    )
    .join(',');
