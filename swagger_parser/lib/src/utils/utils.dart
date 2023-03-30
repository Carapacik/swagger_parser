import 'dart:io';

import '../generator/models/programming_lang.dart';
import '../generator/models/universal_component_class.dart';
import '../generator/models/universal_type.dart';
import '../utils/case_utils.dart';

/// Provides imports as String from list of imports
String dartImports({required Set<String> imports, String? pathPrefix}) {
  if (imports.isEmpty) {
    return '';
  }
  return '\n${imports.map((import) => "import '${pathPrefix ?? ''}${import.toSnake}.dart';").join('\n')}\n';
}

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

String fileImport(UniversalComponentClass dataClass) =>
    dataClass.parameters.any(
      (p) =>
          toSuitableType(
            p,
            ProgrammingLanguage.dart,
            isRequired: p.isRequired,
          ) ==
          'File',
    )
        ? "import 'dart:io';\n\n"
        : '';

String intlImport(UniversalComponentClass dataClass) =>
    dataClass.parameters.any(
      (p) => p.format == 'date',
    )
        ? "import 'package:intl/intl.dart';\n"
        : '';

void introMessage() {
  stdout.writeln('''
  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃   Welcome to swagger_parser   ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
''');
}

void generateMessage() {
  stdout.writeln('Generate...');
}

void successMessage() {
  stdout.writeln(
    'The generation was completed successfully. '
    'You can run the generation using build_runner.',
  );
}

void exitWithError(String message) {
  stderr.writeln('ERROR: $message');
  exit(2);
}
