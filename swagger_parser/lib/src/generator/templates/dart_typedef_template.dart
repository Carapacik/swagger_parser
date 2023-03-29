import 'package:collection/collection.dart';

import '../../utils/case_utils.dart';
import '../../utils/utils.dart';
import '../models/programming_lang.dart';
import '../models/universal_component_class.dart';

/// Provides template for generating dart typedefs using JSON serializable
String dartTypeDefTemplate(UniversalComponentClass dataClass) {
  final className = dataClass.name.toPascal;
  final type = dataClass.parameters.firstOrNull;
  final import = dataClass.imports.firstOrNull;
  if (type == null) {
    return '';
  }
  return '''
${import != null ? "import '${import.toSnake}.dart';\n\n" : ''}typedef $className = ${toSuitableType(type, ProgrammingLanguage.dart, isRequired: type.isRequired)};
''';
}
