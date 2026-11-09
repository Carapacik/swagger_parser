/// Selects the generated names changed by a replacement rule.
enum NamingTarget() {
  /// DTO, enum, union, tuple, and value type names.
  models,

  /// Tag-based client names before the Client suffix.
  clients,

  /// Operation method names before result types are named.
  methods,

  /// Enum members. Wire values remain unchanged.
  enumValues,
}

/// Replaces all regex matches in names of one category.
final class const NameReplacementRule({
  /// Generated name category.
  required final NamingTarget target,

  /// Case-sensitive Dart regular expression.
  required final String pattern,

  /// Literal replacement. An empty string deletes each match.
  required final String replacement,
}) {
  /// Defines a rule. Invalid patterns fail before generation.
  this;
}

/// Naming options. Source identifiers and wire values remain unchanged.
final class const NamingConfig({
  /// Preserve letter casing in named schema types. Defaults to false.
  final bool preserveSchemaCasing = false,

  /// Rules applied in list order, before casing and collision checks.
  final List<NameReplacementRule> replaceRules = const [],
}) {
  /// Configures generated names.
  this;
}
