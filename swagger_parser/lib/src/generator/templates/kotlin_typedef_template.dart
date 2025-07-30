import 'package:collection/collection.dart';

import '../../parser/model/normalized_identifier.dart';
import '../../parser/swagger_parser_core.dart';
import '../../utils/base_utils.dart';
import '../../utils/type_utils.dart';
import '../model/programming_language.dart';

/// Provides template for generating dart typedefs using JSON serializable
String kotlinTypeDefTemplate(UniversalComponentClass dataClass) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  if (type == null) {
    return '';
  }
  return '${descriptionComment(dataClass.description)}'
      'typealias $className = ${type.toSuitableType(ProgrammingLanguage.kotlin, useMultipartFile: false)};\n';
}
