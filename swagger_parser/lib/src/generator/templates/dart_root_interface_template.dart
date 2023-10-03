import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/open_api_info.dart';

String dartRootInterfaceTemplate({
  required OpenApiInfo openApiInfo,
  required Set<String> clientsNames,
  required String postfix,
  required bool squishClients,
}) {
  if (clientsNames.isEmpty) {
    return '';
  }

  final title = openApiInfo.title;
  final summary = openApiInfo.summary;
  final description = openApiInfo.description;
  final version = openApiInfo.version;
  final fulldescription = switch ((summary, description)) {
    (null, null) => null,
    (_, null) => summary,
    (null, _) => description,
    (_, _) => '$summary\n\n$description',
  };

  final comment =
      '${title ?? ''}${version != null ? ' `v$version`' : ''}${fulldescription != null ? '\n\n$fulldescription' : ''}';

  return '''
import 'package:dio/dio.dart';
${_clientsImport(clientsNames, postfix, squishClients: squishClients)}
abstract class IRestClient {
${_interfaceGetters(clientsNames, postfix)}
}

${descriptionComment(comment)}class RestClient implements IRestClient {
  RestClient({
    required Dio dio,
    required String baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String _baseUrl;

${_p(clientsNames, postfix)}

${_r(clientsNames, postfix)}
}
''';
}

String _clientsImport(
  Set<String> imports,
  String postfix, {
  required bool squishClients,
}) =>
    '\n${imports.map(
          (import) => "import '${squishClients ? 'clients' : import.toSnake}/"
              "${'${import}_$postfix'.toSnake}.dart';",
        ).join('\n')}\n';

String _interfaceGetters(Set<String> names, String postfix) => names
    .map((n) => '  ${n.toPascal + postfix.toPascal} get ${n.toCamel};')
    .join('\n\n');

String _p(Set<String> names, String postfix) => names
    .map((n) => '  ${n.toPascal + postfix.toPascal}? _${n.toCamel};')
    .join('\n');

String _r(Set<String> names, String postfix) => names
    .map(
      (n) =>
          '  @override\n  ${n.toPascal + postfix.toPascal} get ${n.toCamel} => '
          '_${n.toCamel} ??= ${n.toPascal + postfix.toPascal}(_dio, baseUrl: _baseUrl);',
    )
    .join('\n\n');
