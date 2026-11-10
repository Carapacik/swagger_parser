part of 'dart_model_mapper.dart';

enum _MatcherMode() {
  branch,
  common,
  predicateOnly,
}

extension on _Mapping {
  void _structuralUnion(_SchemaUse id, String name) {
    if (id.oneOf.isNotEmpty && id.anyOf.isNotEmpty) {
      _fail(id, 'Use one union keyword per generated type.');
    }
    final bool exclusive = id.oneOf.isNotEmpty;
    final List<_SchemaUse> alternatives = exclusive ? id.oneOf : id.anyOf;
    final bool hasCommon = id.fields.keys.any(
      (key) =>
          key != 'oneOf' &&
          key != 'anyOf' &&
          !_annotations.contains(key) &&
          !key.startsWith('x-'),
    );
    final String? common = hasCommon ? _matcher(id, _MatcherMode.common) : null;
    final Set<String>? parentTypes = _conjunctiveTypes(id);
    final bool hasObjectFields =
        id.properties.isNotEmpty ||
        id.requiredProperties.isNotEmpty ||
        id.allOf.isNotEmpty ||
        id.fields.containsKey('additionalProperties');
    final branches = <DartMatchBranch>[];
    final labels = <String>{};
    final reused = <String>{};
    for (final branch in alternatives) {
      final String matcher = _matcher(branch);
      final _SchemaUse target = _concrete(branch);
      if (target == id) {
        _fail(
          branch,
          'A union cannot directly contain itself.',
          field: branch.raw.dynamicReference == null ? null : r'$dynamicRef',
        );
      }
      final _SchemaUse alternative = _schema(target);
      final Set<String>? types = _conjunctiveTypes(target);
      final String? simpleType =
          types?.where((t) => t != 'null' && t != 'integer').firstOrNull ??
          types?.firstOrNull;
      final String hint =
          _componentKey(branch.reference) ??
          _componentKey(target) ??
          _inlineBranchTitle(branch, target) ??
          simpleType ??
          (alternative.types.contains('null')
              ? 'Null'
              : 'Variant${branches.length + 1}');
      final String label = _identifier(hint, labels, type: true);
      final bool dto =
          _isDto(alternative) &&
          _scalarAllOfType(target) == null &&
          !_hasAlternatives(alternative) &&
          _cases(alternative) == null;
      final hintName = '$name$label';
      final bool objectContext =
          (parentTypes?.length == 1 && parentTypes!.contains('object')) ||
          (types?.length == 1 && types!.contains('object'));
      DartTypeReference type;
      var implementsUnion = false;
      if (_customType(target) case final mapped?) {
        if (hasObjectFields &&
            objectContext &&
            !_shape(target).matches(_shape(target, common: id))) {
          _fail(
            target,
            'Mapped union variants cannot add common object fields.',
          );
        }
        type = mapped;
      } else if (_cases(alternative) case final cases?
          when cases.isNotEmpty &&
              cases.every((value) => value == null) &&
              _nullable(target)) {
        type = DartTypeReference(symbol: 'Null');
      } else if ((hasObjectFields ||
              (types == null && alternative.requiredProperties.isNotEmpty)) &&
          objectContext &&
          !_hasAlternatives(alternative) &&
          _cases(alternative) == null &&
          (alternative.types.isEmpty || alternative.types.contains('object'))) {
        final _ObjectShape shape = _shape(target, common: id);
        if (dto && _shape(target).matches(shape)) {
          type = _type(target, hintName);
        } else {
          type = DartTypeReference(symbol: _typeIdentifier(hintName));
          _object(type.symbol, shape);
        }
        implementsUnion = !type.isNullable;
      } else if (!objectContext &&
          alternative.types.isEmpty &&
          (dto || alternative.fields.containsKey('additionalProperties'))) {
        // Object keywords alone also accept scalar JSON values.
        type = _any;
      } else {
        type = _type(target, exclusive && !dto ? '${hintName}Value' : hintName);
        implementsUnion = dto && !type.isNullable;
      }
      if (type.scalarCodec != null) {
        implementsUnion = false;
      }
      final String? implementation = !exclusive
          ? null
          : implementsUnion && reused.add(type.symbol)
          ? type.symbol
          : _typeIdentifier(hintName);
      branches.add(
        DartMatchBranch(label, matcher, type, implementation: implementation),
      );
    }
    structuralUnions.add(
      DartStructuralUnion(
        name,
        branches,
        exclusive: exclusive,
        commonMatcher: common,
        projectionMatcher:
            id.direction != null &&
                (!exclusive ||
                    config.unmatchedUnionValues == UnknownValueMode.preserve)
            ? _matcher(id)
            : null,
      ),
    );
  }

