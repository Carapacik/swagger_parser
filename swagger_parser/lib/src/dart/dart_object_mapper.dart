part of 'dart_model_mapper.dart';

extension on _Mapping {
  _ObjectShape _shape(_SchemaUse id, {_SchemaUse? common}) {
    final properties = <String, _SchemaUse>{};
    final required = <String>{};
    final ignored = <String>{};
    final active = <_SchemaUse>{};
    final restrictedShapes = <Set<String>>[];
    var closed = false;
    _SchemaUse? extra;
    void merge(_SchemaUse part) {
      if (!active.add(part)) {
        _fail(part, 'Object composition contains a cycle.');
      }
      final _SchemaUse schema = _schema(part);
      ignored.addAll(schema.excludedProperties);
      if (schema.reference case final target?) {
        _checkRef(schema);
        merge(target);
      } else {
        if (schema.types.any((type) => type != 'object' && type != 'null') ||
            _cases(schema) != null ||
            (_hasAlternatives(schema) && part != common) ||
            schema.definition.value == false) {
          _fail(part, 'Expected object branches in allOf.');
        }
        for (final _SchemaUse child in schema.allOf) {
          merge(child);
        }
        for (final MapEntry<String, _SchemaUse> field
            in schema.properties.entries) {
          final _SchemaUse? previous = properties[field.key];
          properties[field.key] = previous == null
              ? field.value
              : _intersection(previous, field.value, part, field.key);
        }
        required.addAll(schema.requiredProperties);
        if (schema.fields['additionalProperties'] == false) {
          closed = true;
          restrictedShapes.add(schema.properties.keys.toSet());
        } else if (schema.additionalProperties case final child?
            when child.definition.value != true) {
          restrictedShapes.add(schema.properties.keys.toSet());
          if (extra != null && extra != child) {
            _fail(part, 'Conflicting additional property schemas.');
          }
          extra = child;
        }
      }
      active.remove(part);
    }

    merge(id);
    if (common != null) {
      merge(common);
    }
    if (restrictedShapes.any((keys) => !keys.containsAll(properties.keys)) ||
        (closed && !properties.keys.toSet().containsAll(required))) {
      _fail(id, 'Cannot map undeclared or conflicting required properties.');
    }
    properties.removeWhere((key, _) => ignored.contains(key));
    required.removeAll(ignored);
    return _ObjectShape(
      properties,
      required,
      extra,
      closed: closed,
      ignored: ignored,
    );
  }

  void _object(String name, _ObjectShape shape) {
    final Set<String> used = {
      ..._memberNames,
      if (config.generateValidators) 'validate',
      if (config.serializer == DtoSerializer.freezed ||
          config.serializer == DtoSerializer.dartMappable)
        'copyWith',
      if (config.serializer == DtoSerializer.dartMappable) 'toMap',
      name,
    };
    final Map<String, DartDocumentation> docs = fieldDocumentation[name] =
        <String, DartDocumentation>{};
    final fields = <DartFieldModel>[];
    for (final String wireName in {
      ...shape.properties.keys,
      ...shape.required,
    }) {
      final String field = _identifier(wireName, used);
      final _SchemaUse? id = shape.properties[wireName] ?? shape.extra;
      if (id != null) {
        docs[field] = _schemaDocumentation(id);
      }
      final DartTypeReference type = id == null
          ? _any
          : _type(id, '${name}_$wireName');
      final bool isRequired = shape.required.contains(wireName);
      final JsonValue? defaultValue = isRequired || id == null
          ? null
          : _schemaDefault(id);
      final bool acceptsNull =
          type.isNullable ||
          type.symbol == 'Null' ||
          (!isRequired && id != null && _unionAcceptsNull(id));
      fields.add(
        DartFieldModel(
          name: field,
          wireName: wireName,
          acceptsNull: acceptsNull,
          usePresenceRecord: config.usePresenceRecords,
          type: isRequired || type.isNullable || defaultValue != null
              ? type
              : DartTypeReference(
                  symbol: type.symbol,
                  importUrl: type.importUrl,
                  scalarCodec: type.scalarCodec,
                  typeArguments: type.typeArguments,
                  isNullable: true,
                  isMetadataEnum: type.isMetadataEnum,
                ),
          isRequired: isRequired,
          defaultValue: defaultValue,
        ),
      );
    }
    dtos.add(
      DartDtoModel(
        name: name,
        fields: fields,
        json: true,
        ignoredWireKeys: shape.ignored,
        extraValueType: shape.closed
            ? null
            : shape.extra == null
            ? _any
            : _type(shape.extra!, '${name}AdditionalValue'),
      ),
    );
  }

