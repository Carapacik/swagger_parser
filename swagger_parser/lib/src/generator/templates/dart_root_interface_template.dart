import '../../utils/case_utils.dart';

String dartRootInterfaceTemplate({
  required Set<String> clientsNames,
  required String postfix,
  required bool squishClients,
}) {
  if (clientsNames.isEmpty) {
    return '';
  }
  return '''
import 'package:dio/dio.dart';
${_clientsImport(clientsNames, postfix, squishClients: squishClients)}
abstract class IRestClient {
${_interfaceGetters(clientsNames, postfix)}
}

class RestClient implements IRestClient {
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
