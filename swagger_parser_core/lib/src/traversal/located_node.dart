import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/references/open_api_reference_resolver.dart';
import 'package:swagger_parser_core/src/traversal/document_node.dart';

/// An OpenAPI node with its physical document and schema context.
final class const LocatedNode(
  /// Node role, value, and JSON Pointer.
  final DocumentNode node,

  /// Physical document URI, if available.
  final Uri? uri,

  /// Family of the physical document.
  final OpenApiFamily family, {

  /// Inherited schema dialect URI, if available.
  final String? dialect,
}) {
  /// Locates [node] in its source document.
  this;

  /// Identifies a [pointer] in the same physical document.
  ReferenceLocation at(String pointer) => (documentUri: uri, pointer: pointer);

  /// Physical identity of this node.
  ReferenceLocation get location => at(node.pointer);

  /// Visits direct children with the specified role.
  Iterable<LocatedNode> children(NodeKind kind) sync* {
    for (final DocumentNode child in node.children(family)) {
      if (child.kind == kind) {
        yield LocatedNode(child, uri, family, dialect: dialect);
      }
    }
  }

  /// Interprets a resolved target in its source context.
  LocatedNode target(ReferenceTarget target) => LocatedNode(
    DocumentNode(node.kind, target.value, target.location.pointer),
    target.location.documentUri,
    target.family ?? family,
    dialect: target.dialect,
  );

  /// Visits static reference targets once per chain.
  Iterable<LocatedNode> referenceChain(ReferenceGraph graph) sync* {
    final seen = <ReferenceLocation>{};
    var current = this;
    while (seen.add(current.location)) {
      yield current;
      if (!current.node.fields.containsKey(r'$ref')) {
        return;
      }
      final ReferenceTarget? edge = graph.targetFor(
        current.at('${current.node.pointer}/\$ref'),
      );
      if (edge == null) {
        return;
      }
      current = current.target(edge);
    }
  }
}

/// Effective fields of a Path Item after following its references.
final class const EffectivePathItem._(
  /// Operations keyed by pointer relative to the Path Item.
  final Map<String, LocatedNode> operations,

  /// Path Item that declares the inherited parameter list.
  final LocatedNode? parameterOwner,

  /// First Path Item with a field other than a reference or extension.
  final LocatedNode? nonemptyItem,
) {
  /// Selects the nearest parameter list and the nearest operation per method.
  factory fromChain(Iterable<LocatedNode> chain) {
    final operations = <String, LocatedNode>{};
    LocatedNode? parameters;
    LocatedNode? nonempty;
    for (final item in chain) {
      if (item.node.fields.keys.any(
        (k) => k != r'$ref' && !k.startsWith('x-'),
      )) {
        nonempty ??= item;
      }
      if (item.node.fields.containsKey('parameters')) {
        parameters ??= item;
      }
      for (final LocatedNode operation in item.children(NodeKind.operation)) {
        final String method = operation.node.pointer.substring(
          item.node.pointer.length + 1,
        );
        operations.putIfAbsent(method, () => operation);
      }
    }
    return EffectivePathItem._(
      Map.unmodifiable(operations),
      parameters,
      nonempty,
    );
  }
}
