part of 'api_definition_extractor.dart';

final class _SchemaRegistry(final ReferenceGraph graph) {
  this {
    final Set<String> names = {
      for (final ref in graph.references.values) ?ref.dynamicAnchor,
    };
    for (final MapEntry<(Uri, String), ReferenceTarget> entry
        in graph.dynamicAnchors.entries) {
      if (names.contains(entry.key.$2)) {
        (anchors[entry.key.$1] ??= []).add(entry.value);
      }
    }
  }
  final schemas = <ReferenceLocation, ApiSchema>{};
  final anchors = <Uri, List<ReferenceTarget>>{};
  final visitedResources = <Uri>{};

  ReferenceLocation use(LocatedNode site) {
    final ReferenceLocation id = register(site);
    final ReferenceLocation? ref = schemas[id]!.reference;
    return ref != null &&
            site.node.fields.length == 1 &&
            !anchors.containsKey(graph.schemaResources[id])
        ? ref
        : id;
  }

  ReferenceLocation register(LocatedNode site) {
    final ReferenceLocation id = site.location;
    if (schemas.containsKey(id)) {
      return id;
    }
    final Map<String, Object?> fields = site.node.fields;
    final bool modern =
        site.family == OpenApiFamily.v31 || site.family == OpenApiFamily.v32;
    final String? dialect = modern
        ? (fields[r'$schema'] as String? ??
              site.dialect ??
              (site.family == OpenApiFamily.v32
                  ? OpenApiV32Schema.oasDialect
                  : OpenApiV31Schema.oasDialect))
        : null;
    final bool opaque =
        dialect != null &&
        SchemaDialect.identify(dialect, site.family) == SchemaDialect.unknown;
    final children = <LocatedNode>[];
    final properties = <String, ReferenceLocation>{};
    ReferenceLocation? items;
    final prefixItems = <ReferenceLocation>[];
    ReferenceLocation? contains;
    ReferenceLocation? additionalProperties;
    final allOf = <ReferenceLocation>[];
    final oneOf = <ReferenceLocation>[];
    final anyOf = <ReferenceLocation>[];
    final types = <String>{};
    final required = <String>{};
    ResolvedReference? ref;
    ResolvedReference? dynamicRef;
    if (!opaque) {
      if (fields.containsKey(r'$ref')) {
        ref = _edge(site, r'$ref');
      }
      if (modern && fields.containsKey(r'$dynamicRef')) {
        dynamicRef = _edge(site, r'$dynamicRef');
      }
      if (modern || ref == null) {
        switch (fields['type']) {
          case final String type:
            types.add(type);
            if ((site.family == OpenApiFamily.v30 &&
                    fields['nullable'] == true) ||
                (site.family == OpenApiFamily.swaggerV2 &&
                    fields['x-nullable'] == true)) {
              types.add('null');
            }
          case final List<Object?> names:
            types.addAll(names.whereType<String>());
        }
        if (fields['required'] case final List<Object?> names) {
          required.addAll(names.whereType<String>());
        }
        final context = LocatedNode(
          site.node,
          site.uri,
          site.family,
          dialect: dialect,
        );
        for (final LocatedNode child in context.children(NodeKind.schema)) {
          children.add(child);
          final String relative = child.node.pointer.substring(
            site.node.pointer.length,
          );
          if (relative.startsWith('/properties/')) {
            properties[child.node.key] = child.location;
          }
          if (relative == '/additionalProperties') {
            additionalProperties = child.location;
          }
          if (relative.startsWith('/allOf/')) {
            allOf.add(child.location);
          }
          if (relative.startsWith('/oneOf/')) {
            oneOf.add(child.location);
          }
          if (relative.startsWith('/anyOf/')) {
            anyOf.add(child.location);
          }
          if (relative == '/items') {
            items = child.location;
          }
          if (relative.startsWith('/prefixItems/')) {
            prefixItems.add(child.location);
          }
          if (relative == '/contains') {
            contains = child.location;
          }
        }
      }
    }
    final Uri? resource = graph.schemaResources[id];
    schemas[id] = ApiSchema(
      family: site.family,
      definition: JsonValue(site.node.value),
      dialect: dialect,
      types: types,
      requiredProperties: required,
      properties: properties,
      items: items,
      prefixItems: prefixItems,
      contains: contains,
      additionalProperties: additionalProperties,
      allOf: allOf,
      oneOf: oneOf,
      anyOf: anyOf,
      discriminator: oneOf.isEmpty && anyOf.isEmpty
          ? null
          : _discriminator(site, children),
      reference: ref?.target.location,
      dynamicReference: dynamicRef,
      resourceUri: resource,
    );
    if (resource != null && visitedResources.add(resource)) {
      for (final ReferenceTarget target
          in anchors[resource] ?? const <ReferenceTarget>[]) {
        register(site.target(target));
      }
    }
    for (final child in children) {
      register(child);
    }
    if (ref != null) {
      register(site.target(ref.target));
    }
    if (dynamicRef != null) {
      register(site.target(dynamicRef.target));
    }
    return id;
  }

  ApiDiscriminator? _discriminator(
    LocatedNode site,
    List<LocatedNode> children,
  ) {
    ReferenceLocation target(String field) {
      final LocatedNode node = site.target(
        _edge(site, 'discriminator/$field').target,
      );
      children.add(node);
      return node.location;
    }

    if (site.node.fields['discriminator']
        case final Map<String, Object?> fields) {
      final mapping = <String, ReferenceLocation>{};
      if (fields['mapping'] case final Map<String, Object?> entries) {
        for (final String key in entries.keys) {
          final String token = key.replaceAll('~', '~0').replaceAll('/', '~1');
          mapping[key] = target('mapping/$token');
        }
      }
      return ApiDiscriminator(
        fields['propertyName']! as String,
        mapping,
        defaultMapping:
            site.family == OpenApiFamily.v32 &&
                fields.containsKey('defaultMapping')
            ? target('defaultMapping')
            : null,
      );
    }
    return null;
  }

  ResolvedReference _edge(LocatedNode site, String field) =>
      graph.references[site.at('${site.node.pointer}/$field')] ??
      _fail(
        site,
        'Missing resolved schema reference.',
        field: field,
        code: 'unresolvedDefinition',
      );
}
