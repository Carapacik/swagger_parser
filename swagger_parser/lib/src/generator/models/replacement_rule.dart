/// Used to store regex patterns for replacing names during generation
class ReplacementRule {
  const ReplacementRule({
    required this.pattern,
    required this.replacement,
  });

  /// Pattern to match
  final RegExp pattern;

  /// Replacement string
  final String replacement;

  /// applies the replacement rule to the given input string
  String? apply(String? input) {
    return input?.replaceAll(pattern, replacement);
  }
}
