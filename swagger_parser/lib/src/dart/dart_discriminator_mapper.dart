part of 'dart_model_mapper.dart';

extension on _Mapping {
  void _collectDiscriminators(String name, _SchemaUse id) {
    final seen = <_SchemaUse>{};
    void collect(_SchemaUse schema) {
      if (!seen.add(schema)) {
        return;
      }
      if (schema.reference case final target?) {
        collect(target);
      } else {
        final Object? discriminator = schema.fields['discriminator'];
        final String? key = switch (discriminator) {
          final String key when schema.family == OpenApiFamily.swaggerV2 => key,
          {'propertyName': final String key} => key,
          _ => null,
        };
        if (key != null) {
          (fixedDiscriminators[name] ??= {}).add(key);
        }
      }
      schema.allOf.forEach(collect);
    }

    collect(id);
  }

  void _applyFixedDiscriminators() {
    final Map<String, DartEnumModel> enumTypes = {
      for (final value in enums) value.name: value,
    };
    final Map<String, DartValueModel> wrappers = {
      for (final value in values) value.name: value,
    };
    (JsonValue, String, Set<String>)? constant(
      DartTypeReference type,
      Set<String> seen,
    ) {
      if (type.isNullable || !seen.add(type.symbol)) {
        return null;
      }
      if (type.scalarCodec case final codec?
          when codec.allowedValues.length == 1) {
        final Object value = codec.allowedValues.single;
        return (
          JsonValue(value),
          '${codec.adapter}.read(${jsonEncode(value).replaceAll(r'$', r'\$')})',
          <String>{},
        );
      }
      if (enumTypes[type.symbol] case final model?
          when model.values.length == 1) {
        final MapEntry<String, Object> entry = model.values.entries.single;
        return (
          JsonValue(entry.value),
          '${model.name}.${entry.key}',
          {model.name},
        );
      }
      if (wrappers[type.symbol] case final model?) {
        final (JsonValue, String, Set<String>)? inner = constant(
          model.type,
          seen,
        );
        if (inner != null) {
          return (
            inner.$1,
            'const ${model.name}(${inner.$2})',
            {...inner.$3, model.name},
          );
        }
      }
      return null;
    }

    List<Object> allowed(DartTypeReference type, [Set<String>? seen]) {
      if (!(seen ??= {}).add(type.symbol)) {
        return const [];
      }
      if (type.scalarCodec case final codec?) {
        return codec.allowedValues;
      }
      if (enumTypes[type.symbol] case final model?) {
        return model.values.values.toList();
      }
      if (wrappers[type.symbol] case final model?) {
        return allowed(model.type, seen);
      }
      return const [];
    }

    DartFieldModel mark(DartFieldModel field) {
      final List<Object> values = allowed(field.type);
      final (JsonValue, String, Set<String>)? fixed =
          field.isRequired && !field.acceptsNull
          ? constant(field.type, {})
          : null;
      return DartFieldModel(
        name: field.name,
        wireName: field.wireName,
        type: field.type,
        isRequired: field.isRequired,
        acceptsNull: field.acceptsNull,
        usePresenceRecord: field.usePresenceRecord,
        defaultValue: field.defaultValue,
        defaultExpression: field.defaultExpression,
        defaultDependencies: field.defaultDependencies,
        discriminatorValues: List.unmodifiable(values),
        fixedValue: fixed?.$1,
        fixedExpression: fixed?.$2,
        fixedDependencies: Set.unmodifiable(fixed?.$3 ?? const <String>{}),
      );
    }

    for (var i = 0; i < dtos.length; i++) {
      final DartDtoModel dto = dtos[i];
      final Set<String>? keys = fixedDiscriminators[dto.name];
      if (keys == null) {
        continue;
      }
      dtos[i] = DartDtoModel(
        name: dto.name,
        json: dto.json,
        extraValueType: dto.extraValueType,
        ignoredWireKeys: dto.ignoredWireKeys,
        fields: [
          for (final DartFieldModel field in dto.fields)
            if (keys.contains(field.wireName ?? field.name))
              mark(field)
            else
              field,
        ],
      );
    }
  }
}