  String _matcher(_SchemaUse id, [_MatcherMode mode = _MatcherMode.branch]) {
    final key = (id, mode);
    if (matcherNames[key] case final name?) {
      return name;
    }
    final name = '_matches${matcherNames.length + 1}';
    matcherNames[key] = name;
    matcherSources[name] = id;
    matcherQueue.add((id, mode, name));
    if (!buildingMatchers) {
      buildingMatchers = true;
      try {
        // Linked schemas can be deep even when document nesting is shallow.
        for (var i = 0; i < matcherQueue.length; i++) {
          final (
            _SchemaUse source,
            _MatcherMode sourceMode,
            String sourceName,
          ) = matcherQueue[i];
          _buildMatcher(source, sourceMode, sourceName);
        }
      } finally {
        buildingMatchers = false;
        matcherQueue.clear();
      }
    }
    return name;
  }

  void _buildMatcher(_SchemaUse id, _MatcherMode mode, String name) {
    if (id.dialect case final dialect?
        when SchemaDialect.identify(dialect, id.family) ==
            SchemaDialect.unknown) {
      _fail(id, 'Unsupported schema dialect: $dialect.');
    }
    final _SchemaUse? ref = id.reference;
    final bool modern =
        id.family == OpenApiFamily.v31 || id.family == OpenApiFamily.v32;
    final Map<String, Object?> fields = ref != null && !modern
        ? const <String, Object?>{}
        : id.fields;
    final constraints = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in fields.entries) {
      if (modern && entry.key == 'prefixItems') {
        _checkPrefixItems(id);
        continue;
      }
      if (modern && entry.key == 'contains') {
        if (id.contains == null ||
            (entry.value is! bool && entry.value is! Map<String, Object?>)) {
          _failAtKeyword(id, entry.key, 'Expected a schema object or boolean.');
        }
        continue;
      }
      if (modern &&
          const {
            'minContains',
            'maxContains',
            'minItems',
            'maxItems',
          }.contains(entry.key)) {
        final Object? limit = entry.value;
        if (limit is! num ||
            !limit.isFinite ||
            limit < 0 ||
            limit != limit.toInt()) {
          _failAtKeyword(id, entry.key, 'Expected a nonnegative integer.');
        }
        constraints[entry.key] = limit.toInt();
      } else if (_literalChecks.contains(entry.key)) {
        constraints[entry.key] = entry.value;
      } else if (!_linkedOrAnnotation.contains(entry.key) &&
          !entry.key.startsWith('x-')) {
        _failAtKeyword(
          id,
          entry.key,
          'Structural matching does not support ${entry.key}.',
        );
      }
    }
    bool isJsonScalar(Object? value) =>
        value == null || value is String || value is num || value is bool;
    if (!isJsonScalar(constraints['const'])) {
      _failAtKeyword(id, 'const', 'Expected a scalar constant.');
    }
    if (constraints['enum'] case final List<Object?> values
        when !values.every(isJsonScalar)) {
      _failAtKeyword(id, 'enum', 'Expected scalar enum values.');
    }
    if (constraints['pattern'] case final String pattern) {
      try {
        RegExp(pattern, unicode: true);
      } on FormatException {
        _failAtKeyword(id, 'pattern', 'Invalid regular expression.');
      }
    }
    if (fields['additionalProperties'] == false) {
      constraints['additionalProperties'] = false;
    }
    final predicateOnly = mode == _MatcherMode.predicateOnly;
    String match(_SchemaUse child) =>
        _matcher(child, predicateOnly ? mode : _MatcherMode.branch);
    String matchValue(_SchemaUse child) {
      if (predicateOnly) {
        return match(child);
      }
      final _SchemaUse target = _concrete(child);
      if (!_hasAlternatives(target) &&
          _conjunctiveTypes(target) == null &&
          (_isDto(target) ||
              target.fields.containsKey('additionalProperties'))) {
        _fail(target, 'Set an explicit type for this nested structural value.');
      }
      return match(child);
    }

