part of 'dart_model_mapper.dart';

extension on _Mapping {
  void _prepareTypeMappings() {
    final selectors = <String>{};
    late final selectorIndex = _SchemaIndex(api.schemas, api.dynamicAnchors);
    final exports = <String, String>{};
    final identifier = RegExp(r'^[A-Za-z][A-Za-z0-9_$]*$');
    bool importUri(String value) {
      final Uri? uri = Uri.tryParse(value);
      return uri != null &&
          {'package', 'dart'}.contains(uri.scheme) &&
          uri.path.isNotEmpty &&
          !uri.hasQuery &&
          !uri.hasFragment &&
          !value.contains(RegExp(r'[\s\x27\x22\\]'));
    }

    for (final TypeMapping rule in config.typeMappings) {
      if (!identifier.hasMatch(rule.dartType) ||
          _memberNames.contains(rule.dartType) ||
          _typeOnlyNames.contains(rule.dartType) ||
          rule.dartType == config.rootApiClassName ||
          !identifier.hasMatch(rule.codec.fromJson) ||
          _memberNames.contains(rule.codec.fromJson) &&
              rule.codec.fromJson != 'fromJson' ||
          !identifier.hasMatch(rule.codec.toJson) ||
          _memberNames.contains(rule.codec.toJson) &&
              rule.codec.toJson != 'toJson' ||
          !importUri(rule.importUrl) ||
          !importUri(rule.codec.importUrl)) {
        throw GenerationException('Invalid type mapping symbol or import.');
      }
      final String key;
      if (rule.schema case final selector?) {
        if (rule.type != null || rule.format != null || selector.isEmpty) {
          throw GenerationException('Select a schema or a type/format pair.');
        }
        final Uri? parsed = Uri.tryParse(selector);
        if (parsed == null ||
            !parsed.hasFragment ||
            !parsed.fragment.startsWith('/')) {
          throw GenerationException(
            'Expected a schema URI with a JSON Pointer: $selector.',
          );
        }
        final Uri resolved = api.sourceUri?.resolveUri(parsed) ?? parsed;
        final Uri? document =
            parsed.removeFragment().toString().isEmpty && api.sourceUri == null
            ? null
            : resolved.removeFragment();
        final ReferenceLocation location = (
          documentUri: document,
          pointer: resolved.fragment,
        );
        if (!api.schemas.containsKey(location)) {
          throw GenerationException('Unknown type mapping schema: $selector.');
        }
        mappingSelectors[rule] = location;
        key = 'schema:$document#${resolved.fragment}';
      } else {
        if (!_dartScalars.containsKey(rule.type) ||
            rule.format == null ||
            rule.format!.isEmpty) {
          throw GenerationException(
            'Expected a scalar type and a non-empty format.',
          );
        }
        key = 'format:${rule.type}:${rule.format}';
      }
      if (!selectors.add('$key:${rule.direction.name}')) {
        throw GenerationException('Conflicting type mappings: $key.');
      }
      if (rule.direction != TypeMappingDirection.both) {
        if (mappingSelectors[rule] case final location?) {
          index.mappedDirections.add(location);
        } else {
          index.mappedDirections.addAll([
            for (final location in api.schemas.keys)
              if (_matchesFormat(rule, selectorIndex.use(location))) location,
          ]);
        }
      }
      final String? previous = exports[rule.dartType];
      if (previous != null && previous != rule.importUrl) {
        throw GenerationException('Conflicting public type: ${rule.dartType}.');
      }
      exports[rule.dartType] = rule.importUrl;
      usedNames.add(rule.dartType);
      final defaults = <Object?>[];
      for (final TypeMappingDefault entry in rule.defaults) {
        if (!identifier.hasMatch(entry.constant) ||
            _memberNames.contains(entry.constant) ||
            !importUri(entry.importUrl)) {
          throw GenerationException('Invalid type mapping constant or import.');
        }
        if (!_isMappingJson(entry.value)) {
          throw GenerationException('Expected a finite JSON mapping default.');
        }
        if (defaults.any((value) => _sameDefault(value, entry.value))) {
          throw GenerationException('Duplicate type mapping default.');
        }
        defaults.add(entry.value);
      }
      for (final String uri in {
        rule.importUrl,
        rule.codec.importUrl,
        for (final entry in rule.defaults) entry.importUrl,
      }) {
        mappingPrefixes.putIfAbsent(
          uri,
          () => _identifier('mapped${mappingPrefixes.length + 1}', usedNames),
        );
      }
    }
  }

