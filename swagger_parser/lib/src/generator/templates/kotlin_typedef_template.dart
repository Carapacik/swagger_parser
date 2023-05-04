import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_component_class.dart';

/// Provides template for generating dart typedefs using JSON serializable
String kotlinTypeDefTemplate(UniversalComponentClass dataClass) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  if (type == null) {
    return '';
  }
  return '${classDescription(dataClass.description)}'
      'typealias $className = ${toSuitableType(type, ProgrammingLanguage.kotlin)};';
}
