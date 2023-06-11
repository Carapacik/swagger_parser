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

/// Provides class description
String descriptionComment(String? description, {String tab = ''}) {
  if (description == null || description.isEmpty) {
    return '';
  }

  final lineStart = RegExp('^(.*)', multiLine: true);
  final result = description.replaceAllMapped(
    lineStart,
    (m) => '$tab/// ${m[1]}',
  );

  return '$result\n';
}

String ioImport(UniversalComponentClass dataClass) => dataClass.parameters
        .any((p) => p.toSuitableType(ProgrammingLanguage.dart) == 'File')
    ? "import 'dart:io';\n\n"
    : '';

void introMessage() {
  stdout.writeln(
    '''
  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃                               ┃
  ┃   Welcome to swagger_parser   ┃
  ┃                               ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
''',
  );
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
