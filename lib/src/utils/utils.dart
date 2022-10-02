import 'dart:io';

import 'package:swagger_parser/src/generator/models/programming_lang.dart';
import 'package:swagger_parser/src/generator/models/universal_type.dart';
import 'package:swagger_parser/src/utils/case_utils.dart';

/// Provides imports as String from list of imports
String dartImports({
  required final Set<String> imports,
  final String? pathPrefix,
}) =>
    imports
        .map(
          (import) => "import '${pathPrefix ?? ''}${import.toSnake}.dart';\n",
        )
        .join();

/// Converts [UniversalType] to Concrete type of certain language
String toSuitableType(UniversalType type, ProgrammingLanguage lang) {
  if (type.arrayDepth == 0) {
    return type.byLang(lang);
  }
  final sb = StringBuffer();
  for (var i = 0; i < type.arrayDepth; i++) {
    sb.write('List<');
  }
  sb.write(type.byLang(lang));
  for (var i = 0; i < type.arrayDepth; i++) {
    sb.write('>');
  }
  return sb.toString();
}

void exitWithError(String message) {
  stderr.writeln('ERROR: $message');
  exit(2);
}
