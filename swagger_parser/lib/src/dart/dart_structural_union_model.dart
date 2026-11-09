part of 'dart_generation_model.dart';

/// A union selected by the shape of its JSON input.
final class DartStructuralUnion(
  /// Generated Dart type.
  final String name,
  Iterable<DartMatchBranch> branches, {

  /// Whether exactly one branch must match.
  required final bool exclusive,

  /// Predicate for constraints adjacent to the union.
  required final String? commonMatcher,

  /// Root predicate used to project directional JSON snapshots.
  final String? projectionMatcher,
}) {
  /// Copies the branches in schema order.
  this;

  /// Alternatives with independent match predicates.
  final List<DartMatchBranch> branches = List.unmodifiable(branches);
}

/// A branch of a structural union.
final class const DartMatchBranch(
  /// Suffix for the generated branch accessors.
  final String label,

  /// Predicate name.
  final String matcher,

  /// Type of the decoded JSON value.
  final DartTypeReference type, {

  /// Concrete class for an exclusive union.
  final String? implementation,
}) {
  /// Pairs a predicate with its decoded value.
  this;
}

/// Constraints for one generated JSON predicate.
final class DartSchemaMatcher(
  /// Generated function name.
  final String name, {
  required Iterable<String> types,
  required Map<String, Object?> constraints,
  required Map<String, String> properties,
  required Iterable<String> allOf,
  required Iterable<String> oneOf,
  required Iterable<String> anyOf,

  /// Matcher for each array item after [prefixItems].
  final String? items,
  Iterable<String> prefixItems = const [],

  /// Predicate that counts toward `minContains` and `maxContains`.
  final String? contains,

  /// Matcher for undeclared properties.
  final String? additional,

  /// Whether this is a false schema.
  final bool reject = false,
  Iterable<String> ignoredWireKeys = const [],
}) {
  /// Copies the checks and links to child predicates.
  this;

  /// JSON types accepted by the schema.
  final Set<String> types = Set.unmodifiable(types);

  /// Keys omitted from directional validation and snapshots.
  final Set<String> ignoredWireKeys = Set.unmodifiable(ignoredWireKeys);

  /// Literal constraints, including required keys and scalar bounds.
  final Map<String, Object?> constraints =
      JsonValue(constraints).value! as Map<String, Object?>;

  /// Property matchers keyed by wire name.
  final Map<String, String> properties = Map.unmodifiable(properties);

  /// Matchers for present array positions in wire order.
  final List<String> prefixItems = List.unmodifiable(prefixItems);

  /// Predicates that must all match, including static references.
  final List<String> allOf = List.unmodifiable(allOf);

  /// Predicates that require exactly one match.
  final List<String> oneOf = List.unmodifiable(oneOf);

  /// Predicates that require at least one match.
  final List<String> anyOf = List.unmodifiable(anyOf);
}
