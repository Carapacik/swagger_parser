import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required UniversalRestClient restClient,
  required String name,
  required String defaultContentType,
  required bool useMultipartFile,
  bool extrasParameterByDefault = false,
  bool dioOptionsParameterByDefault = false,
  bool addOpenApiMetadata = false,
  bool originalHttpResponse = false,
  String? fileName,
}) {
  final parameterTypes = restClient.requests
      .expand((r) => r.parameters.map((p) => p.type))
      .toSet();
  final includeExtras = extrasParameterByDefault;
  final includeMetadata = addOpenApiMetadata;
  final sb = StringBuffer('''
${_convertImport(restClient)}${ioImport(parameterTypes, useMultipartFile: useMultipartFile)}import 'package:dio/dio.dart'${_hideHeaders(restClient, defaultContentType)};
import 'package:retrofit/retrofit.dart';
${dartImports(imports: restClient.imports, pathPrefix: '../models/')}
part '${fileName ?? name.toSnake}.g.dart';

@RestApi()
abstract class $name {
  factory $name(Dio dio, {String? baseUrl}) = _$name;
''');

  if (includeMetadata && restClient.requests.isNotEmpty) {
    sb.write('\n');
    for (final request in restClient.requests) {
      sb.write(_openApiExtrasConst(request));
    }
  }

  for (final request in restClient.requests) {
    final openApiExtrasConstName =
        includeMetadata ? _openApiConstName(request) : null;
    sb
      ..write('\n')
      ..write(
        _toClientRequest(
          request,
          defaultContentType,
          className: name,
          originalHttpResponse: originalHttpResponse,
          addExtrasParameter: includeExtras,
          addDioOptionsParameter: dioOptionsParameterByDefault,
          includeMetadata: includeMetadata,
          useMultipartFile: useMultipartFile,
          openApiExtrasConstName: openApiExtrasConstName,
        ),
      );
  }

  sb.write('}\n');
  return sb.toString();
}

String _toClientRequest(
  UniversalRequest request,
  String defaultContentType, {
  required String className,
  required bool originalHttpResponse,
  required bool addExtrasParameter,
  required bool addDioOptionsParameter,
  required bool includeMetadata,
  required bool useMultipartFile,
  String? openApiExtrasConstName,
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

  final defaultExtras = includeMetadata && addExtrasParameter
      ? _openApiExtrasReference(
          openApiExtrasConstName,
          request,
          className: className,
        )
      : null;

  final sb = StringBuffer()
    ..write(
      "  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ', end: '  ')}${request.isDeprecated ? "@Deprecated('This method is marked as deprecated')\n  " : ''}${_contentTypeHeader(request, defaultContentType)}@${request.requestType.name.toUpperCase()}('${request.route}')$dioResponseTypeAnnotation\n  Future<$finalResponseType> ${request.name}(",
    );

  if (request.parameters.isNotEmpty ||
      addExtrasParameter ||
      addDioOptionsParameter) {
    sb.write('{\n');
  }

  final sortedByRequired = List<UniversalRequestType>.from(
    request.parameters.sorted((a, b) => a.type.compareTo(b.type)),
  );
  for (final parameter in sortedByRequired) {
    sb.write('${_toParameter(parameter, useMultipartFile)}\n');
  }
  if (addExtrasParameter) {
    sb.write(_addExtraParameter(defaultExtras));
  }
  if (addDioOptionsParameter) {
    sb.write(_addDioOptionsParameter());
  }

  if (request.parameters.isNotEmpty ||
      addExtrasParameter ||
      addDioOptionsParameter) {
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

String _addExtraParameter(String? defaultExtras) =>
    '    @Extras() Map<String, dynamic>? extras${defaultExtras != null ? ' =\n        $defaultExtras' : ''},\n';

String _openApiExtrasReference(
  String? openApiExtrasConstName,
  UniversalRequest request, {
  required String className,
}) {
  return openApiExtrasConstName != null
      ? '$className.$openApiExtrasConstName'
      : _openApiExtrasLiteral(request);
}

String _openApiExtrasConst(UniversalRequest request) =>
    '  static const Map<String, dynamic> ${_openApiConstName(request)} =\n'
    '      ${_openApiExtrasLiteral(request)};\n';

String _openApiConstName(UniversalRequest request) =>
    '${request.name}OpenapiExtras';

String _openApiExtrasLiteral(UniversalRequest request) {
  final tags = request.tags.map(_quoteJson).join(', ');
  final operationId = _quoteJson(request.operationId ?? request.name);
  final externalDocsUrl = request.externalDocsUrl != null
      ? _quoteJson(request.externalDocsUrl!)
      : 'null';
  return '''
<String, dynamic>{
    'openapi': <String, dynamic>{
      'tags': <String>[$tags],
      'operationId': $operationId,
      'externalDocsUrl': $externalDocsUrl,
    },
  }''';
}

String _quoteJson(String value) =>
    '"${value.replaceAll(r'\\', r'\\\\').replaceAll('"', r'\\"')}"';

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
  final keywordArguments = parameter.type.name!.replaceFirst(
    'value',
    'value_',
  );

  final deprecatedAnnotation = parameter.deprecated
      ? "    @Deprecated('This is marked as deprecated')\n"
      : '';

  return '$deprecatedAnnotation    @${parameter.parameterType.type}'
      "(${parameter.name != null && !parameter.parameterType.isBody ? "${parameter.parameterType.isPart ? 'name: ' : ''}${_startsWithDollar(parameter.name!) ? 'r' : ''}'${parameter.name}'" : ''}) "
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

bool _startsWithDollar(String name) => name.isNotEmpty && name.startsWith(r'$');
