import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/json_serializer.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

String getStaticFieldName(UniversalRequest request) => request.name.toCamel;

/// Provides template for generating dart Retrofit client
String dartRetrofitClientTemplate({
  required UniversalRestClient restClient,
  required String name,
  required String defaultContentType,
  required bool useMultipartFile,
  required bool generateUrlsConstants,
  bool useDartMappableNaming = false,
  bool extrasParameterByDefault = false,
  bool dioOptionsParameterByDefault = false,
  bool addOpenApiMetadata = false,
  bool originalHttpResponse = false,
  bool useFlutterCompute = false,
  String? fileName,
  JsonSerializer? jsonSerializer,
}) {
  // For non-freezed serializers, apply sealed naming to union imports and types
  final applySealedNaming =
      jsonSerializer != null && jsonSerializer != JsonSerializer.freezed;
  final parameterTypes = restClient.requests
      .expand((r) => r.parameters.map((p) => p.type))
      .toSet();
  final includeExtras = extrasParameterByDefault;
  final includeMetadata = addOpenApiMetadata;

  // Determine @RestApi annotation
  final restApiAnnotation = useFlutterCompute
      ? '@RestApi(parser: Parser.FlutterCompute)'
      : jsonSerializer == JsonSerializer.dartMappable && useDartMappableNaming
          ? '@RestApi(parser: Parser.DartMappable)'
          : '@RestApi()';

  // Flutter foundation import for compute function
  final flutterComputeImport = useFlutterCompute
      ? "import 'package:flutter/foundation.dart' show compute;\n"
      : '';

  // Transform imports for sealed naming if needed
  final imports = applySealedNaming
      ? restClient.imports.map(_applySealedNamingToImport).toSet()
      : restClient.imports;

  final sb = StringBuffer('''
${_convertImport(restClient)}${ioImport(parameterTypes, useMultipartFile: useMultipartFile)}${_typedDataImport(restClient)}import 'package:dio/dio.dart'${_hideHeaders(restClient, defaultContentType)};
${flutterComputeImport}import 'package:retrofit/retrofit.dart';
${dartImports(imports: imports, pathPrefix: '../models/')}
part '${fileName ?? name.toSnake}.g.dart';

$restApiAnnotation
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
          clientName: name,
          originalHttpResponse: originalHttpResponse,
          addExtrasParameter: includeExtras,
          addDioOptionsParameter: dioOptionsParameterByDefault,
          includeMetadata: includeMetadata,
          useMultipartFile: useMultipartFile,
          generateUrlsConstants: generateUrlsConstants,
          openApiExtrasConstName: openApiExtrasConstName,
          applySealedNaming: applySealedNaming,
        ),
      );
  }

  sb.write('}\n');
  if (generateUrlsConstants) {
    sb.write(
      '''
\n
abstract class ${name}Urls {
${restClient.requests.map((e) => '\t/// ${e.route}\n\tstatic const ${getStaticFieldName(e)} = "${e.route}";').join('\n')}
}\n
''',
    );
  }

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
  required String clientName,
  required bool generateUrlsConstants,
  String? openApiExtrasConstName,
  bool applySealedNaming = false,
}) {
  var responseType = request.returnType == null
      ? 'void'
      : request.returnType!.toSuitableType(
          ProgrammingLanguage.dart,
          useMultipartFile: useMultipartFile,
        );

  // Apply sealed naming transformation to response type if needed
  if (applySealedNaming) {
    responseType = _renameUnionTypes(responseType);
  }

  String finalResponseType;
  String dioResponseTypeAnnotation;
  if (_hasBinaryResponse(request)) {
    // Retrofit supports streaming and SSE, but only for event types of [String]
    // or [Uint8List], also the [DioResponseType] **must** be set to
    // [ResponseType.stream].
    //
    //See https://github.com/trevorwang/retrofit.dart/tree/master#streaming-and-server-sent-events-sse
    final eventType =
        request.returnType?.type == 'string' ? 'String' : 'Uint8List';
    finalResponseType = 'Stream<$eventType>';
    dioResponseTypeAnnotation = '\n  @DioResponseType(ResponseType.stream)';
  } else {
    finalResponseType =
        (originalHttpResponse ? 'HttpResponse<$responseType>' : responseType);
    finalResponseType = 'Future<$finalResponseType>';
    dioResponseTypeAnnotation = '';
  }

  final defaultExtras = includeMetadata && addExtrasParameter
      ? _openApiExtrasReference(
          openApiExtrasConstName,
          request,
          className: className,
        )
      : null;

  final requestAnnotation = generateUrlsConstants
      ? '@${request.requestType.name.toUpperCase()}(${clientName}Urls.${getStaticFieldName(request)})'
      : "@${request.requestType.name.toUpperCase()}('${request.route}')";

  final sb = StringBuffer()
    ..write(
        "  ${descriptionComment(request.description, tabForFirstLine: false, tab: '  ', end: '  ')}")
    ..write(request.isDeprecated
        ? "@Deprecated('This method is marked as deprecated')\n  "
        : '')
    ..write(_contentTypeHeader(request, defaultContentType))
    ..write(requestAnnotation)
    ..writeln(dioResponseTypeAnnotation)
    ..write('  $finalResponseType ')
    ..write('${request.name}(');

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

String _convertImport(UniversalRestClient restClient) {
  return restClient.requests.any(
    (r) =>
        _hasBinaryStringResponse(r) ||
        r.parameters.any((e) => e.parameterType.isPart),
  )
      ? "import 'dart:convert';\n"
      : '';
}

String _typedDataImport(UniversalRestClient restClient) {
  return restClient.requests.any(_hasBinaryResponse)
      ? "import 'dart:typed_data';\n"
      : '';
}

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

// Helper functions for sealed naming transformation
const _unionSuffix = 'Union';
const _snakeUnionSuffix = '_union';

String _applySealedNamingToImport(String import) {
  if (import.endsWith(_unionSuffix)) {
    return '${import.substring(0, import.length - _unionSuffix.length)}Sealed';
  }
  if (import.endsWith(_snakeUnionSuffix)) {
    return '${import.substring(0, import.length - _snakeUnionSuffix.length)}_sealed';
  }
  return import;
}

String _renameUnionTypes(String type) => type.replaceAllMapped(
      RegExp(r'([A-Z][A-Za-z0-9_]*)Union\b'),
      (match) => '${match.group(1)}Sealed',
    );

bool _hasBinaryResponse(UniversalRequest request) {
  return request.returnType?.format == 'binary' ||
      _hasBinaryStringResponse(request);
}

bool _hasBinaryStringResponse(UniversalRequest request) {
  return request.returnType?.type == 'string' &&
      request.returnType?.format == 'binary';
}
