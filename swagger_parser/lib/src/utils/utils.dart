import 'dart:io';

import '../generator/models/generation_statistics.dart';
import '../generator/models/open_api_info.dart';
import '../generator/models/programming_lang.dart';
import '../generator/models/universal_data_class.dart';
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
String descriptionComment(
  String? description, {
  bool tabForFirstLine = true,
  String tab = '',
  String end = '',
}) {
  if (description == null || description.isEmpty) {
    return '';
  }

  final lineStart = RegExp('^(.*)', multiLine: true);
  final result = description.replaceAllMapped(
    lineStart,
    (m) => '${!tabForFirstLine && m.start == 0 ? '' : tab}/// ${m[1]}',
  );

  return '$result\n$end';
}

/// Replace all not english letters in text
String? replaceNotEnglishLetter(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  final lettersRegex = RegExp('[^a-zA-Z]');
  return text.replaceAll(lettersRegex, ' ');
}

/// Specially for File import
String ioImport(UniversalComponentClass dataClass) => dataClass.parameters
        .any((p) => p.toSuitableType(ProgrammingLanguage.dart) == 'File')
    ? "import 'dart:io';\n\n"
    : '';

const dartGeneratedFileComment = r'''
//  ____ _ _ _ ____ ____ ____ ____ ____     ___  ____ ____ ____ ____ ____
//  [__  | | | |__| | __ | __ |___ |__/     |__] |__| |__/ [__  |___ |__/
//  ___] |_|_| |  | |__] |__] |___ |  \ ___ |    |  | |  \ ___] |___ |  \                            
//
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint

''';

const kotlinGeneratedFileComment = r'''
//  ____ _ _ _ ____ ____ ____ ____ ____     ___  ____ ____ ____ ____ ____
//  [__  | | | |__| | __ | __ |___ |__/     |__] |__| |__/ [__  |___ |__/
//  ___] |_|_| |  | |__] |__] |___ |  \ ___ |    |  | |  \ ___] |___ |  \
//
// GENERATED CODE - DO NOT MODIFY BY HAND
                         
''';

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

final _numbersRegExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

String formatNumber(int number) {
  return '$number'.replaceAllMapped(
    _numbersRegExp,
    (match) => '${match[1]} ',
  );
}

void schemaStatisticsMessage(
  String name,
  OpenApiInfo openApi,
  GenerationStatistics statistics,
) {
  final version = openApi.version != null ? 'v${openApi.version}' : '';
  var title = '$name $version';

  if (title.length > 80) {
    title = '${title.substring(0, 80)}...';
  }

  // pretty print
  stdout.writeln(
    '\n> $title:\n'
    '    ${formatNumber(statistics.totalRestClients)} rest clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '    ${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.',
  );
}

void summaryStatisticsMessage(
  int schemasCount,
  GenerationStatistics statistics,
) {
  stdout.writeln(
    '\nSummary:\n'
    '${formatNumber(schemasCount)} schemas, '
    '${formatNumber(statistics.totalRestClients)} clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.',
  );
}

void successMessage() {
  stdout.writeln(
    '\n'
    'The generation was completed successfully. '
    'You can run the generation using build_runner.',
  );
}

void exitWithError(String message) {
  stderr.writeln('ERROR: $message');
  exit(2);
}
