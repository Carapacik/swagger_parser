part of 'dart_model_mapper.dart';

extension on _Mapping {
  Set<String> _inferRequired(_SchemaUse schema) => {
    for (final MapEntry<String, _SchemaUse> property
        in schema.properties.entries)
      if (_schemaDefault(property.value) == null &&
          _acceptsInferredNull(property.value, {}) == false)
        property.key,
  };

  // Unknown or recursive constraints cannot prove that a property rejects null.
  bool? _acceptsInferredNull(_SchemaUse schema, Set<_SchemaUse> active) {
    if (!active.add(schema)) {
      return null;
    }
    if (schema.dialect case final dialect?
        when SchemaDialect.identify(dialect, schema.family) ==
            SchemaDialect.unknown) {
      return null;
    }
    final Map<String, Object?> fields = schema.rawFields;
    if (schema.definition.value is bool) {
      return schema.definition.value! as bool;
    }
    if (schema.swaggerNullable == false) {
      return false;
    }
    if (schema.swaggerNullable == true && schema.reference != null) {
      return _nullable(schema);
    }
    final bool legacyRef =
        schema.reference != null &&
        (schema.family == OpenApiFamily.swaggerV2 ||
            schema.family == OpenApiFamily.v30);
    bool? check(_SchemaUse child) => _acceptsInferredNull(child, {...active});
    if (legacyRef) {
      return check(schema.reference!);
    }
    if ((schema.types.isNotEmpty && !schema.types.contains('null')) ||
        (fields.containsKey('const') && fields['const'] != null) ||
        (fields['enum'] is List<Object?> &&
            !(fields['enum']! as List<Object?>).contains(null))) {
      return false;
    }
    bool unknown = fields.keys.any(
      const {'not', 'if', 'then', 'else'}.contains,
    );
    for (final _SchemaUse child in [?schema.reference, ...schema.allOf]) {
      final bool? accepts = check(child);
      if (accepts == false) {
        return false;
      }
      unknown |= accepts == null;
    }
    if (schema.anyOf.isNotEmpty) {
      final List<bool?> accepts = schema.anyOf.map(check).toList();
      if (!accepts.contains(true)) {
        if (!accepts.contains(null)) {
          return false;
        }
        unknown = true;
      }
    }
    if (schema.oneOf.isNotEmpty) {
      final List<bool?> accepts = schema.oneOf.map(check).toList();
      final int matches = accepts.where((value) => value == true).length;
      if (matches > 1 || (matches == 0 && !accepts.contains(null))) {
        return false;
      }
      unknown |= accepts.contains(null);
    }
    return unknown ? null : true;
  }
}
