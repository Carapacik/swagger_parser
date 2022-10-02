import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_request.dart';
import 'package:swagger_parser/src/generator/models/universal_request_type.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/utils/case_utils.dart';
import 'package:swagger_parser/src/utils/utils.dart';

/// Return file contents for kotlin retrofit client
/// File contents are generated using universal rest client
String kotlinRetrofitClientTemplate({
  required final UniversalRestClient restClient,
}) {
  final sb = StringBuffer('''
import retrofit2.http.*

interface ${restClient.name.toPascal}Client {''');
  for (final request in restClient.requests) {
    sb.write(_toClientRequest(request: request));
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest({required final UniversalRequest request}) {
  final sb = StringBuffer('''

    ${request.isMultiPart ? '@MultiPart\n    ' : ''}@${request.requestType.name.toUpperCase()}("${request.route}")
    suspend fun ${request.name}(''');
  if (request.parameters.isEmpty) {
    sb.write(')\n');
    return sb.toString();
  }
  if (request.parameters.isNotEmpty) {
    final queryParameters = request.parameters
        .map((e) => '\n${_toQueryParameter(parameter: e)}')
        .join(',');
    sb.write(queryParameters);
  }
  if (request.returnType == null) {
    sb.write('\n    )\n');
    return sb.toString();
  }
  sb.write(
    '\n    ): ${toSuitableType(request.returnType!, ProgrammingLanguage.kotlin)}\n',
  );
  return sb.toString();
}

String _toQueryParameter({required final UniversalRequestType parameter}) =>
    '        @${parameter.parameterType.type}${parameter.parameterType.isBody ? '' : '("${parameter.name}")'} ${parameter.type.name!.toCamel}: ${toSuitableType(parameter.type, ProgrammingLanguage.kotlin)}';
