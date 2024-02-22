import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_language.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required UniversalRestClient restClient,
  required String name,
  required bool markFileAsGenerated,
  required String defaultContentType,
  bool originalHttpResponse = false,
}) {
  final sb = StringBuffer(
    '''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${_convertImport(restClient)}${_fileImport(restClient)}import 'package:dio/dio.dart'${_hideHeaders(restClient, defaultContentType)};
import 'package:retrofit/retrofit.dart';
${dartImports(imports: restClient.imports, pathPrefix: '../models/')}
part '${name.toSnake}.g.dart';

@RestApi()
abstract class $name {
  factory $name(Dio dio, {String? baseUrl}) = _$name;
''',
  );
  for (final request in restClient.requests) {
    sb.write(
      _toClientRequest(
        request,
        defaultContentType,
        originalHttpResponse: originalHttpResponse,
      ),
    );
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(
  UniversalRequest request,
  String defaultContentType, {
  required bool originalHttpResponse,
}) {
  final responseType = request.returnType == null
      ? 'void'
      : request.returnType!.toSuitableType(ProgrammingLanguage.dart);
  final sb = StringBuffer(
    '''

  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ', end: '  ')}${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}${_contentTypeHeader(request, defaultContentType)}@${request.requestType.name.toUpperCase()}('${request.route}')
  Future<${originalHttpResponse ? 'HttpResponse<$responseType>' : responseType}> ${request.name}(''',
  );
  if (request.parameters.isNotEmpty) {
    sb.write('{\n');
  }
  final sortedByRequired = List<UniversalRequestType>.from(
    request.parameters.sorted((a, b) => a.type.compareTo(b.type)),
  );
  for (final parameter in sortedByRequired) {
    sb.write('${_toParameter(parameter)}\n');
  }
  if (request.parameters.isNotEmpty) {
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _convertImport(UniversalRestClient restClient) =>
    restClient.requests.any(
      (r) => r.parameters.any(
        (e) => e.parameterType.isPart,
      ),
    )
        ? "import 'dart:convert';\n"
        : '';

String _fileImport(UniversalRestClient restClient) => restClient.requests.any(
      (r) => r.parameters.any(
        (e) => e.type.toSuitableType(ProgrammingLanguage.dart).contains('File'),
      ),
    )
        ? "import 'dart:io';\n\n"
        : '';

String _toParameter(UniversalRequestType parameter) {
  var parameterType = parameter.type.toSuitableType(ProgrammingLanguage.dart);
  // https://github.com/trevorwang/retrofit.dart/issues/631
  // https://github.com/Carapacik/swagger_parser/issues/110
  if (parameter.parameterType.isBody &&
      (parameterType == 'Object' || parameterType == 'Object?')) {
    parameterType = 'dynamic';
  }
  return "    @${parameter.parameterType.type}(${parameter.name != null && !parameter.parameterType.isBody ? "${parameter.parameterType.isPart ? 'name: ' : ''}'${parameter.name}'" : ''}) "
      '${_required(parameter.type)}'
      '$parameterType '
      '${parameter.type.name!.toCamel}${_defaultValue(parameter.type)},';
}

String _contentTypeHeader(
  UniversalRequest request,
  String defaultContentType,
) {
  if (request.isMultiPart) {
    return '@MultiPart()\n  ';
  }
  if (request.isFormUrlEncoded) {
    return '@FormUrlEncoded()\n  ';
  }
  if (request.contentType != defaultContentType) {
    return "@Headers(<String, String>{'Content-Type': '${request.contentType}'})\n  ";
  }
  return '';
}

/// ` hide Headers ` for retrofit Headers
String _hideHeaders(
  UniversalRestClient restClient,
  String defaultContentType,
) =>
    restClient.requests.any(
      (r) =>
          r.contentType != defaultContentType &&
          !(r.isMultiPart || r.isFormUrlEncoded),
    )
        ? ' hide Headers'
        : '';

/// return required if isRequired
String _required(UniversalType t) =>
    t.isRequired && t.defaultValue == null ? 'required ' : '';

/// return defaultValue if have
String _defaultValue(UniversalType t) => t.defaultValue != null
    ? ' = '
        '${t.arrayDepth > 0 ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue?.toCamel)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}'
    : '';
