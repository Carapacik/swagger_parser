import 'package:collection/collection.dart';

import '../../parser/model/normalized_identifier.dart';
import '../../parser/swagger_parser_core.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

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
