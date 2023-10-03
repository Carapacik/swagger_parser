import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_data_class.dart';
import '../models/universal_type.dart';

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
