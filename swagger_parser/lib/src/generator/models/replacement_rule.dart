/// Used to store regex patterns for replacing names during generation
class ReplacementRule {
  /// Constructor for [ReplacementRule]
  const ReplacementRule({
    required this.pattern,
    required this.replacement,
  });

  /// Pattern to match
  final RegExp pattern;

  /// Replacement string
  final String replacement;

  /// Applies the replacement rule to the given input string
  String? apply(String? input) => input?.replaceAll(pattern, replacement);
}
