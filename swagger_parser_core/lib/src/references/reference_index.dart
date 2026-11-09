part of 'open_api_reference_resolver.dart';

final class _File(
  final Uri? uri,
  final OpenApiFamily family,
  final Object? root, {
  required final bool complete,
}) {
  final nodes = <String, _Entry>{};
  bool get modern => family == OpenApiFamily.v31 || family == OpenApiFamily.v32;
  String get defaultDialect => family == OpenApiFamily.v32
      ? OpenApiV32Schema.oasDialect
      : OpenApiV31Schema.oasDialect;
  ReferenceLocation at(String pointer) => (documentUri: uri, pointer: pointer);
}

final class _Entry(
  final _File file,
  final DocumentNode node,
  final Uri base,
  final String dialect,
) {
  ReferenceTarget get target => ReferenceTarget._(
    file.at(node.pointer),
    base,
    node.value,
    file.family,
    file.modern ? dialect : null,
  );
}

typedef _Resource = ({_File file, String pointer});
typedef _Pending = ({
  _Entry source,
  String pointer,
  Uri base,
  String text,
  NodeKind expected,
});

final class _ReferenceIndex(
  final ParseConfig config,
  final DocumentLoader? loader,
) {
  final resources = <Uri, _Resource>{};
  final anchors = <(Uri, String), _Entry>{};
  final dynamicAnchors = <(Uri, String), ReferenceTarget>{};
  final pending = <_Pending>[];
  late final Uri entryUri;
  final loadFailures = <Uri, Object>{};
  final edges = <ReferenceLocation, ResolvedReference>{};

  static final _invalidEscape = RegExp('~(?![01])');
  static final _indexToken = RegExp(r'^(?:0|[1-9][0-9]*)$');

  Never _fail(
    ReferenceLocation source,
    String code,
    String message, [
    Object? cause,
  ]) => throw ReferenceResolutionException(
    code,
    message,
    sourceUri: source.documentUri,
    documentPath: source.pointer,
    cause: cause,
  );

  Uri _uri(Uri base, String text, ReferenceLocation source) {
    final Uri? uri = parseUriReference(text);
    if (uri == null) {
      _fail(source, 'invalidReference', 'Invalid URI reference: $text.');
    }
    return base.resolveUri(uri);
  }

  Future<ReferenceGraph> resolve(OpenApiDocument doc, Uri? sourceUri) async {
    entryUri = sourceUri?.removeFragment() ?? Uri();
    _add(
      doc.toJson(),
      sourceUri?.removeFragment(),
      doc.version.family,
      complete: true,
    );
    // A later file can declare the canonical URI of an earlier reference.
    var next = 0;
    while (next < pending.length) {
      final int count = resources.length;
      final deferred = <_Pending>[];
      ReferenceResolutionException? firstFailure;
      while (next < pending.length) {
        final _Pending edge = pending[next++];
        try {
          await _follow(edge);
        } on ReferenceResolutionException catch (error) {
          if (error.code != 'loadFailed') {
            rethrow;
          }
          firstFailure ??= error;
          deferred.add(edge);
        }
      }
      if (firstFailure != null && resources.length == count) {
        throw firstFailure;
      }
      pending.addAll(deferred);
    }
    return ReferenceGraph(
      edges,
      documentUri: sourceUri?.removeFragment(),
      dynamicAnchors: dynamicAnchors,
      schemaResources: {
        for (final file in resources.values.map((r) => r.file).toSet())
          if (file.modern)
            for (final entry in file.nodes.values)
              if (entry.node.kind == NodeKind.schema)
                file.at(entry.node.pointer): entry.base,
      },
    );
  }

  void _add(
    Object? data,
    Uri? uri,
    OpenApiFamily family, {
    required bool complete,
  }) {
    final file = _File(uri, family, JsonValue(data).value, complete: complete);
    final Uri retrieval = uri ?? Uri();
    _register(retrieval, file, '', '');
    if (complete) {
      final root = DocumentNode(NodeKind.document, file.root, '');
      var base = retrieval;
      if (family == OpenApiFamily.v32 && root.fields[r'$self'] is String) {
        base = _uri(
          base,
          root.fields[r'$self']! as String,
          file.at(r'/$self'),
        ).removeFragment();
        _register(base, file, '', r'/$self');
      }
      final Object? dialect = root.fields['jsonSchemaDialect'];
      _index(
        file,
        root,
        base,
        dialect is String ? dialect : file.defaultDialect,
      );
    }
  }

  void _register(Uri uri, _File file, String pointer, String field) {
    final _Resource resource = (file: file, pointer: pointer);
    final _Resource? previous = resources[uri];
    if (previous != null && previous != resource) {
      _fail(
        file.at(field),
        'duplicateIdentifier',
        'Duplicate resource URI: $uri.',
      );
    }
    resources[uri] = resource;
  }

  _Entry _index(
    _File file,
    DocumentNode node,
    Uri inheritedBase,
    String inheritedDialect,
  ) {
    var base = inheritedBase;
    var dialect = inheritedDialect;
    final _Entry? previous = file.nodes[node.pointer];
    if (previous != null) {
      return previous;
    }
    final Map<String, Object?> fields = node.fields;
    final bool schema = file.modern && node.kind == NodeKind.schema;
    if (schema && fields[r'$schema'] is String) {
      dialect = fields[r'$schema']! as String;
    }
    final bool opaque =
        schema &&
        SchemaDialect.identify(dialect, file.family) == SchemaDialect.unknown;
    if ((schema && !opaque, fields[r'$id']) case (true, final String id)) {
      final String field = appendPointer(node.pointer, r'$id');
      final Uri identifier = _uri(base, id, file.at(field));
      if (identifier.fragment.isNotEmpty) {
        _fail(
          file.at(field),
          'invalidReference',
          r'$id cannot contain a nonempty fragment.',
        );
      }
      base = identifier.removeFragment();
      _register(base, file, node.pointer, field);
    }
    final entry = _Entry(file, node, base, dialect);
    file.nodes[node.pointer] = entry;
    if (opaque) {
      return entry;
    }
    if (schema) {
      for (final key in const [r'$anchor', r'$dynamicAnchor']) {
        if (fields[key] case final String name) {
          final keyUri = (base, name);
          if (anchors.containsKey(keyUri)) {
            _fail(
              file.at(appendPointer(node.pointer, key)),
              'duplicateIdentifier',
              'Duplicate schema anchor: $name.',
            );
          }
          anchors[keyUri] = entry;
          if (key == r'$dynamicAnchor') {
            dynamicAnchors[keyUri] = entry.target;
          }
        }
      }
      _queue(entry, r'$dynamicRef', NodeKind.schema);
    }
    if (node.allowsRef(file.family)) {
      _queue(entry, r'$ref', node.kind);
    }
    if (node.kind == NodeKind.link && !fields.containsKey(r'$ref')) {
      _queue(entry, 'operationRef', NodeKind.operation);
    }
    final Object? discriminator = fields['discriminator'];
    if (node.kind == NodeKind.schema &&
        file.family != OpenApiFamily.swaggerV2 &&
        (file.modern || !fields.containsKey(r'$ref')) &&
        (fields.containsKey('oneOf') || fields.containsKey('anyOf')) &&
        discriminator is Map<String, Object?>) {
      _discriminator(entry, discriminator);
    }
    for (final DocumentNode child in node.children(file.family)) {
      _index(file, child, base, dialect);
    }
    return entry;
  }

  void _queue(_Entry entry, String key, NodeKind expected) {
    final Map<String, Object?> fields = entry.node.fields;
    if (!fields.containsKey(key)) {
      return;
    }
    final Object? text = fields[key];
    if (text is! String) {
      _fail(
        entry.file.at(appendPointer(entry.node.pointer, key)),
        'invalidReference',
        'Expected a URI string.',
      );
    }
    pending.add((
      source: entry,
      pointer: appendPointer(entry.node.pointer, key),
      base: entry.base,
      text: text,
      expected: expected,
    ));
  }

  static final _componentName = RegExp(r'^[a-zA-Z0-9._-]+$');

  void _discriminator(_Entry entry, Map<String, Object?> discriminator) {
    final path = '${entry.node.pointer}/discriminator';
    void target(String pointer, String text) {
      final bool named =
          _componentName.hasMatch(text) && text != '.' && text != '..';
      pending.add((
        source: entry,
        pointer: pointer,
        base: named ? entryUri : entry.base,
        text: named ? '#/components/schemas/$text' : text,
        expected: NodeKind.schema,
      ));
    }

    if (discriminator['mapping'] case final Map<String, Object?> mapping) {
      for (final MapEntry<String, Object?> entry in mapping.entries) {
        if (entry.value case final String value) {
          target(appendPointer('$path/mapping', entry.key), value);
        }
      }
    }
    if ((entry.file.family, discriminator['defaultMapping']) case (
      OpenApiFamily.v32,
      final String value,
    )) {
      target('$path/defaultMapping', value);
    }
  }

  Future<void> _follow(_Pending edge) async {
    final ReferenceLocation origin = edge.source.file.at(edge.pointer);
    final Uri uri = _uri(edge.base, edge.text, origin);
    final Uri base = uri.removeFragment();
    final _Resource resource =
        resources[base] ?? await _load(base, edge, origin);
    final _File file = resource.file;
    if (!file.complete &&
        edge.expected == NodeKind.schema &&
        file.nodes.isEmpty) {
      _index(
        file,
        DocumentNode(NodeKind.schema, file.root, ''),
        file.uri ?? base,
        file.defaultDialect,
      );
    }
    final String fragment;
    try {
      fragment = Uri.decodeComponent(uri.fragment);
    } on FormatException catch (error) {
      _fail(
        origin,
        'invalidReference',
        'Invalid UTF-8 in URI fragment.',
        error,
      );
    }
    final _Entry target;
    String? dynamicName;
    if (fragment.isEmpty || fragment.startsWith('/')) {
      if (_invalidEscape.hasMatch(fragment)) {
        _fail(
          origin,
          'invalidReference',
          'Invalid JSON Pointer escape in $uri.',
        );
      }
      final pointer = '${resource.pointer}$fragment';
      final _Entry? existing = file.nodes[pointer];
      if (existing != null) {
        target = existing;
      } else if (!file.complete) {
        final Object? value = _valueAt(file.root, pointer, origin);
        final _Entry? root = file.nodes[resource.pointer];
        target = _index(
          file,
          DocumentNode(edge.expected, value, pointer),
          root?.base ?? file.uri ?? base,
          root?.dialect ?? file.defaultDialect,
        );
      } else {
        _fail(origin, 'missingTarget', 'No reference target at $uri.');
      }
    } else {
      final (Uri, String) key = (
        file.nodes[resource.pointer]?.base ?? base,
        fragment,
      );
      final _Entry? anchor = anchors[key];
      if (anchor == null) {
        _fail(origin, 'missingTarget', 'Unknown schema anchor: $uri.');
      }
      target = anchor;
      if (edge.pointer ==
              appendPointer(edge.source.node.pointer, r'$dynamicRef') &&
          dynamicAnchors.containsKey(key)) {
        dynamicName = fragment;
      }
    }
    if (target.node.kind != edge.expected ||
        !(target.node.value is Map<String, Object?> ||
            (file.modern &&
                edge.expected == NodeKind.schema &&
                target.node.value is bool))) {
      _fail(
        origin,
        'invalidTarget',
        'Expected a ${edge.expected.name} at $uri.',
      );
    }
    edges[origin] = ResolvedReference(
      uri: uri,
      target: target.target,
      dynamicAnchor: dynamicName,
    );
  }

  Future<_Resource> _load(
    Uri uri,
    _Pending edge,
    ReferenceLocation origin,
  ) async {
    final DocumentLoader? load = loader;
    if (!uri.hasScheme) {
      _fail(
        origin,
        'missingBaseUri',
        'A relative external reference requires an absolute base URI.',
      );
    }
    if (load == null) {
      _fail(origin, 'missingLoader', 'Supply a DocumentLoader for $uri.');
    }
    if (loadFailures[uri] case final Object cause) {
      _fail(origin, 'loadFailed', 'Cannot load $uri.', cause);
    }
    final SchemaSource source;
    try {
      source = await load.load(uri);
    } on Object catch (error) {
      loadFailures[uri] = error;
      _fail(origin, 'loadFailed', 'Cannot load $uri.', error);
    }
    final Uri actual = uri.resolveUri(source.uri ?? uri).removeFragment();
    if (!resources.containsKey(actual)) {
      try {
        final DecodedDocument decoded = const SourceDecoder().decode(
          source,
          config,
        );
        final Object? value = decoded.value;
        if (value is Map<String, Object?> &&
            (value.containsKey('swagger') || value.containsKey('openapi'))) {
          final OpenApiDocument doc = readDocument(decoded, config);
          _add(value, actual, doc.version.family, complete: true);
        } else {
          _add(value, actual, edge.source.file.family, complete: false);
        }
      } on OpenApiException catch (error) {
        if (error is ReferenceResolutionException) {
          rethrow;
        }
        _fail(origin, 'invalidDocument', 'Cannot parse $actual.', error);
      }
    }
    final _Resource resource = resources[actual]!;
    _register(uri, resource.file, resource.pointer, resource.pointer);
    return resource;
  }

  Object? _valueAt(Object? root, String pointer, ReferenceLocation origin) {
    var value = root;
    for (final String part in pointer.split('/').skip(1)) {
      final String key = part.replaceAll('~1', '/').replaceAll('~0', '~');
      if (value is Map<String, Object?> && value.containsKey(key)) {
        value = value[key];
      } else if (value is List<Object?> && _indexToken.hasMatch(key)) {
        final int? index = int.tryParse(key);
        if (index == null || index >= value.length) {
          _fail(origin, 'missingTarget', 'No array item at $pointer.');
        }
        value = value[index];
      } else {
        _fail(origin, 'missingTarget', 'No value at $pointer.');
      }
    }
    return value;
  }
}
