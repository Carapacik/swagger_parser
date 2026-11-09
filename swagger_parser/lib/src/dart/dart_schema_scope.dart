part of 'dart_model_mapper.dart';

// A decoder and its predicates must use the same targets for dynamic references.
final class _SchemaIndex(
  final Map<ReferenceLocation, ApiSchema> schemas,
  final Map<(Uri, String), ReferenceLocation> anchors, [
  final Set<String> Function(_SchemaUse)? inferRequired,
]) {
  this {
    if (!schemas.values.any((s) => s.dynamicReference?.dynamicAnchor != null)) {
      return;
    }

    final targets = <String, List<ReferenceLocation>>{};
    for (final MapEntry<(Uri, String), ReferenceLocation> entry
        in anchors.entries) {
      (targets[entry.key.$2] ??= []).add(entry.value);
    }

    // Propagate only the anchor names that can affect each schema.
    final parents = <ReferenceLocation, Set<ReferenceLocation>>{};
    final pending = <(ReferenceLocation, String)>[];
    for (final MapEntry<ReferenceLocation, ApiSchema> entry
        in schemas.entries) {
      final ApiSchema schema = entry.value;
      final String? name = schema.dynamicReference?.dynamicAnchor;
      if (name != null) {
        pending.add((entry.key, name));
      }
      for (final ReferenceLocation target in [
        ?schema.reference,
        ?schema.dynamicReference?.target.location,
        if (name != null) ...?targets[name],
        ...schema.properties.values,
        ?schema.items,
        ...schema.prefixItems,
        ?schema.contains,
        ?schema.additionalProperties,
        ...schema.allOf,
        ...schema.oneOf,
        ...schema.anyOf,
        ...?schema.discriminator?.mapping.values,
        ?schema.discriminator?.defaultMapping,
      ]) {
        (parents[target] ??= {}).add(entry.key);
      }
    }
    while (pending.isNotEmpty) {
      final (ReferenceLocation id, String name) = pending.removeLast();
      if ((dependencies[id] ??= {}).add(name)) {
        for (final ReferenceLocation parent
            in parents[id] ?? const <ReferenceLocation>{}) {
          pending.add((parent, name));
        }
      }
    }
  }

  final dependencies = <ReferenceLocation, Set<String>>{};
  final uses = <ReferenceLocation, _ScopeCache>{};
  // Explicit rules can split equal JSON shapes.
  final mappedDirections = <ReferenceLocation>{};
  late final directions = _SchemaDirections(
    schemas,
    const {},
    mappedDirections,
  );
  late final naturalDirections = _SchemaDirections(schemas);

  bool hasDirectionalShape(_SchemaUse schema) =>
      (schema.bindings.isEmpty
              ? naturalDirections
              : _SchemaDirections(schemas, schema.bindings))
          .changedSchemas
          .contains(schema.location);

  _SchemaUse use(
    ReferenceLocation id, [
    Map<String, ReferenceLocation> outer = const {},
    _Direction? direction,
    Set<String> excluded = const {},
    _RequiredMode requiredMode = _RequiredMode.infer,
  ]) {
    final ApiSchema raw = schemas[id]!;
    _ScopeCache cache = uses.putIfAbsent(id, _ScopeCache.new);
    final Set<String>? names = dependencies[id];
    final bindings = <String, ReferenceLocation>{};
    // Each cache level selects the target of one anchor name.
    for (final String name in names ?? const <String>{}) {
      final ReferenceLocation? target =
          outer[name] ?? anchors[(raw.resourceUri, name)];
      cache = cache.targets.putIfAbsent(target, _ScopeCache.new);
      if (target != null) {
        bindings[name] = target;
      }
    }
    final _SchemaDirections rules = bindings.isEmpty
        ? directions
        : cache.directions ??= _SchemaDirections(
            schemas,
            bindings,
            mappedDirections,
          );
    final _Direction? effective =
        !rules.changedSchemas.contains(id) && excluded.isEmpty
        ? null
        : direction;
    final blocked = <String>{
      ...excluded,
      if (effective != null) ...rules.excluded(id, effective),
    };
    final List<String> keys = blocked.toList()..sort();
    final bool suppress =
        requiredMode == _RequiredMode.suppress ||
        inferRequired == null ||
        _explicitRequired(id, bindings);
    final (_Direction?, String, bool) key = (
      effective,
      keys.map(Uri.encodeComponent).join('/'),
      suppress,
    );
    return cache.uses.putIfAbsent(
      key,
      () => _SchemaUse(
        this,
        id,
        raw,
        bindings,
        effective,
        blocked,
        suppressInference: suppress,
      ),
    );
  }

  bool _explicitRequired(
    ReferenceLocation id,
    Map<String, ReferenceLocation> bindings, [
    Set<ReferenceLocation>? active,
  ]) {
    if (!(active ??= {}).add(id)) {
      return true;
    }
    final ApiSchema schema = schemas[id]!;
    final Object? fields = schema.definition.value;
    final bool legacyRef =
        schema.reference != null &&
        (schema.family == OpenApiFamily.swaggerV2 ||
            schema.family == OpenApiFamily.v30);
    if (!legacyRef &&
        fields is Map<String, Object?> &&
        (fields.containsKey('required') ||
            schema.requiredProperties.isNotEmpty)) {
      return true;
    }
    for (final ReferenceLocation target in [
      ?schema.reference,
      if (schema.dynamicReference case final ref?)
        bindings[ref.dynamicAnchor] ?? ref.target.location,
      ...schema.allOf,
    ]) {
      if (_explicitRequired(target, bindings, {...active})) {
        return true;
      }
    }
    return false;
  }
}

