part of 'dart_model_mapper.dart';

extension on _Mapping {
  JsonValue? _schemaDefault(_SchemaUse id, [Set<_SchemaUse>? seen]) {
    if (!(seen ??= {}).add(id)) {
      return null;
    }
    final bool legacyRef =
        id.reference != null &&
        (id.family == OpenApiFamily.swaggerV2 ||
            id.family == OpenApiFamily.v30);
    if (!legacyRef && id.rawFields.containsKey('default')) {
      return JsonValue(id.rawFields['default']);
    }
    final List<JsonValue> inherited = [
      for (final child in [?id.reference, ...id.allOf])
        ?_schemaDefault(child, {...seen}),
    ];
    if (inherited.any((v) => !_sameDefault(v.value, inherited.first.value))) {
      _fail(id, 'Conflicting schema defaults.');
    }
    return inherited.firstOrNull;
  }

  _ConstantExpression _applyDefaults() {
    final Map<String, DartDtoModel> models = {
      for (final dto in dtos) dto.name: dto,
    };
    final Map<String, DartEnumModel> enumTypes = {
      for (final value in enums) value.name: value,
    };
    final Map<String, DartValueModel> wrappers = {
      for (final value in values) value.name: value,
    };
    final Set<String> constantTypes = {
      ...models.keys,
      ...enumTypes.keys,
      ...wrappers.keys,
      for (final value in tuples) value.name,
      for (final value in unions) value.name,
      for (final value in structuralUnions) value.name,
    };
    final active = <DartFieldModel>{};
    final resolved = <DartFieldModel, DartFieldModel>{};

    Never fail(String path, String reason) =>
        throw GenerationException('Invalid default for $path: $reason');
    String literal(Object? value) => jsonEncode(value).replaceAll(r'$', r'\$');
    String typeCode(DartTypeReference type, Set<String> dependencies) {
      if (type.scalarCodec != null || constantTypes.contains(type.symbol)) {
        dependencies.add(type.symbol);
      }
      return '${type.symbol}'
          '${type.typeArguments.isEmpty ? '' : '<${type.typeArguments.map((t) => typeCode(t, dependencies)).join(',')}>'}'
          '${type.isNullable ? '?' : ''}';
    }

    late DartFieldModel Function(DartFieldModel, String) resolve;
    String expression(
      DartTypeReference type,
      Object? value,
      String path,
      Set<String> dependencies,
    ) {
      if (value == null && (type.isNullable || type.symbol == 'Null')) {
        return 'null';
      }
      if (type.scalarCodec case final codec?) {
        for (final DartMappedDefault entry in codec.defaults) {
          if (_sameDefault(entry.value.value, value)) {
            dependencies.add(entry.expression);
            return entry.expression;
          }
        }
        fail(path, 'No constant mapping for this JSON default.');
      }
      if (enumTypes[type.symbol] case final e?) {
        for (final MapEntry<String, Object> entry in e.values.entries) {
          if (entry.value == value) {
            dependencies.add(e.name);
            return '${e.name}.${entry.key}';
          }
        }
        fail(path, 'Unknown enum value.');
      }
      if (wrappers[type.symbol] case final wrapper?) {
        dependencies.add(wrapper.name);
        return 'const ${wrapper.name}(${expression(wrapper.type, value, path, dependencies)})';
      }
      if (models[type.symbol] case final dto?) {
        if (value is! Map<String, Object?>) {
          fail(path, 'Expected an object.');
        }
        dependencies.add(dto.name);
        final args = <String>[];
        final Set<String> known = dto.ignoredWireKeys.toSet();
        for (final DartFieldModel field in dto.fields) {
          final String key = field.wireName ?? field.name;
          known.add(key);
          if (!value.containsKey(key)) {
            if (field.isRequired) {
              fail('$path/$key', 'Missing required property.');
            }
            if (field.defaultValue != null) {
              resolve(field, '$path/$key');
            }
            continue;
          }
          if (field.fixedValue case final fixed?) {
            if (!_sameDefault(value[key], fixed.value)) {
              fail('$path/$key', 'Unexpected discriminator value.');
            }
            continue;
          }
          if (value[key] == null && !field.acceptsNull) {
            fail('$path/$key', 'Null is not allowed.');
          }
          final String code = expression(
            field.type,
            value[key],
            '$path/$key',
            dependencies,
          );
          args.add(
            '${field.name}: ${field.tracksPresence ? '(value: $code)' : code}',
          );
        }
        final extras = <String>[];
        for (final MapEntry<String, Object?> entry in value.entries) {
          if (known.contains(entry.key)) {
            continue;
          }
          final DartTypeReference? extra = dto.extraValueType;
          if (extra == null) {
            fail('$path/${entry.key}', 'Unknown property.');
          }
          extras.add(
            '${literal(entry.key)}: ${expression(extra, entry.value, path, dependencies)}',
          );
        }
        if (extras.isNotEmpty) {
          args.add('additionalProperties: const {${extras.join(',')}}');
        }
        return 'const ${dto.name}(${args.join(',')})';
      }
      switch (type.symbol) {
        case 'String':
          if (value is String) {
            return literal(value);
          }
        case 'bool':
          if (value is bool) {
            return '$value';
          }
        case 'int':
          if (value is num &&
              value.isFinite &&
              value == value.truncateToDouble()) {
            return '${value.toInt()}';
          }
        case 'double':
          if (value is num && value.isFinite) {
            return '${value.toDouble()}';
          }
        case 'num':
          if (value is num && value.isFinite) {
            return '$value';
          }
        case 'List':
          if (value is List<Object?>) {
            if (value.isEmpty) {
              return 'const []';
            }
            final DartTypeReference item = type.typeArguments.single;
            return 'const <${typeCode(item, dependencies)}>[${value.indexed.map((v) => expression(item, v.$2, '$path/${v.$1}', dependencies)).join(',')}]';
          }
        case 'Map':
          if (value is Map<String, Object?>) {
            if (value.isEmpty) {
              return 'const {}';
            }
            final DartTypeReference item = type.typeArguments.last;
            return 'const <String, ${typeCode(item, dependencies)}>{${value.entries.map((e) => '${literal(e.key)}: ${expression(item, e.value, '$path/${e.key}', dependencies)}').join(',')}}';
          }
        case 'Object':
          return value is List || value is Map
              ? 'const ${literal(value)}'
              : literal(value);
      }
      fail(path, 'Cannot represent ${type.symbol} as a constant default.');
    }

    resolve = (field, path) {
      if (resolved[field] case final found?) {
        return found;
      }
      if (field.defaultValue case final value?) {
        if (!active.add(field)) {
          fail(path, 'Defaults form a constructor cycle.');
        }
        if (value.value == null && !field.acceptsNull) {
          fail(path, 'Null is not allowed.');
        }
        final dependencies = <String>{};
        final String code = expression(
          field.type,
          value.value,
          path,
          dependencies,
        );
        active.remove(field);
        return resolved[field] = DartFieldModel(
          name: field.name,
          type: field.type,
          isRequired: field.isRequired,
          wireName: field.wireName,
          acceptsNull: field.acceptsNull,
          usePresenceRecord: field.usePresenceRecord,
          discriminatorValues: field.discriminatorValues,
          defaultValue: value,
          defaultExpression: code,
          defaultDependencies: Set.unmodifiable(dependencies),
        );
      }
      return field;
    };
    for (var i = 0; i < dtos.length; i++) {
      final DartDtoModel dto = dtos[i];
      dtos[i] = DartDtoModel(
        name: dto.name,
        json: dto.json,
        extraValueType: dto.extraValueType,
        ignoredWireKeys: dto.ignoredWireKeys,
        fields: [
          for (final field in dto.fields)
            resolve(field, '${dto.name}/${field.wireName ?? field.name}'),
        ],
      );
    }
    return expression;
  }
}

bool _sameDefault(Object? a, Object? b) {
  if (a is List<Object?> && b is List<Object?>) {
    return a.length == b.length &&
        a.indexed.every((entry) => _sameDefault(entry.$2, b[entry.$1]));
  }
  if (a is Map<String, Object?> && b is Map<String, Object?>) {
    return a.length == b.length &&
        a.entries.every(
          (entry) =>
              b.containsKey(entry.key) &&
              _sameDefault(entry.value, b[entry.key]),
        );
  }
  return a == b;
}
