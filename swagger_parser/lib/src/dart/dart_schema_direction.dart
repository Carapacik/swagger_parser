part of 'dart_model_mapper.dart';

enum _Direction() {
  request,
  response,
}

final class _SchemaDirections(
  final Map<ReferenceLocation, ApiSchema> schemas, [
  final Map<String, ReferenceLocation> bindings = const {},
  Set<ReferenceLocation> mapped = const {},
]) {
  this {
    for (final MapEntry<ReferenceLocation, ApiSchema> entry
        in schemas.entries) {
      final ApiSchema schema = entry.value;
      final Object? fields = schema.definition.value;
      final bool legacy =
          schema.family == OpenApiFamily.swaggerV2 ||
          schema.family == OpenApiFamily.v30;
      access[entry.key] =
          fields is Map<String, Object?> &&
              !(legacy && schema.reference != null)
          ? (fields['readOnly'] == true ? 1 : 0) |
                (schema.family != OpenApiFamily.swaggerV2 &&
                        fields['writeOnly'] == true
                    ? 2
                    : 0)
          : 0;
    }
    changedSchemas.addAll(mapped);
    var changed = true;
    while (changed) {
      changed = false;
      for (final MapEntry<ReferenceLocation, ApiSchema> entry
          in schemas.entries) {
        int flags = access[entry.key]!;
        for (final ReferenceLocation target in _composition(entry.value)) {
          flags |= access[target] ?? 0;
        }
        if (flags != access[entry.key]) {
          access[entry.key] = flags;
          changed = true;
        }
      }
    }
    final parents = <ReferenceLocation, Set<ReferenceLocation>>{};
    for (final MapEntry<ReferenceLocation, ApiSchema> entry
        in schemas.entries) {
      final ApiSchema schema = entry.value;
      for (final ReferenceLocation target in schema.properties.values) {
        final int flags = access[target] ?? 0;
        if (flags == 3) {
          throw GenerationException(
            'A Dart property cannot be both readOnly and writeOnly: $target.',
          );
        }
        if (flags != 0) {
          changedSchemas.add(entry.key);
        }
      }
      for (final ReferenceLocation target in [
        ..._composition(schema),
        ...schema.properties.values,
        ?schema.items,
        ...schema.prefixItems,
        ?schema.contains,
        ?schema.additionalProperties,
        ...schema.oneOf,
        ...schema.anyOf,
        ...?schema.discriminator?.mapping.values,
        ?schema.discriminator?.defaultMapping,
      ]) {
        (parents[target] ??= {}).add(entry.key);
      }
    }
    // A Swagger base also depends on its polymorphic descendants.
    for (final MapEntry<ReferenceLocation, ApiSchema> entry
        in schemas.entries) {
      if (entry.value.family != OpenApiFamily.swaggerV2 ||
          entry.value.allOf.isEmpty) {
        continue;
      }
      final seen = <ReferenceLocation>{};
      void inherit(ReferenceLocation target) {
        if (!seen.add(target)) {
          return;
        }
        final ApiSchema parent = schemas[target]!;
        final Object? fields = parent.definition.value;
        if (fields is Map<String, Object?> &&
            fields['discriminator'] is String) {
          (parents[entry.key] ??= {}).add(target);
        }
        for (final ReferenceLocation next in [
          ?parent.reference,
          ...parent.allOf,
        ]) {
          inherit(next);
        }
      }

      entry.value.allOf.forEach(inherit);
    }
    final List<ReferenceLocation> pending = changedSchemas.toList();
    while (pending.isNotEmpty) {
      for (final ReferenceLocation parent
          in parents[pending.removeLast()] ?? const <ReferenceLocation>{}) {
        if (changedSchemas.add(parent)) {
          pending.add(parent);
        }
      }
    }
  }

  final access = <ReferenceLocation, int>{};
  final changedSchemas = <ReferenceLocation>{};

  Iterable<ReferenceLocation> _composition(ApiSchema schema) => [
    ?schema.reference,
    if (schema.dynamicReference case final reference?)
      bindings[reference.dynamicAnchor] ?? reference.target.location,
    ...schema.allOf,
  ];

  Set<String> excluded(ReferenceLocation id, _Direction direction) {
    final result = <String>{};
    final seen = <ReferenceLocation>{};
    final pending = [id];
    final mask = direction == _Direction.request ? 1 : 2;
    while (pending.isNotEmpty) {
      final ReferenceLocation current = pending.removeLast();
      if (!seen.add(current)) {
        continue;
      }
      final ApiSchema schema = schemas[current]!;
      for (final MapEntry<String, ReferenceLocation> property
          in schema.properties.entries) {
        if (((access[property.value] ?? 0) & mask) != 0) {
          result.add(property.key);
        }
      }
      pending.addAll(_composition(schema));
    }
    return result;
  }
}
