import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_request.dart';
import 'package:swagger_parser/src/generator/models/universal_request_type.dart';
import 'package:swagger_parser/src/generator/models/universal_rest_client.dart';
import 'package:swagger_parser/src/utils/case_utils.dart';
import 'package:swagger_parser/src/utils/utils.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required final UniversalRestClient restClient,
}) {
  final sb = StringBuffer('''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
${dartImports(imports: restClient.imports, pathPrefix: '../shared_models/')}
part 'rest_client.g.dart';

@RestApi()
abstract class Client {
  factory Client(Dio dio, {required String baseUrl}) = _Client;
''');
  for (final request in restClient.requests) {
    sb.write(_toClientRequest(request: request));
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest({required final UniversalRequest request}) {
  final sb = StringBuffer('''

  ${request.isMultiPart ? '@MultiPart()\n  ' : ''}@${request.requestType.name.toUpperCase()}('${request.route}')
  Future<${request.returnType == null ? 'void' : toSuitableType(request.returnType!, ProgrammingLanguage.dart)}> ${request.name}(''');
  if (request.parameters.isNotEmpty) {
    sb.write('{\n');
  }
  for (final parameter in request.parameters) {
    sb.write('${_toQueryParameter(parameter: parameter)}\n');
  }
  if (request.parameters.isNotEmpty) {
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _toQueryParameter({required final UniversalRequestType parameter}) =>
    "    @${parameter.parameterType.type}(${parameter.name != null ? "${parameter.parameterType.isPart ? 'name: ' : ''}'${parameter.name}'" : ''}) "
    'required ${toSuitableType(parameter.type, ProgrammingLanguage.dart)} ${parameter.type.name!.toCamel},';
