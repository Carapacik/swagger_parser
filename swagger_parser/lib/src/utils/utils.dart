import 'dart:io';

import '../generator/models/programming_lang.dart';
import '../generator/models/universal_type.dart';
import '../utils/case_utils.dart';

/// Provides imports as String from list of imports
String dartImports({required Set<String> imports, String? pathPrefix}) =>
    imports
        .map(
          (import) => "import '${pathPrefix ?? ''}${import.toSnake}.dart';\n",
        )
        .join();

/// Converts [UniversalType] to concrete type of certain [ProgrammingLanguage]
String toSuitableType(
  UniversalType type,
  ProgrammingLanguage lang, {
  bool isRequired = true,
}) {
  if (type.arrayDepth == 0) {
    return type.byLang(lang, isRequired: isRequired);
  }
  final sb = StringBuffer();
  for (var i = 0; i < type.arrayDepth; i++) {
    sb.write('List<');
  }
  sb.write(type.byLang(lang));
  for (var i = 0; i < type.arrayDepth; i++) {
    sb.write('>');
  }
  if (!isRequired && type.defaultValue == null) {
    sb.write('?');
  }
  return sb.toString();
}

void exitWithError(String message) {
  stderr.writeln('ERROR: $message');
  exit(2);
}
