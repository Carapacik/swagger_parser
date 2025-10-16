import 'package:collection/collection.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:swagger_parser/src/utils/base_utils.dart';
import 'package:swagger_parser/src/utils/type_utils.dart';

/// Provides template for generating dart typedefs using JSON serializable
String dartTypeDefTemplate(UniversalComponentClass dataClass,
    {required bool useMultipartFile}) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  final import = dataClass.imports.firstOrNull;
  if (type == null) {
    return '';
  }
  return '${import != null ? "import '${import.toSnake}.dart';\nexport '${import.toSnake}.dart';\n\n" : ''}'
      '${descriptionComment(dataClass.description)}'
      'typedef $className = ${type.toSuitableType(ProgrammingLanguage.dart, useMultipartFile: useMultipartFile)};\n';
}
