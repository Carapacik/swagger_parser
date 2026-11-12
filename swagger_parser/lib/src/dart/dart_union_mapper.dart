part of 'dart_model_mapper.dart';

extension on _Mapping {
  String? _inlineBranchTitle(_SchemaUse branch, _SchemaUse target) {
    if (_componentKey(branch.reference) != null ||
        _componentKey(target) != null) {
      return null;
    }
    final bool legacyRef =
        branch.reference != null &&
        (branch.family == OpenApiFamily.swaggerV2 ||
            branch.family == OpenApiFamily.v30);
    for (final Object? title in [
      if (!legacyRef) branch.fields['title'],
      if (branch != target) target.fields['title'],
    ]) {
      if (title is String && _word.hasMatch(title)) {
        return title.trim();
      }
    }
    return null;
  }

  bool _swaggerUnion(_SchemaUse id, String name) {
    if (id.family != OpenApiFamily.swaggerV2 ||
        id.fields['discriminator'] is! String ||
        _componentKey(id) == null) {
      return false;
    }
    final key = id.fields['discriminator']! as String;
    if (id.excludedProperties.contains(key)) {
      return false;
    }
    bool inherits(_SchemaUse child, Set<_SchemaUse> seen) {
      if (child.location == id.location) {
        return true;
      }
      if (!seen.add(child)) {
        return false;
      }
      return [
        ?child.reference,
        ...child.allOf,
      ].any((part) => inherits(part, seen));
    }

    final mapping = <String, String>{};
    for (final MapEntry<String, ReferenceLocation> entry
        in api.namedSchemas.entries) {
      final _SchemaUse child = index.use(
        entry.value,
        id.bindings,
        id.direction,
      );
      if (child == id ||
          child.family != OpenApiFamily.swaggerV2 ||
          child.allOf.isEmpty ||
          !inherits(child, {})) {
        continue;
      }
      final String variant = _name(child, entry.key);
      final DartTypeReference? mapped = _customType(child);
      _declare(child);
      final String concrete;
      if (mapped != null) {
        concrete = _typeIdentifier('${name}_${entry.key}');
        values.add(DartValueModel(concrete, _taggedMappedType(mapped)));
      } else {
        concrete = swaggerConcrete[child] ?? variant;
      }
      mapping[entry.key] = concrete;
      (fixedDiscriminators[concrete] ??= {}).add(key);
    }
    if (mapping.isEmpty) {
      return false;
    }
    final String concrete = _identifier(
      '${name}Value',
      usedNames,
      type: true,
      suffixes: _typeSuffixes,
    );
    swaggerConcrete[id] = concrete;
    _object(concrete, _shape(id));
    _collectDiscriminators(concrete, id);
    unions.add(
      DartUnionModel(name, key, {_componentKey(id)!: concrete, ...mapping}),
    );
    return true;
  }

  bool _usesDiscriminator(_SchemaUse id) {
    final String? key = id.raw.discriminator?.propertyName;
    if (key == null || id.excludedProperties.contains(key)) {
      return false;
    }
    return ![
      ...id.oneOf,
      ...id.anyOf,
    ].any((branch) => _shape(_concrete(branch)).ignored.contains(key));
  }

  void _union(_SchemaUse id, String name) {
    if (id.oneOf.isNotEmpty && id.anyOf.isNotEmpty) {
      _fail(id, 'Use one tagged composition per id.');
    }
    final ApiDiscriminator discriminator = id.raw.discriminator!;
    final List<_SchemaUse> branches = id.oneOf.isNotEmpty ? id.oneOf : id.anyOf;
    final variants = <_SchemaUse, String>{};
    final implicit = <String, _SchemaUse>{};
    for (final branch in branches) {
      final _SchemaUse target = _concrete(branch);
      if (target == id ||
          (id.oneOf.isNotEmpty && variants.containsKey(target))) {
        _fail(branch, 'Expected a distinct object variant.');
      }
      final _SchemaUse alternative = _schema(target);
      if ((!_isDto(alternative) && !alternative.types.contains('object')) ||
          _hasAlternatives(alternative)) {
        _fail(branch, 'Expected an object or object allOf variant.');
      }
      final _SchemaUse? direct = branch.reference;
      if (_componentKey(direct) case final tag?) {
        if (!discriminator.mapping.containsKey(tag)) {
          if (implicit.containsKey(tag) && implicit[tag] != target) {
            _fail(branch, 'Ambiguous discriminator value: $tag.');
          }
          implicit[tag] = target;
        }
      }
      if (variants.containsKey(target)) {
        continue;
      }
      final _ObjectShape standalone = _shape(target);
      final _ObjectShape combined = _shape(target, common: id);
      final String? title = _inlineBranchTitle(branch, target);
      final hint = '$name${title ?? 'Variant${variants.length + 1}'}';
      if (_customType(target) case final mapped?) {
        if (!standalone.matches(combined)) {
          _fail(
            target,
            'Mapped union variants cannot add common object fields.',
          );
        }
        final String wrapper = _typeIdentifier(
          '${name}_${_componentKey(target) ?? hint}',
        );
        values.add(DartValueModel(wrapper, _taggedMappedType(mapped)));
        variants[target] = wrapper;
      } else if (_isDto(alternative) && standalone.matches(combined)) {
        final String baseName = _name(target, hint);
        _declare(target);
        variants[target] = baseName;
      } else {
        final String variantName = _typeIdentifier(
          title == null ? '${name}_${_name(target, hint)}' : hint,
        );
        _object(variantName, combined);
        variants[target] = variantName;
      }
    }

    String typeFor(_SchemaUse location, String field) {
      final String? type = variants[_concrete(location)];
      if (type == null) {
        _fail(
          id,
          'The discriminator target must be a listed variant.',
          field: 'discriminator/$field',
        );
      }
      return type;
    }

    final Map<String, String> mapping = {
      for (final entry in implicit.entries) entry.key: variants[entry.value]!,
      for (final entry in discriminator.mapping.entries)
        entry.key: typeFor(
          id.child(entry.value),
          'mapping/${entry.key.replaceAll('~', '~0').replaceAll('/', '~1')}',
        ),
    };
    final ReferenceLocation? fallback = discriminator.defaultMapping;
    final String? defaultType = fallback == null
        ? null
        : typeFor(id.child(fallback), 'defaultMapping');
    if (!{...mapping.values, ?defaultType}.containsAll(variants.values)) {
      _fail(id, 'Give each variant a discriminator mapping.');
    }
    for (final String variant in variants.values) {
      (fixedDiscriminators[variant] ??= {}).add(discriminator.propertyName);
    }
    unions.add(
      DartUnionModel(
        name,
        discriminator.propertyName,
        mapping,
        defaultType: defaultType,
      ),
    );
  }
}

// Tagged unions always decode JSON objects, even when a branch permits null.
DartTypeReference _taggedMappedType(DartTypeReference type) =>
    DartTypeReference(
      symbol: type.symbol,
      importUrl: type.importUrl,
      scalarCodec: type.scalarCodec,
      typeArguments: type.typeArguments,
      isMetadataEnum: type.isMetadataEnum,
    );
