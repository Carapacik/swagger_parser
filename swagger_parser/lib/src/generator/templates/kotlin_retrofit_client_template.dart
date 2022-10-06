import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_request.dart';
import '../models/universal_request_type.dart';
import '../models/universal_rest_client.dart';

/// Return file contents for kotlin retrofit client
/// File contents are generated using universal rest client
String kotlinRetrofitClientTemplate({
  required UniversalRestClient restClient,
  String? postfix,
}) {
  final name = postfix != null ? restClient.name.toPascal + postfix : 'Client';
  final sb = StringBuffer(
    '''
import retrofit2.http.*

interface $name {''',
  );
  for (final request in restClient.requests) {
    sb.write(_toClientRequest(request));
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(UniversalRequest request) {
  final sb = StringBuffer(
    '''

    ${request.isMultiPart ? '@MultiPart\n    ' : ''}@${request.requestType.name.toUpperCase()}("${request.route}")
    suspend fun ${request.name}(''',
  );
  if (request.parameters.isEmpty) {
    sb.write(')\n');
    return sb.toString();
  }
  if (request.parameters.isNotEmpty) {
    final queryParameters =
        request.parameters.map((e) => '\n${_toQueryParameter(e)}').join(',');
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

String _toQueryParameter(UniversalRequestType parameter) =>
    '        @${parameter.parameterType.type}${parameter.parameterType.isBody ? '' : '("${parameter.name}")'} ${parameter.type.name!.toCamel}: ${toSuitableType(parameter.type, ProgrammingLanguage.kotlin)}';
