import '../../parser/swagger_parser_core.dart';
import '../../parser/utils/case_utils.dart';
import '../../utils/base_utils.dart';

String dartRootClientTemplate({
  required OpenApiInfo openApiInfo,
  required String name,
  required Set<String> clientsNames,
  required String postfix,
  required bool putClientsInFolder,
  required bool markFileAsGenerated,
}) {
  if (clientsNames.isEmpty) {
    return '';
  }

  final className = name.toPascal;

  final title = openApiInfo.title;
  final summary = openApiInfo.summary;
  final description = openApiInfo.description;
  final version = openApiInfo.apiVersion;
  final fullDescription = switch ((summary, description)) {
    (null, null) => null,
    (_, null) => summary,
    (null, _) => description,
    (_, _) => '$summary\n\n$description',
  };

  final comment =
      '${title ?? ''}${version != null ? ' `v$version`' : ''}${fullDescription != null ? '\n\n$fullDescription' : ''}';

  return '''
${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}import 'package:dio/dio.dart';
${_clientsImport(clientsNames, postfix, putClientsInFolder: putClientsInFolder)}
${descriptionComment(comment)}class $className {
  $className(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '${openApiInfo.apiVersion ?? ''}';

${_privateFields(clientsNames, postfix)}

${_getters(clientsNames, postfix)}
}
''';
}

String _clientsImport(
  Set<String> imports,
  String postfix, {
  required bool putClientsInFolder,
}) =>
    '\n${imports.map(
          (import) =>
              "import '${putClientsInFolder ? 'clients' : import.toSnake}/"
              "${'${import}_$postfix'.toSnake}.dart';",
        ).join('\n')}\n';

String _privateFields(Set<String> names, String postfix) => names
    .map((n) => '  ${n.toPascal + postfix.toPascal}? _${n.toCamel};')
    .join('\n');

String _getters(Set<String> names, String postfix) => names
    .map(
      (n) => '  ${n.toPascal + postfix.toPascal} get ${n.toCamel} => '
          '_${n.toCamel} ??= ${n.toPascal + postfix.toPascal}(_dio, baseUrl: _baseUrl);',
    )
    .join('\n\n');
