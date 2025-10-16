import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

/// Return file contents for kotlin retrofit client
/// File contents are generated using universal rest client
String kotlinRetrofitClientTemplate({
  required UniversalRestClient restClient,
  required String name,
}) {
  final sb = StringBuffer('''
import retrofit2.http.*

interface $name {''');
  for (final request in restClient.requests) {
    sb.write(_toClientRequest(request));
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(UniversalRequest request) {
  final sb = StringBuffer('''

    ${descriptionComment(request.description, tabForFirstLine: false, tab: '    ', end: '    ')}${request.isDeprecated ? '@Deprecated("This method is marked as deprecated")\n    ' : ''}${request.isMultiPart ? '@MultiPart\n    ' : ''}${request.isFormUrlEncoded ? '@FormUrlEncoded\n    ' : ''}@${request.requestType.name.toUpperCase()}("${request.route}")
    suspend fun ${request.name}(''');
  if (request.parameters.isEmpty) {
    sb.write(')');
  } else {
    final queryParameters =
        request.parameters.map((e) => '\n${_toQueryParameter(e)},').join();
    sb.write(queryParameters);
  }
  if (request.returnType == null) {
    if (request.parameters.isEmpty) {
      sb.write('\n');
    } else {
      sb.write('\n    )\n');
    }
    return sb.toString();
  }
  if (request.parameters.isNotEmpty) {
    sb.write('\n    )');
  }

  sb.write(
    ': ${request.returnType!.toSuitableType(ProgrammingLanguage.kotlin, useMultipartFile: false)}\n',
  );
  return sb.toString();
}

String _toQueryParameter(UniversalRequestType parameter) =>
    '        @${parameter.parameterType.type}${parameter.name != null && !parameter.parameterType.isBody ? '("${parameter.name}")' : ''} '
    '${parameter.type.name!.toCamel}: ${parameter.type.toSuitableType(ProgrammingLanguage.kotlin, useMultipartFile: false)}'
    '${_defaultValue(parameter.type)}';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue?.toScreamingSnake)?.toScreamingSnake}' : protectDefaultValue(t.defaultValue, type: t.type, dart: false)}'
    : '';
