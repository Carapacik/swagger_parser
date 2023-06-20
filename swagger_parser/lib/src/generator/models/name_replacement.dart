/// Used to store regex patterns for replacing names during generation
class NameReplacement {
  const NameReplacement({
    required this.pattern,
    required this.replacement,
  });

  /// Pattern to match
  final RegExp pattern;

  /// Replacement string
  final String replacement;

  String? apply(String? input) {
    return input?.replaceAll(pattern, replacement);
  }
}
