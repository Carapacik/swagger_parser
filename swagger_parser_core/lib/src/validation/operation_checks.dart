part of 'open_api_validator.dart';

final _pathExpression = RegExp(r'\{([^{}]+)\}');

typedef _Template = ({String path, Set<String> names});

final class _OperationChecks(
  final Map<String, Object?> root,
  final OpenApiFamily family,
  final ReferenceGraph? graph,
) {
  final diagnostics = <Diagnostic>[];
  final operationIds = <String, String>{};
  final activeItems = <ReferenceLocation>{};
  final localParameters = <String, LocatedNode>{};

  List<Diagnostic> check() {
    final document = DocumentNode(NodeKind.document, root, '');
    final Iterable<DocumentNode> nodes = document.children(family);
    if (graph == null) {
      for (final DocumentNode node in nodes.where(
        (n) => n.kind == NodeKind.parameter,
      )) {
        localParameters[node.pointer] = LocatedNode(node, null, family);
      }
    }
    for (final node in nodes) {
      final site = LocatedNode(node, graph?.documentUri, family);
      final String pointer = node.pointer;
      if (pointer.startsWith('/paths/')) {
        final String path = pointer
            .substring('/paths/'.length)
            .replaceAll('~1', '/')
            .replaceAll('~0', '~');
        final Set<String> names = _pathExpression
            .allMatches(path)
            .map((m) => m.group(1)!)
            .toSet();
        _pathItem(site, pointer, (path: path, names: names));
      } else if (pointer.startsWith('/webhooks/')) {
        _pathItem(site, pointer, null);
      } else if (graph == null) {
        // Unused components have no operation IDs in scope.
        if (node.kind == NodeKind.pathItem) {
          _pathItem(site, null, null);
        } else if (node.kind == NodeKind.callback) {
          _callback(site, null);
        }
      }
    }
    return diagnostics;
  }

  Iterable<LocatedNode> _chain(LocatedNode start) sync* {
    if (graph case final references?) {
      yield* start.referenceChain(references);
      return;
    }
    final seen = <ReferenceLocation>{};
    LocatedNode? current = start;
    while (current != null && seen.add(current.at(current.node.pointer))) {
      yield current;
      final Object? ref = current.node.fields[r'$ref'];
      if (ref is! String) {
        return;
      }
      if (start.node.kind != NodeKind.parameter ||
          !ref.startsWith('#/') ||
          parseUriReference(ref) == null) {
        return;
      }
      try {
        current = localParameters[Uri.decodeComponent(ref.substring(1))];
      } on FormatException {
        return;
      }
    }
  }

  void _pathItem(LocatedNode site, String? mount, _Template? template) {
    final visited = <ReferenceLocation>[];
    final item = EffectivePathItem.fromChain(
      _chain(site).takeWhile((item) {
        if (!activeItems.add(item.location)) {
          return false;
        }
        visited.add(item.location);
        return true;
      }),
    );
    final LocatedNode? parameterOwner = item.parameterOwner;
    final LocatedNode? nonemptyItem = item.nonemptyItem;
    final Map<String, LocatedNode> operations = item.operations;
    final shared = <String>{};
    final bool deferred = parameterOwner != null
        ? _parameters(parameterOwner, template, shared)
        : graph == null && site.node.fields.containsKey(r'$ref');
    if (operations.isEmpty &&
        nonemptyItem != null &&
        !deferred &&
        (graph != null || !site.node.fields.containsKey(r'$ref'))) {
      _missingParameters(nonemptyItem, template, shared);
    }
    for (final MapEntry<String, LocatedNode> entry in operations.entries) {
      final String? operationMount = mount == null
          ? null
          : '$mount/${entry.key}';
      _operation(
        entry.value,
        operationMount,
        template,
        shared,
        deferMissing: deferred,
      );
    }
    activeItems.removeAll(visited);
  }

  void _operation(
    LocatedNode operation,
    String? mount,
    _Template? template,
    Set<String> shared, {
    required bool deferMissing,
  }) {
    final Object? id = operation.node.fields['operationId'];
    if (id is String && mount != null) {
      final String? first = operationIds[id];
      if (first == null) {
        operationIds[id] = mount;
      } else {
        _error(
          'duplicateOperationId',
          'Duplicate operation ID $id at $first and $mount.',
          operation,
          '${operation.node.pointer}/operationId',
        );
      }
    }
    final declared = {...shared};
    final bool unresolved = _parameters(operation, template, declared);
    if (!deferMissing && !unresolved) {
      _missingParameters(operation, template, declared);
    }
    for (final LocatedNode callback in operation.children(NodeKind.callback)) {
      final String suffix = callback.node.pointer.substring(
        operation.node.pointer.length,
      );
      _callback(callback, mount == null ? null : '$mount$suffix');
    }
  }

  void _missingParameters(
    LocatedNode site,
    _Template? template,
    Set<String> declared,
  ) {
    if (template == null) {
      return;
    }
    for (final String missing in template.names.difference(declared)) {
      _error(
        'missingPathParameter',
        'Declare the path parameter $missing for ${template.path}.',
        site,
        site.node.pointer,
      );
    }
  }

  void _callback(LocatedNode site, String? mount) {
    final LocatedNode callback = _chain(site).last;
    for (final LocatedNode item in callback.children(NodeKind.pathItem)) {
      final String suffix = item.node.pointer.substring(
        callback.node.pointer.length,
      );
      _pathItem(item, mount == null ? null : '$mount$suffix', null);
    }
  }

  bool _parameters(
    LocatedNode owner,
    _Template? template,
    Set<String> declared,
  ) {
    final seen = <(String, String)>{};
    var unresolved = false;
    for (final LocatedNode parameter in owner.children(NodeKind.parameter)) {
      final LocatedNode definition = _chain(parameter).last;
      final String pointer = parameter.node.pointer;
      if (definition.node.fields.containsKey(r'$ref')) {
        unresolved = true;
        if (graph != null) {
          _error(
            'unresolvedParameter',
            'The reference chain has no parameter definition.',
            parameter,
            '$pointer/\$ref',
          );
        }
        continue;
      }

      final Map<String, Object?> fields = definition.node.fields;
      final Object? location = fields['in'];
      final Object? name = fields['name'];
      if (location is! String || name is! String) {
        unresolved = true;
        _error(
          'invalidParameter',
          'Set the parameter name and location.',
          definition,
          definition.node.pointer,
        );
        continue;
      }
      if (!seen.add((
        location,
        location == 'header' ? name.toLowerCase() : name,
      ))) {
        _error(
          'duplicateParameter',
          'Duplicate $location parameter: $name.',
          parameter,
          pointer,
        );
      }
      if (location != 'path') {
        continue;
      }

      declared.add(name);
      if (fields['required'] != true) {
        _error(
          'optionalPathParameter',
          'Set required to true for $name.',
          definition,
          fields.containsKey('required')
              ? '${definition.node.pointer}/required'
              : definition.node.pointer,
        );
      }
      if (template != null && !template.names.contains(name)) {
        _error(
          'unusedPathParameter',
          'No path expression for $name in ${template.path}.',
          parameter,
          parameter.node.fields.containsKey(r'$ref')
              ? pointer
              : '$pointer/name',
        );
      }
    }
    return unresolved;
  }

  void _error(String code, String message, LocatedNode site, String pointer) {
    diagnostics.add(
      Diagnostic(
        code: code,
        message: message,
        severity: DiagnosticSeverity.error,
        sourceUri: site.uri,
        documentPath: pointer,
      ),
    );
  }
}