  Set<_SchemaUse> _mappingAncestors(_SchemaUse id) {
    final result = <_SchemaUse>{};
    void visit(_SchemaUse schema) {
      if (result.add(schema)) {
        if (schema.reference case final target?) {
          visit(target);
        }
        schema.allOf.forEach(visit);
      }
    }

    visit(id);
    return result;
  }

  bool _matchesFormat(TypeMapping rule, _SchemaUse id) {
    final Set<String> types = {...?_conjunctiveTypes(id)}..remove('null');
    if (types.contains('number')) {
      types.remove('integer');
    }
    return types.length == 1 &&
        types.single == rule.type &&
        _mappingAncestors(id)
            .any((schema) => schema.fields['format'] == rule.format);
  }

  bool _matchesDirection(TypeMapping rule, _SchemaUse id) =>
      rule.direction == TypeMappingDirection.both ||
      rule.direction.name == id.direction?.name;

  bool _mappedSwaggerUnion(_SchemaUse id) {
    if (id.family != OpenApiFamily.swaggerV2) {
      return false;
    }
    final _SchemaUse target = _concrete(id);
    if (target.fields['discriminator'] is! String) {
      return false;
    }
    bool inherits(_SchemaUse child, Set<_SchemaUse> seen) {
      if (!seen.add(child)) {
        return false;
      }
      return child.location == target.location ||
          [
            ?child.reference,
            ...child.allOf,
          ].any((part) => inherits(part, seen));
    }

    return api.namedSchemas.values.any(
      (location) =>
          location != target.location &&
          index.use(location).allOf.isNotEmpty &&
          inherits(index.use(location), {}),
    );
  }

  DartParameterObjectShape? _mappedParameterShape(_SchemaUse id) {
    final _ObjectShape shape = _shape(id);
    DartParameterObjectShape result = shape.closed
        ? DartParameterObjectShape.flat
        : DartParameterObjectShape.open;
    if (shape.extra != null) {
      result = DartParameterObjectShape.flat;
    }
    for (final _SchemaUse child in [...shape.properties.values, ?shape.extra]) {
      final Set<String>? types = _conjunctiveTypes(child);
      if (types == null || types.isEmpty) {
        result = DartParameterObjectShape.open;
      } else if (types.any(
        (t) => t != 'null' && !_dartScalars.containsKey(t),
      )) {
        return null;
      }
    }
    return result;
  }