  bool _unionAcceptsNull(_SchemaUse id) {
    final _SchemaUse target = _concrete(id);
    if (!_hasAlternatives(target) || _usesDiscriminator(target)) {
      return false;
    }
    // Only scalar predicates and composition can reject a JSON null.
    final active = <_SchemaUse>{};
    final memo = <_SchemaUse, bool>{};
    bool accepts(_SchemaUse schema) {
      if (memo[schema] case final result?) {
        return result;
      }
      if (!active.add(schema)) {
        _fail(
          schema,
          'Recursive union matching must descend into a property or item.',
        );
      }
      final Object? values = schema.fields['enum'];
      final bool result =
          schema.definition.value != false &&
          (schema.types.isEmpty || schema.types.contains('null')) &&
          schema.fields['const'] == null &&
          (values is! List<Object?> || values.contains(null)) &&
          (schema.reference == null || accepts(schema.reference!)) &&
          schema.allOf.every(accepts) &&
          (schema.anyOf.isEmpty || schema.anyOf.any(accepts)) &&
          (schema.oneOf.isEmpty || schema.oneOf.where(accepts).length == 1);
      active.remove(schema);
      return memo[schema] = result;
    }

    return accepts(target);
  }

  _SchemaUse _intersection(
    _SchemaUse left,
    _SchemaUse right,
    _SchemaUse owner,
    String property,
  ) {
    final _SchemaUse a = _concrete(left);
    final _SchemaUse b = _concrete(right);
    if (a == b) {
      return _nullable(left) && !_nullable(right) ? right : left;
    }
    // Keep both constraint sets and their reference scopes.
    final Set<String>? leftTypes = _conjunctiveTypes(a);
    final Set<String>? rightTypes = _conjunctiveTypes(b);
    final Set<String> commonTypes =
        leftTypes?.intersection(rightTypes ?? const {}) ?? const {};
    final Iterable<String> concreteTypes = commonTypes.where(
      (type) =>
          type != 'null' &&
          !(type == 'integer' && commonTypes.contains('number')),
    );
    const scalarTypes = {'string', 'integer', 'number', 'boolean', 'null'};
    if (leftTypes != null &&
        rightTypes != null &&
        leftTypes.isNotEmpty &&
        rightTypes.isNotEmpty &&
        scalarTypes.containsAll({...leftTypes, ...rightTypes}) &&
        concreteTypes.length == 1 &&
        _cases(a) == null &&
        _cases(b) == null &&
        !_hasAlternatives(a) &&
        !_hasAlternatives(b) &&
        _customType(left) == null &&
        _customType(right) == null) {
      return intersections.putIfAbsent(
        (left, right),
        () => _SchemaUse(
          index,
          left.location,
          ApiSchema(
            family: left.family,
            dialect: left.dialect,
            definition: JsonValue(const <String, Object?>{}),
            types: const [],
            properties: const {},
            requiredProperties: const [],
          ),
          left.bindings,
          left.direction,
          const {},
          suppressInference: true,
          intersectionBranches: [left, right],
        ),
      );
    }
    if (_isSubset(a, b)) {
      return left;
    }
    if (_isSubset(b, a)) {
      return right;
    }
    _fail(owner, 'Conflicting allOf property: $property.');
  }

  // A scalar enum or const can narrow a scalar field inherited through allOf.
  bool _isSubset(_SchemaUse narrowId, _SchemaUse wideId) {
    final _SchemaUse narrow = _schema(narrowId);
    final _SchemaUse wide = _schema(wideId);
    if (wide.fields.keys.any(
      (key) => !const {
        'type',
        'enum',
        'const',
        'nullable',
        'x-nullable',
        'description',
        'title',
        'example',
        'examples',
        'readOnly',
        'writeOnly',
      }.contains(key),
    )) {
      return false;
    }
    final List<Object?>? wideCases = _cases(wide);
    if (_cases(narrow) case final cases?) {
      return cases.every(
        (value) =>
            (wideCases == null || wideCases.contains(value)) &&
            _allowsScalar(wide.types, value),
      );
    }
    return wideCases == null &&
        narrow.types.isNotEmpty &&
        narrow.types.every(
          (type) =>
              const {
                'string',
                'integer',
                'number',
                'boolean',
                'null',
              }.contains(type) &&
              (wide.types.isEmpty ||
                  wide.types.contains(type) ||
                  (type == 'integer' && wide.types.contains('number'))),
        );
  }
}

final class const _ObjectShape(
  final Map<String, _SchemaUse> properties,
  final Set<String> required,
  final _SchemaUse? extra, {
  required final bool closed,
  final Set<String> ignored = const {},
}) {
  bool matches(_ObjectShape other) =>
      closed == other.closed &&
      ignored.length == other.ignored.length &&
      ignored.containsAll(other.ignored) &&
      extra == other.extra &&
      required.length == other.required.length &&
      required.containsAll(other.required) &&
      properties.length == other.properties.length &&
      properties.entries.every((e) => other.properties[e.key] == e.value);
}

bool _allowsScalar(Set<String> types, Object? value) =>
    types.isEmpty ||
    switch (value) {
      String() => types.contains('string'),
      bool() => types.contains('boolean'),
      int() => types.contains('integer') || types.contains('number'),
      num() =>
        types.contains('number') ||
            (types.contains('integer') &&
                value.isFinite &&
                value == value.truncateToDouble()),
      null => types.contains('null'),
      _ => false,
    };