enum _RequiredMode() {
  infer,
  suppress,
}

final class _ScopeCache() {
  _SchemaDirections? directions;
  final targets = <ReferenceLocation?, _ScopeCache>{};
  final uses = <(_Direction?, String, bool), _SchemaUse>{};
}

// Identity includes the schema, anchor bindings, direction, and required policy.
final class _SchemaUse(
  final _SchemaIndex index,
  final ReferenceLocation location,
  final ApiSchema raw,
  final Map<String, ReferenceLocation> bindings,
  final _Direction? direction,
  final Set<String> excludedProperties, {
  required final bool suppressInference,
  final List<_SchemaUse>? intersectionBranches,
}) {
  _SchemaUse child(ReferenceLocation target) =>
      index.use(target, bindings, direction);
  _SchemaUse _alternative(ReferenceLocation target) => index.use(
    target,
    bindings,
    direction,
    const {},
    suppressInference ? _RequiredMode.suppress : _RequiredMode.infer,
  );
  _SchemaUse _composed(ReferenceLocation target) => index.use(
    target,
    bindings,
    direction,
    excludedProperties,
    suppressInference ? _RequiredMode.suppress : _RequiredMode.infer,
  );
  String get pointer => location.pointer;
  Set<String> get types => raw.types;
  late final Set<String> requiredProperties = {
    ...raw.requiredProperties.difference(excludedProperties),
    if (!suppressInference) ...index.inferRequired!(this),
  };
  OpenApiFamily get family => raw.family;
  bool? get swaggerNullable => family == OpenApiFamily.swaggerV2
      ? rawFields['x-nullable'] as bool?
      : null;
  String? get dialect => raw.dialect;
  JsonValue get definition => raw.definition;
  Map<String, Object?> get rawFields => switch (raw.definition.value) {
    final Map<String, Object?> value => value,
    _ => const {},
  };
  late final Map<String, Object?> fields = {
    ...rawFields,
    if (rawFields.containsKey('required') || requiredProperties.isNotEmpty)
      'required': requiredProperties.toList(),
  };

  late final Map<String, _SchemaUse> properties = {
    for (final entry in raw.properties.entries)
      if (!excludedProperties.contains(entry.key))
        entry.key: child(entry.value),
  };
  late final _SchemaUse? items = raw.items == null ? null : child(raw.items!);
  late final List<_SchemaUse> prefixItems = raw.prefixItems.map(child).toList();
  late final _SchemaUse? contains = raw.contains == null
      ? null
      : child(raw.contains!);
  late final _SchemaUse? additionalProperties = raw.additionalProperties == null
      ? null
      : child(raw.additionalProperties!);
  late final List<_SchemaUse> oneOf = raw.oneOf.map(_alternative).toList();
  late final List<_SchemaUse> anyOf = raw.anyOf.map(_alternative).toList();

  late final ReferenceLocation? _dynamicTarget = switch (raw.dynamicReference) {
    final ResolvedReference edge =>
      bindings[edge.dynamicAnchor] ?? edge.target.location,
    null => null,
  };

  // Schema reference siblings intersect with their target in OpenAPI 3.1+.
  late final bool _intersection = _needsIntersection();

  bool _needsIntersection() {
    final ReferenceLocation? target =
        _dynamicTarget ??
        (family == OpenApiFamily.v31 || family == OpenApiFamily.v32
            ? raw.reference
            : null);
    if (target == null) {
      return false;
    }
    final Set<String> targetTypes = index.schemas[target]!.types;
    return (raw.reference != null && _dynamicTarget != null) ||
        rawFields.keys.any((key) {
          if (key == 'type') {
            return targetTypes.isEmpty || !types.containsAll(targetTypes);
          }
          return _referenceShapeKeywords.contains(key);
        });
  }

  late final _SchemaUse? reference = switch (raw.reference ?? _dynamicTarget) {
    final ReferenceLocation id when !_intersection => _composed(id),
    _ => null,
  };
  late final List<_SchemaUse> allOf =
      intersectionBranches ??
      [
        if (_intersection) ...[
          if (raw.reference case final id?) _composed(id),
          if (_dynamicTarget case final id?) _composed(id),
        ],
        ...raw.allOf.map(_composed),
      ];
}

const _referenceShapeKeywords = {
  'type',
  'properties',
  'items',
  'prefixItems',
  'allOf',
  'oneOf',
  'anyOf',
  'const',
  'enum',
  'required',
  'additionalProperties',
};
