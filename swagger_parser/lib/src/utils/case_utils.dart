/// [CaseUtils] for handling file names and class names
class CaseUtils {
  CaseUtils(String text) {
    _words = _groupIntoWords(text);
  }

  late List<String> _words;

  static const _caseSymbolsList = ['_', '-', '/', '{', '}', ' '];
  static const _upperRegex = r'[A-Z]$';

  List<String> _groupIntoWords(String text) {
    final sb = StringBuffer();
    final words = <String>[];
    final isAllCaps = text.toUpperCase() == text;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final nextChar = i + 1 == text.length ? null : text[i + 1];

      if (_caseSymbolsList.contains(char)) {
        continue;
      }
      sb.write(char);
      final isEndOfWord = nextChar == null ||
          (RegExp(_upperRegex).hasMatch(nextChar) && !isAllCaps) ||
          _caseSymbolsList.contains(nextChar);

      if (isEndOfWord) {
        words.add(sb.toString());
        sb.clear();
      }
    }

    return words;
  }

  /// Return text formatted to camel case
  String get camelCase {
    var word = _words.map(_upperCaseFirstLetter).join();
    if (word.isNotEmpty) {
      word = word[0].toLowerCase() + word.substring(1);
    }
    return word;
  }

  /// Return text formatted to pascal case
  String get pascalCase => _words.map(_upperCaseFirstLetter).join();

  /// Return text formatted to snake case
  String get snakeCase => _words.map((word) => word.toLowerCase()).join('_');

  String _upperCaseFirstLetter(String word) =>
      '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}';
}

extension StringToCase on String {
  String get toCamel => CaseUtils(this).camelCase;

  String get toPascal => CaseUtils(this).pascalCase;

  String get toSnake => CaseUtils(this).snakeCase;
}
