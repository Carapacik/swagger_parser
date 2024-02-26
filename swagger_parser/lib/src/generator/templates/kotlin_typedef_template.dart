import 'package:collection/collection.dart';

import '../../parser/swagger_parser_core.dart';
import '../../utils/case_utils.dart';
import '../../utils/type_utils.dart';
import '../../utils/utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart typedefs using JSON serializable
String kotlinTypeDefTemplate(
  UniversalComponentClass dataClass, {
  required bool markFileAsGenerated,
}) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  if (type == null) {
    return '';
  }
  return '${generatedFileComment(markFileAsGenerated: markFileAsGenerated, ignoreLints: false)}${descriptionComment(dataClass.description)}'
      'typealias $className = ${type.toSuitableType(ProgrammingLanguage.kotlin)};\n';
}
