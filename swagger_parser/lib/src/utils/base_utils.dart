import '../generator/model/programming_language.dart';
import '../parser/swagger_parser_core.dart';
import '../parser/utils/case_utils.dart';
import 'type_utils.dart';

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
        '${!tabForFirstLine && m.start == 0 ? '' : tab}///${m[1]!.trim().isEmpty ? '' : ' '}${m.start == 0 && m.end == description.length ? m[1] : addDot(m[1])}',
  );

  return '$result\n$end';
}

/// Add dot to string if not exist
/// https://dart.dev/effective-dart/documentation#do-format-comments-like-sentences
String? addDot(String? text) =>
    text != null && text.trim().isNotEmpty && !_punctuationRegExp.hasMatch(text)
        ? '$text.'
        : text;

/// RegExp for punctuation marks in the end of string
final _punctuationRegExp = RegExp(r'[.!?]$');

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

String formatNumber(int number) => number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]} ',
    );

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
// ignore_for_file: type=lint, unused_import
''';
