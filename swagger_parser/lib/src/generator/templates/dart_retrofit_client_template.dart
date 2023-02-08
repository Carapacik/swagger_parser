import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
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
  final partFile = postfix != null
      ? '${restClient.name.toSnake}_${postfix.toSnake}'
      : 'rest_client';
  final sb = StringBuffer(
    '''
${_fileImport(restClient)}import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

${dartImports(imports: restClient.imports, pathPrefix: '../shared_models/')}
part '$partFile.g.dart';

@RestApi()
abstract class $name {
  factory $name(Dio dio, {String baseUrl}) = _$name;
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
  final sortedByRequired = List<UniversalRequestType>.from(
    request.parameters.sorted((a, b) => a.type.compareTo(b.type)),
  );
  for (final parameter in sortedByRequired) {
    sb.write('${_toQueryParameter(parameter)}\n');
  }
  if (request.parameters.isNotEmpty) {
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _fileImport(UniversalRestClient restClient) => restClient.requests.any(
      (r) => r.parameters.any(
        (p) =>
            toSuitableType(
              p.type,
              ProgrammingLanguage.dart,
              isRequired: p.type.isRequired,
            ) ==
            'File',
      ),
    )
        ? "import 'dart:io';\n\n"
        : '';

String _toQueryParameter(UniversalRequestType parameter) =>
    "    @${parameter.parameterType.type}(${parameter.name != null ? "${parameter.parameterType.isPart ? 'name: ' : ''}'${parameter.name}'" : ''}) "
    '${parameter.type.isRequired && parameter.type.defaultValue == null ? 'required ' : ''}'
    '${toSuitableType(parameter.type, ProgrammingLanguage.dart, isRequired: parameter.type.isRequired)} '
    '${parameter.type.name!.toCamel}${parameter.type.defaultValue != null ? ' = ${parameter.type.type.quoterForStringType()}${parameter.type.defaultValue}${parameter.type.type.quoterForStringType()}' : ''},';
