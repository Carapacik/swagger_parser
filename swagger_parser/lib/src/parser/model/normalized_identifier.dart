const _separatorSymbolsPattern = r'[ #,\-./@\\_{}()\[\]<>:;`~!$%^&*+=|\\]';
final _separatorPattern = RegExp(_separatorSymbolsPattern);
final _separatorSplitPattern = RegExp('$_separatorSymbolsPattern+');
final _lowercasePattern = RegExp('[a-z]');
final _uppercasePattern = RegExp('[A-Z]');
final _digitPattern = RegExp(r'\d');

/// Normalized identifier for an entity in the OpenAPI specification
class NormalizedIdentifier {
  const NormalizedIdentifier._(this._words, {this.isPrivate = false});

  factory NormalizedIdentifier.fromWords(List<String> words,
      {bool isPrivate = false}) {
    return NormalizedIdentifier._(words.where((w) => w.isNotEmpty).toList(),
        isPrivate: isPrivate);
  }

  /// Parses the given [text] and splits it into words based on casing, spaces, etc.
  factory NormalizedIdentifier.parse(String text) {
    if (text.isEmpty) {
      return const NormalizedIdentifier._([]);
    }

    final (text: workingText, :isPrivate) = _extractPrivatePrefix(text);

    if (workingText.isEmpty) {
      return NormalizedIdentifier._([], isPrivate: isPrivate);
    }

    final words = _parseWords(workingText);
    return NormalizedIdentifier._(words, isPrivate: isPrivate);
  }

  /// Words in the identifier
  final List<String> _words;

  /// Returns a copy of [_words] to avoid modifications
  List<String> get words => [..._words];

  /// True when the identifier is private
  ///
  /// For example, `_id` is private, `id` is public.
  final bool isPrivate;

  static ({String text, bool isPrivate}) _extractPrivatePrefix(String text) {
    final isPrivate = text.startsWith('_');
    final workingText = isPrivate ? text.substring(1) : text;
    return (text: workingText, isPrivate: isPrivate);
  }

  static List<String> _parseWords(String text) {
    final hasDelimiters = _separatorPattern.hasMatch(text);

    if (hasDelimiters) {
      return _parseDelimitedText(text);
    }
    return _splitCamelCase(text);
  }

  static List<String> _parseDelimitedText(String text) {
    final words = <String>[];
    final parts = _splitIntoAlphanumericParts(text);

    for (final part in parts) {
      if (_hasMixedCase(part)) {
        words.addAll(_splitCamelCase(part));
      } else {
        words.add(part.toLowerCase());
      }
    }
    return words;
  }

  static List<String> _splitIntoAlphanumericParts(String text) {
    return text
        .split(_separatorSplitPattern)
        .where((w) => w.isNotEmpty)
        .toList();
  }

  static bool _hasMixedCase(String text) {
    return _lowercasePattern.hasMatch(text) && _uppercasePattern.hasMatch(text);
  }

  static List<String> _splitCamelCase(String text) {
    if (text.isEmpty) {
      return [];
    }

    final words = <String>[];
    final buffer = StringBuffer();
    var previousCharType = _CharType.other;

    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      final charType = _CharType.from(char);

      final shouldSplit = _shouldSplitAtChar(
        buffer: buffer,
        currentCharType: charType,
        previousCharType: previousCharType,
        currentIndex: i,
        text: text,
      );

      if (shouldSplit) {
        words.add(buffer.toString().toLowerCase());
        buffer.clear();
      }

      buffer.write(char);
      previousCharType = charType;
    }

    if (buffer.isNotEmpty) {
      words.add(buffer.toString().toLowerCase());
    }

