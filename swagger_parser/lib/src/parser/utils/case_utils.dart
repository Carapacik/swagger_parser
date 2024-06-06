/// [CaseUtils] for handling file names and class names
class CaseUtils {
  /// Constructor for [CaseUtils]
  CaseUtils(String text) {
    _words = _groupIntoWords(text);
  }

  late final List<String> _words;
  static const _separateSymbolsList = r' #,-./@\_{}()[]<>:;`~!$%^&*+=|\';
  static final _upperCaseRegex = RegExp('[A-Z]');
  static final _lowerCaseRegex = RegExp('[a-z]');
  final _upperCaseTwoLettersRowWords = <String>{};

  List<String> _groupIntoWords(String text) {
    final sb = StringBuffer();
    final words = <String>[];
    final isAllCaps = text.toUpperCase() == text;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (_separateSymbolsList.contains(char)) {
        if (i == 0 && char == '_') {
          words.add('private');
        }
        continue;
      }

      final nextChar = i + 1 == text.length ? null : text[i + 1];
      final nextSecondChar = i + 2 >= text.length ? null : text[i + 2];

      sb.write(char);

      final isEndOfWord = nextChar == null ||
          (_upperCaseRegex.hasMatch(nextChar) &&
              !isAllCaps &&
              (!_upperCaseRegex.hasMatch(char) ||
                  (nextSecondChar != null &&
                      _lowerCaseRegex.hasMatch(nextSecondChar)))) ||
          _separateSymbolsList.contains(nextChar);

      if (isEndOfWord) {
        final word = sb.toString();
        if (sb.length == 2 && word.toUpperCase() == word) {
          _upperCaseTwoLettersRowWords.add(word);
        }
        words.add(word);
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

  /// Return text formatted to screaming snake case
  String get screamingSnakeCase => snakeCase.toUpperCase();

  String _upperCaseFirstLetter(String word) {
    if (word.length == 2) {
      final upperCase = word.toUpperCase();
      if (_upperCaseTwoLettersRowWords.contains(upperCase)) {
        return upperCase;
      }
    }

    return '${word.substring(0, 1).toUpperCase()}${word.substring(1).toLowerCase()}';
  }
}

/// Extension to easily format String
extension StringToCaseX on String {
  // (!) We have to use two times, the results for the first and second
  // application may be different, e.g. p_n_d -> PND -> Pnd

  /// Return text formatted to camelCase
  String get toCamel => CaseUtils(CaseUtils(this).camelCase).camelCase;

  /// Return text formatted to PascalCase
  String get toPascal => CaseUtils(CaseUtils(this).pascalCase).pascalCase;

  /// Return text formatted to snake_case
  String get toSnake => CaseUtils(CaseUtils(this).snakeCase).snakeCase;

  /// Return text formatted to SCREAMING_SNAKE_CASE
  String get toScreamingSnake =>
      CaseUtils(CaseUtils(this).screamingSnakeCase).screamingSnakeCase;
}
