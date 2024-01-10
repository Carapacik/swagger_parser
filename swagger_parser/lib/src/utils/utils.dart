import 'dart:io';

import '../generator/models/generation_statistics.dart';
import '../generator/models/open_api_info.dart';
import '../generator/models/programming_language.dart';
import '../generator/models/universal_data_class.dart';
import '../generator/models/universal_type.dart';
import '../utils/case_utils.dart';

const _green = '\x1B[32m';
// ignore: unused_element
const _yellow = '\x1B[33m';
// ignore: unused_element
const _blue = '\x1B[34m';
const _lightBlue = '\x1B[36m';
const _red = '\x1B[31m';
const _reset = '\x1B[0m';

/// Provides imports as String from list of imports
String dartImports({required Set<String> imports, String? pathPrefix}) {
  if (imports.isEmpty) {
    return '';
  }
  return '\n${imports.map((import) => "import '${pathPrefix ?? ''}${import.toSnake}.dart';").join('\n')}\n';
}

String indentation(int length) => ' ' * length;

/// Provides description
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
    (m) =>
        '${!tabForFirstLine && m.start == 0 ? '' : tab}/// ${m.start == 0 && m.end == description.length ? m[1] : addDot(m[1])}',
  );

  return '$result\n$end';
}

/// RegExp for punctuation marks in the end of string
final _punctuationRegExp = RegExp(r'[.!?]$');

/// Add dot to string if not exist
/// https://dart.dev/effective-dart/documentation#do-format-comments-like-sentences
String? addDot(String? text) =>
    text != null && text.trim().isNotEmpty && !_punctuationRegExp.hasMatch(text)
        ? '$text.'
        : text;

/// Replace all not english letters in text
String? replaceNotEnglishLetter(String? text) {
  if (text == null || text.isEmpty) {
    return null;
  }
  final lettersRegex = RegExp('[^a-zA-Z]');
  return text.replaceAll(lettersRegex, ' ');
}

/// Specially for File import
String ioImport(UniversalComponentClass dataClass) => dataClass.parameters.any(
      (p) => p.toSuitableType(ProgrammingLanguage.dart).startsWith('File'),
    )
        ? "import 'dart:io';\n\n"
        : '';

String generatedFileComment({
  required bool markFileAsGenerated,
  bool ignoreLints = true,
}) =>
    markFileAsGenerated
        ? ignoreLints
            ? '$_generatedCodeComment$_ignoreLintsComment\n'
            : '$_generatedCodeComment\n'
        : '';

const _generatedCodeComment = '''
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
''';

const _ignoreLintsComment = '''
// ignore_for_file: type=lint
''';

void introMessage() {
  stdout.writeln(
    r'''

┃  ____ _ _ _ ____ ____ ____ ____ ____     ___  ____ ____ ____ ____ ____ 
┃  [__  | | | |__| | __ | __ |___ |__/     |__] |__| |__/ [__  |___ |__/ 
┃  ___] |_|_| |  | |__] |__] |___ |  \ ___ |    |  | |  \ ___] |___ |  \
┃
''',
  );
}

void generateMessage() {
  stdout.writeln('Generate...');
}

void extractingSchemaFromUrlMessage(String url) {
  stdout.writeln('Extracting schema from $_lightBlue$url...$_reset');
}

final _numbersRegExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');

String formatNumber(int number) => '$number'.replaceAllMapped(
      _numbersRegExp,
      (match) => '${match[1]} ',
    );

void schemaStatisticsMessage({
  required OpenApiInfo openApi,
  required GenerationStatistics statistics,
  String? name,
}) {
  final version = openApi.version != null ? 'v${openApi.version}' : '';

  var title = name ?? '';
  if (title.length > 80) {
    title = '${title.substring(0, 80)}...';
  }

  stdout.writeln(
    '> $title $version: \n'
    '    ${formatNumber(statistics.totalRestClients)} rest clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '    ${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.\n'
    '    ${_green}Success (${statistics.timeElapsed.inMilliseconds / 1000} seconds)$_reset\n',
  );
}

void schemaFailedMessage({
  required Object error,
  required StackTrace stack,
  String? name,
}) {
  var title = name ?? '';
  if (title.length > 80) {
    title = '${title.substring(0, 80)}...';
  }

  stdout.writeln(
    '> $title: \n'
    '    ${_red}Failed to generate files.$_reset\n'
    '    $error\n'
    '    ${stack.toString().replaceAll('\n', '\n    ')}\n',
  );
}

void summaryStatisticsMessage({
  required int successCount,
  required int schemasCount,
  required GenerationStatistics statistics,
}) {
  stdout.writeln(
    'Summary (${statistics.timeElapsed.inMilliseconds / 1000} seconds):\n'
    '${successCount != schemasCount ? '$successCount/$schemasCount' : '$schemasCount'} schemas, '
    '${formatNumber(statistics.totalRestClients)} clients, '
    '${formatNumber(statistics.totalRequests)} requests, '
    '${formatNumber(statistics.totalDataClasses)} data classes.\n'
    '${formatNumber(statistics.totalFiles)} files with ${formatNumber(statistics.totalLines)} lines of code.\n',
  );
}

void doneMessage({
  required int successSchemasCount,
  required int schemasCount,
}) {
  if (successSchemasCount == 0) {
    stdout.writeln(
      '${_red}The generation was completed with errors.\n'
      'No schemas were generated.$_reset',
    );
  } else if (successSchemasCount != schemasCount) {
    stdout.writeln(
      '${_red}The generation was completed with errors.\n'
      '${schemasCount - successSchemasCount} schemas were not generated.$_reset',
    );
  } else {
    stdout.writeln(
      '${schemasCount > 1 ? _green : ''}The generation was completed successfully. '
      'You can run the generation using build_runner.${schemasCount > 1 ? _reset : ''}',
    );
  }
}

void doneExtractMessage() {
  stdout.writeln('${_green}The extraction was completed successfully.$_reset');
}

void exitWithError(String message) {
  stderr.writeln('${_red}ERROR: $message$_reset');
  exit(2);
}