    return words;
  }

  static bool _shouldSplitAtChar({
    required StringBuffer buffer,
    required _CharType currentCharType,
    required _CharType previousCharType,
    required int currentIndex,
    required String text,
  }) {
    if (buffer.isEmpty) {
      return false;
    }

    if (currentCharType != _CharType.uppercase) {
      return false;
    }

    return switch (previousCharType) {
      // Split on lowercase to uppercase transition
      _CharType.lowercase ||
      // Split on digit to uppercase transition
      _CharType.digit ||
      // Split on non-ASCII to uppercase transition
      _CharType.other =>
        true,
      // Handle acronym splitting (consecutive uppercase letters)
      _CharType.uppercase => _isLastLetterOfAcronym(currentIndex, text),
    };
  }

  static bool _isLastLetterOfAcronym(int currentIndex, String text) {
    final hasNext = currentIndex + 1 < text.length;
    if (!hasNext) {
      return false;
    }

    final nextChar = text[currentIndex + 1];
    return _CharType.from(nextChar) == _CharType.lowercase;
  }

  /// Return text formatted to camel case
  String get camelCase {
    if (_words.isEmpty) {
      return '';
    }
    final first = _words.first;
    final rest = _words.skip(1);
    return [first.toLowerCase(), ...rest.map(_upperCaseFirstLetter)].join();
  }

  /// Return text formatted to pascal case
  String get pascalCase => _words.map(_upperCaseFirstLetter).join();

  /// Return text formatted to snake case
  String get snakeCase => _words.map((word) => word.toLowerCase()).join('_');

  /// Return text formatted to kebab case
  String get kebabCase => _words.map((word) => word.toLowerCase()).join('-');

  /// Return text formatted to screaming snake case
  String get screamingSnakeCase => snakeCase.toUpperCase();

  /// Return text formatted to screaming kebab case
  String get screamingKebabCase => kebabCase.toUpperCase();

  /// Return text formatted to train case
  String get trainCase => _words.map(_upperCaseFirstLetter).join('-');

  String _upperCaseFirstLetter(String word) {
    if (word.isEmpty) {
      return '';
    }
    final first = word[0];
    final rest = word.substring(1);
    return '${first.toUpperCase()}${rest.toLowerCase()}';
  }
}

/// Character type enumeration for parsing
enum _CharType {
  other,
  lowercase,
  uppercase,
  digit;

  static _CharType from(String char) {
    assert(char.length == 1, 'only valid on single characters');

    if (_digitPattern.hasMatch(char)) {
      return _CharType.digit;
    }
    if (_uppercasePattern.hasMatch(char)) {
      return _CharType.uppercase;
    }
    if (_lowercasePattern.hasMatch(char)) {
      return _CharType.lowercase;
    }
    return _CharType.other;
  }
}

/// Extension to easily format String using NormalizedIdentifier
extension StringToCaseX on String {
  /// Return text formatted to camelCase.
  ///
  /// The result is prefixed with `private` if the given text indicates a private entity
  String get toCamel {
    final identifier = NormalizedIdentifier.parse(this);
    return identifier.isPrivate
        ? 'private${identifier.pascalCase}'
        : identifier.camelCase;
  }

  /// Return text formatted to PascalCase
  ///
  /// The result is prefixed with `Private` if the given text indicates a private entity
  String get toPascal {
    final identifier = NormalizedIdentifier.parse(this);
    return identifier.isPrivate
        ? 'Private${identifier.pascalCase}'
        : identifier.pascalCase;
  }

  /// Return text formatted to snake_case
  ///
  /// The result is prefixed with `private_` if the given text indicates a private entity
  String get toSnake {
    final identifier = NormalizedIdentifier.parse(this);
    return identifier.isPrivate
        ? 'private_${identifier.snakeCase}'
        : identifier.snakeCase;
  }

  /// Return text formatted to SCREAMING_SNAKE_CASE
  ///
  /// The result is prefixed with `PRIVATE_` if the given text indicates a private entity
  String get toScreamingSnake {
    final identifier = NormalizedIdentifier.parse(this);
    return identifier.isPrivate
        ? 'PRIVATE_${identifier.screamingSnakeCase}'
        : identifier.screamingSnakeCase;
  }
}