    final bool acceptsArray = id.types.isEmpty || id.types.contains('array');
    final bool acceptsObject = id.types.isEmpty || id.types.contains('object');
    matchers[name] = DartSchemaMatcher(
      name,
      types: id.types,
      constraints: constraints,
      ignoredWireKeys: id.excludedProperties,
      reject: id.definition.value == false,
      properties: {
        if (acceptsObject)
          for (final p in id.properties.entries) p.key: matchValue(p.value),
      },
      items: acceptsArray && id.items != null ? matchValue(id.items!) : null,
      prefixItems: acceptsArray ? id.prefixItems.map(matchValue) : const [],
      contains: acceptsArray && id.contains != null
          ? _matcher(id.contains!, _MatcherMode.predicateOnly)
          : null,
      additional:
          !acceptsObject ||
              id.additionalProperties == null ||
              fields['additionalProperties'] is bool
          ? null
          : matchValue(id.additionalProperties!),
      allOf: [if (ref != null) match(ref), ...id.allOf.map(match)],
      oneOf: mode == _MatcherMode.common ? [] : id.oneOf.map(match),
      anyOf: mode == _MatcherMode.common ? [] : id.anyOf.map(match),
    );
  }

  Never _failAtKeyword(_SchemaUse id, String key, String message) => _fail(
    id,
    message,
    field: key.replaceAll('~', '~0').replaceAll('/', '~1'),
  );

  void _checkMatcherCycles() {
    final checked = <String>{};
    final active = <String>{};
    void visit(String name) {
      if (checked.contains(name)) {
        return;
      }
      if (!active.add(name)) {
        _fail(
          matcherSources[name]!,
          'Recursive union matching must descend into a property or item.',
        );
      }
      final DartSchemaMatcher node = matchers[name]!;
      for (final String child in [
        ...node.allOf,
        ...node.oneOf,
        ...node.anyOf,
      ]) {
        visit(child);
      }
      active.remove(name);
      checked.add(name);
    }

    for (final String name in matchers.keys) {
      visit(name);
    }
  }
}

const _literalChecks = {
  'required',
  'enum',
  'const',
  'minimum',
  'maximum',
  'multipleOf',
  'exclusiveMinimum',
  'exclusiveMaximum',
  'minLength',
  'maxLength',
  'pattern',
  'minItems',
  'maxItems',
  'uniqueItems',
  'minProperties',
  'maxProperties',
};

const Set<String> _linkedOrAnnotation = {
  'type',
  'properties',
  'items',
  'additionalProperties',
  'allOf',
  'oneOf',
  'anyOf',
  r'$ref',
  r'$dynamicRef',
  ..._annotations,
};

const _annotations = {
  r'$id',
  r'$schema',
  r'$anchor',
  r'$dynamicAnchor',
  r'$defs',
  'definitions',
  r'$comment',
  'title',
  'description',
  'format',
  'default',
  'example',
  'examples',
  'deprecated',
  'readOnly',
  'writeOnly',
  'nullable',
  'discriminator',
  'externalDocs',
  'xml',
  'contentEncoding',
  'contentMediaType',
  'contentSchema',
};
