import 'package:collection/collection.dart';

import '../../parser/model/universal_data_class.dart';
import '../../parser/model/universal_type.dart';
import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_language.dart';

/// Provides template for generating dart typedefs using JSON serializable
String dartTypeDefTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
}) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  final import = dataClass.imports.firstOrNull;
  if (type == null) {
    return '';
  }
  return '${generatedFileComment(
    markFileAsGenerated: markFileAsGenerated,
  )}${import != null ? "import '${import.toSnake}.dart';\n\n" : ''}'
      '${descriptionComment(dataClass.description)}'
      'typedef $className = ${type.toSuitableType(ProgrammingLanguage.dart)};\n';
}
