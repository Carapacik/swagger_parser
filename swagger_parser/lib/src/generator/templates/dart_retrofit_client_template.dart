import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required UniversalRestClient restClient,
  required String name,
  required bool markFileAsGenerated,
  required String defaultContentType,
  required bool useMultipartFile,
  bool extrasParameterByDefault = false,
  bool dioOptionsParameterByDefault = false,
  bool originalHttpResponse = false,
}) {
  final parameterTypes = restClient.requests
      .expand((r) => r.parameters.map((p) => p.type))
      .toSet();
  final sb = StringBuffer('''
${generatedFileComment(markFileAsGenerated: markFileAsGenerated)}${_convertImport(restClient)}${ioImport(parameterTypes, useMultipartFile: useMultipartFile)}import 'package:dio/dio.dart'${_hideHeaders(restClient, defaultContentType)};
import 'package:retrofit/retrofit.dart';
${dartImports(imports: restClient.imports, pathPrefix: '../models/')}
part '${name.toSnake}.g.dart';

@RestApi()
abstract class $name {
  factory $name(Dio dio, {String? baseUrl}) = _$name;
''');
  for (final request in restClient.requests) {
    sb.write(
      _toClientRequest(request, defaultContentType,
          originalHttpResponse: originalHttpResponse,
          extrasParameterByDefault: extrasParameterByDefault,
          dioOptionsParameterByDefault: dioOptionsParameterByDefault,
          useMultipartFile: useMultipartFile),
    );
  }
  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(
  UniversalRequest request,
  String defaultContentType, {
  required bool originalHttpResponse,
  required bool extrasParameterByDefault,
  required bool dioOptionsParameterByDefault,
  required bool useMultipartFile,
}) {
  final responseType = request.returnType == null
      ? 'void'
      : request.returnType!.toSuitableType(
          ProgrammingLanguage.dart,
          useMultipartFile: useMultipartFile,
        );

  // Check if this is a binary response (file download)
  final isBinaryResponse = request.returnType?.format == 'binary' ||
      (request.returnType?.type == 'string' &&
          request.returnType?.format == 'binary');

  // For binary responses, we need to use HttpResponse<List<int>> and add @DioResponseType
  final finalResponseType = isBinaryResponse
      ? 'HttpResponse<List<int>>'
      : (originalHttpResponse ? 'HttpResponse<$responseType>' : responseType);

  // Add @DioResponseType(ResponseType.bytes) for binary responses - after @GET
  final dioResponseTypeAnnotation =
      isBinaryResponse ? '\n  @DioResponseType(ResponseType.bytes)' : '';

  final sb = StringBuffer(
    '''

  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ', end: '  ')}${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}${_contentTypeHeader(request, defaultContentType)}@${request.requestType.name.toUpperCase()}('${request.route}')$dioResponseTypeAnnotation
  Future<$finalResponseType> ${request.name}(''',
  );
  if (request.parameters.isNotEmpty ||
      extrasParameterByDefault ||
      dioOptionsParameterByDefault) {
    sb.write('{\n');
  }
  final sortedByRequired = List<UniversalRequestType>.from(
    request.parameters.sorted((a, b) => a.type.compareTo(b.type)),
  );
  for (final parameter in sortedByRequired) {
    sb.write('${_toParameter(parameter, useMultipartFile)}\n');
  }
  if (extrasParameterByDefault) {
    sb.write(_addExtraParameter());
  }
  if (dioOptionsParameterByDefault) {
    sb.write(_addDioOptionsParameter());
  }
  if (request.parameters.isNotEmpty ||
      extrasParameterByDefault ||
      dioOptionsParameterByDefault) {
    sb.write('  });\n');
  } else {
    sb.write(');\n');
  }
  return sb.toString();
}

String _convertImport(UniversalRestClient restClient) =>
    restClient.requests.any(
      (r) => r.parameters.any((e) => e.parameterType.isPart),
    )
        ? "import 'dart:convert';\n"
        : '';

String _addExtraParameter() => '    @Extras() Map<String, dynamic>? extras,\n';

String _addDioOptionsParameter() =>
    '    @DioOptions() RequestOptions? options,\n';

String _toParameter(UniversalRequestType parameter, bool useMultipartFile) {
  var parameterType = parameter.type.toSuitableType(
    ProgrammingLanguage.dart,
    useMultipartFile: useMultipartFile,
  );
  // https://github.com/trevorwang/retrofit.dart/issues/631
  // https://github.com/Carapacik/swagger_parser/issues/110
  if (parameter.parameterType.isBody &&
      (parameterType == 'Object' || parameterType == 'Object?')) {
    parameterType = 'dynamic';
  }

  // https://github.com/trevorwang/retrofit.dart/issues/661
  // The Word `value` cant be used a a keyword argument
  final keywordArguments = parameter.type.name!.toCamel.replaceFirst(
    'value',
    'value_',
  );

  return '    @${parameter.parameterType.type}'
      "(${parameter.name != null && !parameter.parameterType.isBody ? "${parameter.parameterType.isPart ? 'name: ' : ''}${_startWith$(parameter.name!) ? 'r' : ''}'${parameter.name}'" : ''}) "
      '${_required(parameter.type)}'
      '$parameterType '
      '$keywordArguments${_defaultValue(parameter.type)},';
}

String _contentTypeHeader(UniversalRequest request, String defaultContentType) {
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
String _required(UniversalType t) => t.isRequired ? 'required ' : '';

/// return defaultValue if have and not required
String _defaultValue(UniversalType t) => !t.isRequired && t.defaultValue != null
    ? ' = '
        '${t.wrappingCollections.isNotEmpty ? 'const ' : ''}'
        '${t.enumType != null ? '${t.type}.${protectDefaultEnum(t.defaultValue?.toCamel)?.toCamel}' : protectDefaultValue(t.defaultValue, type: t.type)}'
    : '';

bool _startWith$(String name) => name.isNotEmpty && name.startsWith(r'$');
