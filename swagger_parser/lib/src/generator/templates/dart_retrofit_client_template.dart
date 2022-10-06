import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_request.dart';
import '../models/universal_request_type.dart';
import '../models/universal_rest_client.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required UniversalRestClient restClient,
  String? postfix,
}) {
  final name = postfix != null ? restClient.name.toPascal + postfix : 'Client';

  final sb = StringBuffer(
    '''
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
${dartImports(imports: restClient.imports, pathPrefix: '../shared_models/')}
part '${postfix != null ? restClient.name.toSnake : 'rest_client'}.g.dart';

@RestApi()
abstract class $name {
  factory $name(Dio dio, {required String baseUrl}) = _$name;
''',
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

  ${request.isMultiPart ? '@MultiPart()\n  ' : ''}@${request.requestType.name.toUpperCase()}('${request.route}')
  Future<${request.returnType == null ? 'void' : toSuitableType(request.returnType!, ProgrammingLanguage.dart)}> ${request.name}(''',
  );
  if (request.parameters.isNotEmpty) {
    sb.write('{\n');
  }
  for (final parameter in request.parameters) {
    sb.write('${_toQueryParameter(parameter)}\n');
  }
  if (request.parameters.isNotEmpty) {
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _toQueryParameter(UniversalRequestType parameter) =>
    "    @${parameter.parameterType.type}(${parameter.name != null ? "${parameter.parameterType.isPart ? 'name: ' : ''}'${parameter.name}'" : ''}) "
    'required ${toSuitableType(parameter.type, ProgrammingLanguage.dart)} ${parameter.type.name!.toCamel},';
