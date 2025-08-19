import 'package:meta/meta.dart';

import 'normalized_identifier.dart';

/// Used to store regex patterns for replacing names during generation
@immutable
final class ReplacementRule {
  /// Constructor for [ReplacementRule]
  const ReplacementRule({required this.pattern, required this.replacement});

  /// Pattern to match
  final RegExp pattern;

  /// Replacement string
  final String replacement;

  /// Returns the replacement string in the correct case
  String get replacementInCorrectCase => replacement.isNotEmpty
      ? replacement[0] == replacement[0].toUpperCase()
          ? replacement.toPascal
          : replacement.toCamel
      : replacement;

  /// Applies the replacement rule to the given input string
  String? apply(String? input) =>
      input?.replaceAll(pattern, replacementInCorrectCase);
}