  DartTypeReference? _customType(
    _SchemaUse id,
  ) => customTypes.putIfAbsent(id, () {
    if (config.typeMappings.isEmpty) {
      return null;
    }
    final Set<_SchemaUse> ancestors = _mappingAncestors(id);
    final Set<String> types = {...?_conjunctiveTypes(id)}..remove('null');
    if (types.contains('number')) {
      types.remove('integer');
    }
    final Set<String> formats = {
      for (final schema in ancestors)
        if (schema.fields['format'] case final String format) format,
    };
    final referenceChain = <_SchemaUse>{};
    var current = id;
    while (referenceChain.add(current) && current.reference != null) {
      current = current.reference!;
    }
    final List<TypeMapping> exact = [
      for (final rule in config.typeMappings.where(
        (rule) => _matchesDirection(rule, id),
      ))
        if (mappingSelectors[rule] case final location?
            when ancestors.any((s) => s.location == location) &&
                (referenceChain.any((s) => s.location == location) ||
                    !(_conjunctiveTypes(index.use(location))
                            ?.contains('object') ??
                        _hasObjectShape(index.use(location)))))
          rule,
    ];
    final List<TypeMapping> candidates = exact.isNotEmpty
        ? exact
        : [
            for (final rule in config.typeMappings)
              if (_matchesDirection(rule, id) &&
                  rule.schema == null &&
                  types.length == 1 &&
                  types.single == rule.type &&
                  formats.contains(rule.format))
                rule,
          ];
    final List<TypeMapping> matches = [
      for (final rule in candidates)
        if (rule.direction != TypeMappingDirection.both ||
            !candidates.any(
              (other) =>
                  other.direction != TypeMappingDirection.both &&
                  mappingSelectors[other] == mappingSelectors[rule] &&
                  other.type == rule.type &&
                  other.format == rule.format,
            ))
          rule,
    ];
    if (matches.isEmpty) {
      return null;
    }
    if (matches.length != 1) {
      _fail(id, 'Conflicting type mappings.');
    }
    final TypeMapping rule = matches.single;
    final bool object =
        types.length == 1 && types.single == 'object' ||
        _conjunctiveTypes(id) == null && ancestors.any(_hasObjectShape);
    if (!(object && rule.schema != null ||
            types.length == 1 && _dartScalars.containsKey(types.single)) ||
        ancestors.any(
          (s) =>
              _hasAlternatives(s) ||
              s.items != null ||
              !object && s.properties.isNotEmpty,
        )) {
      _fail(id, 'Type mappings require a scalar or object schema.');
    }
    if (object) {
      if (_mappedSwaggerUnion(id)) {
        _fail(id, 'Type mappings cannot replace a polymorphic union.');
      }
      if (rule.direction == TypeMappingDirection.both &&
          index.hasDirectionalShape(id)) {
        _fail(
          id,
          'Object type mappings require identical request and response shapes.',
        );
      }
    }
    final String matcher = _matcher(id);
    final allowed = <Object>[];
    for (final ancestor in ancestors) {
      if (_cases(ancestor) case final values?) {
        final List<Object> concrete = values.nonNulls.toList();
        if (allowed.isEmpty) {
          allowed.addAll(concrete);
        } else {
          allowed.removeWhere((v) => !concrete.contains(v));
        }
      }
    }
    final codec = DartScalarCodec(
      dartType: rule.dartType,
      wireType: object ? 'Map<String, Object?>' : _dartScalars[types.single]!,
      typeImport: rule.importUrl,
      typePrefix: mappingPrefixes[rule.importUrl]!,
      codecImport: rule.codec.importUrl,
      codecPrefix: mappingPrefixes[rule.codec.importUrl]!,
      fromJson: rule.codec.fromJson,
      toJson: rule.codec.toJson,
      adapter: '_Scalar${customTypes.length + 1}',
      matcher: matcher,
      matchers: _reachableMatchers([matcher]).toList(),
      allowedValues: allowed,
      parameterObjectShape: object ? _mappedParameterShape(id) : null,
      defaults: [
        for (final entry in rule.defaults)
          DartMappedDefault(
            JsonValue(entry.value),
            '${mappingPrefixes[entry.importUrl]}.${entry.constant}',
          ),
      ],
    );
    final List<String> exported = typeExports.putIfAbsent(
      rule.importUrl,
      () => [],
    );
    if (!exported.contains(rule.dartType)) {
      exported.add(rule.dartType);
    }
    return DartTypeReference(
      symbol: '${codec.typePrefix}.${rule.dartType}',
      scalarCodec: codec,
      isNullable: _nullable(id),
    );
  });
}

bool _isMappingJson(Object? value) => switch (value) {
  null || String() || bool() || int() => true,
  double() => value.isFinite,
  List<Object?>() => value.every(_isMappingJson),
  Map<String, Object?>() => value.values.every(_isMappingJson),
  _ => false,
};
