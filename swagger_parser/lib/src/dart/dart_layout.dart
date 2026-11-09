part of 'dart_model_mapper.dart';

extension on _Mapping {
  void _validateFacade() {
    if (!DartModelMapper.isValidFileSuffix(config.fileSuffix)) {
      throw GenerationException('Invalid file suffix: ${config.fileSuffix}.');
    }
    final String name = config.rootApiClassName;
    if (!DartModelMapper.isValidRootApiClassName(name)) {
      throw GenerationException('Invalid root client name: $name.');
    }
    if (!DartModelMapper.isValidRootApiClassName(config.fallbackClientName)) {
      throw GenerationException(
        'Invalid fallback client name: ${config.fallbackClientName}.',
      );
    }
  }

  List<DartLibraryModel> _layout(List<DartLibraryModel> clients) {
    final deps = <String, Set<String>>{};
    void types(String name, Iterable<DartTypeReference> refs) {
      final Set<String> symbols = deps.putIfAbsent(name, () => {});
      void add(DartTypeReference type) {
        symbols.add(type.symbol);
        type.typeArguments.forEach(add);
      }

      refs.forEach(add);
    }

    for (final DartDtoModel dto in dtos) {
      types(dto.name, [
        for (final f in dto.fields) f.type,
        for (final f in dto.fields)
          for (final name in {...f.defaultDependencies, ...f.fixedDependencies})
            DartTypeReference(symbol: name),
        ?dto.extraValueType,
      ]);
    }
    for (final DartValueModel value in values) {
      types(value.name, [value.type]);
    }
    for (final DartTupleModel tuple in tuples) {
      types(tuple.name, [...tuple.positions, ?tuple.restType]);
    }
    for (final DartEnumModel e in enums) {
      deps[e.name] = {};
    }
    for (final DartUnionModel union in unions) {
      deps[union.name] = {...union.mapping.values, ?union.defaultType};
    }
    for (final DartStructuralUnion union in structuralUnions) {
      types(union.name, union.branches.map((b) => b.type));
    }

    // Sealed variants must share a Dart library, including overlapping unions.
    final parent = <String, String>{};
    String family(String name) {
      final String? next = parent[name];
      return next == null ? name : parent[name] = family(next);
    }

    void join(String base, String variant) {
      if (family(base) != family(variant)) {
        parent[family(variant)] = family(base);
      }
    }

    for (final DartUnionModel union in unions) {
      for (final String name in deps[union.name]!) {
        join(union.name, name);
      }
    }
    for (final DartStructuralUnion union in structuralUnions) {
      for (final DartMatchBranch branch in union.branches) {
        if (branch.implementation == branch.type.symbol) {
          join(union.name, branch.type.symbol);
        }
      }
    }
    final groups = <String, Set<String>>{};
    for (final String name in deps.keys) {
      (groups[family(name)] ??= {}).add(name);
    }
    _pruneModelGroups(clients, deps, groups, family);
    final owners = <String, String>{};
    final visited = <_SchemaUse>{};
    void own(String name, String folder) {
      final String base = family(name);
      if (!groups.containsKey(base) || owners.containsKey(base)) {
        return;
      }
      owners[base] = folder;
      for (final String item in groups[base]!) {
        for (final String dep in deps[item]!) {
          own(dep, folder);
        }
      }
    }

    void visit(_SchemaUse id, String folder) {
      if (!visited.add(id)) {
        return;
      }
      if (names[id] case final name?) {
        own(name, folder);
      }
      for (final _SchemaUse next in [
        ?id.reference,
        ...id.properties.values,
        ?id.items,
        ...id.prefixItems,
        ?id.contains,
        ?id.additionalProperties,
        ...id.allOf,
        ...id.oneOf,
        ...id.anyOf,
      ]) {
        visit(next, folder);
      }
    }

    for (final ApiOperation op in selectedOperations) {
      final String? folder = clientFolders[op.tags.firstOrNull?.trim() ?? ''];
      if (folder == null) {
        continue;
      }
      final List<ApiMediaType> media = [
        for (final p in [...op.parameters, ...?op.requestBody?.formFields])
          ...p.content.values,
        ...?op.requestBody?.content.values,
        for (final response in op.responses.values) ...response.content.values,
      ];
      for (final ReferenceLocation id in [
        for (final p in [...op.parameters, ...?op.requestBody?.formFields])
          ?p.schema,
        for (final item in media) ...[?item.schema, ?item.itemSchema],
      ]) {
        for (final _Direction direction in _Direction.values) {
          visit(index.use(id, const {}, direction), folder);
        }
      }
    }
    final paths = <String, String>{};
    final usedPaths = <String>{};
    for (final MapEntry<String, Set<String>> group in groups.entries) {
      final String? folder = owners[group.key];
      final stem =
          '${folder == null ? '' : '$folder/'}models/${_clientSnakeCase(group.key)}';
      String path = _fileName(stem);
      for (var n = 2; !usedPaths.add(path); n++) {
        path = _fileName('$stem$n');
      }
      for (final String name in group.value) {
        paths[name] = path;
      }
    }
    final Set<String> objectNames = {
      for (final dto in dtos) dto.name,
      for (final u in unions) u.name,
    };
    final Set<String> wrapperNames = {
      for (final v in values) v.name,
      for (final t in tuples) t.name,
      for (final u in structuralUnions) u.name,
    };
    final Map<String, DartDtoModel> dtoByName = {
      for (final d in dtos) d.name: d,
    };
    final Map<String, DartEnumModel> enumByName = {
      for (final e in enums) e.name: e,
    };
    final Map<String, DartValueModel> valueByName = {
      for (final v in values) v.name: v,
    };
    final Map<String, DartUnionModel> unionByName = {
      for (final u in unions) u.name: u,
    };
    final Map<String, DartStructuralUnion> structuralByName = {
      for (final u in structuralUnions) u.name: u,
    };
    final Map<String, DartTupleModel> tupleByName = {
      for (final t in tuples) t.name: t,
    };
    final libraries = <DartLibraryModel>[];
    final String errorName = config.generateValidators
        ? _identifier('DtoValidationError', usedNames, type: true)
        : 'DtoValidationError';
    final Set<String> reservedPaths = {
      'exports.dart',
      '${_clientSnakeCase(config.rootApiClassName)}.dart',
      ...paths.values,
      ...clients.map((client) => client.relativePath),
    };
    String errorPath = _fileName('dto_validation_error');
    for (var n = 2; reservedPaths.contains(errorPath); n++) {
      errorPath = _fileName('dto_validation_error$n');
    }
    final sources = <String, _SchemaUse>{
      for (final entry in names.entries) entry.value: entry.key,
    };
    if (config.generateValidators && groups.isNotEmpty) {
      libraries.add(
        DartLibraryModel(
          relativePath: errorPath,
          dtos: const [],
          validationErrors: true,
          validationErrorName: errorName,
        ),
      );
    }
    for (final MapEntry<String, Set<String>> group in groups.entries) {
      final Set<String> members = group.value;
      final String path = paths[group.key]!;
      final List<DartTupleModel> localTuples = [
        for (final name in members) ?tupleByName[name],
      ];
      final List<DartStructuralUnion> localUnions = [
        for (final name in members) ?structuralByName[name],
      ];
      final imported = <String>{
        for (final name in members)
          for (final ref in deps[name]!)
            if (paths[ref] case final target? when target != path)
              p.posix.relative(target, from: p.posix.dirname(path)),
      };
      final validators = <String, String>{
        if (config.generateValidators)
          for (final name in members)
            if (sources[name] case final source?)
              name: _matcher(source, _MatcherMode.predicateOnly),
      };
      libraries.add(
        DartLibraryModel(
          relativePath: path,
          documentation: {
            for (final name in members)
              if (sources[name] case final source?)
                name: _schemaDocumentation(source),
          },
          fieldDocumentation: {
            for (final name in members) name: ?fieldDocumentation[name],
          },
          validators: validators,
          validatorExtensions: {
            for (final name in validators.keys)
              name: _identifier(
                '${name}Validation',
                usedNames,
                type: true,
                preserveCase: true,
              ),
          },
          validationErrorName: errorName,
          validationErrorImport: validators.isEmpty
              ? null
              : p.posix.relative(errorPath, from: p.posix.dirname(path)),
          imports: imported.toList()..sort(),
          constantImports: {
            for (final entry in mappingPrefixes.entries)
              if (members.any(
                (name) => deps[name]!.any(
                  (symbol) => symbol.startsWith('${entry.value}.'),
                ),
              ))
                entry.key: entry.value,
          },
          objectNames: objectNames,
          wrapperNames: wrapperNames,
          matchIntegers: tuples.isNotEmpty || structuralUnions.isNotEmpty,
          dtos: [for (final name in members) ?dtoByName[name]],
          enums: [for (final name in members) ?enumByName[name]],
          values: [for (final name in members) ?valueByName[name]],
          unions: [for (final name in members) ?unionByName[name]],
          structuralUnions: localUnions,
          tuples: localTuples,
          matchers: _reachableMatchers([
            ...validators.values,
            for (final t in localTuples) t.matcher,
            for (final u in localUnions) ...[
              ?u.commonMatcher,
              ?u.projectionMatcher,
              for (final b in u.branches) b.matcher,
            ],
          ]),
        ),
      );
    }
    final generateMetadata = config.apiMetadata != ApiMetadataMode.none;
    final String metadataType = generateMetadata
        ? _identifier('OperationMetadata', usedNames, type: true)
        : 'OperationMetadata';
    final Set<String> metadataPaths = {
      'exports.dart',
      '${_clientSnakeCase(config.rootApiClassName)}.dart',
      ...libraries.map((library) => library.relativePath),
      ...clients.map((library) => library.relativePath),
    };
    String metadataPath(String stem) {
      String path = _fileName(stem);
      for (var n = 2; !metadataPaths.add(path); n++) {
        path = _fileName('$stem$n');
      }
      return path;
    }

    final String metadataTypePath = metadataPath('api_metadata');
    final metadataNames = <String>[];
    final operationConstants = <(String, String), String>{};
    if (generateMetadata) {
      libraries.add(
        DartLibraryModel(
          relativePath: metadataTypePath,
          dtos: const [],
          apiMetadata: true,
          metadataTypeName: metadataType,
        ),
      );
    }
    final String decoderPath = metadataPath('_response_decoder');
    final String nativeDecoderPath = metadataPath('_response_decoder_native');
    final String webDecoderPath = metadataPath('_response_decoder_web');
    if (config.decodeResponsesInBackground && clients.isNotEmpty) {
      for (final MapEntry<String, String> entry in {
        'entry': decoderPath,
        'native': nativeDecoderPath,
        'web': webDecoderPath,
      }.entries) {
        libraries.add(
          DartLibraryModel(
            relativePath: entry.value,
            dtos: const [],
            responseDecoder: entry.key,
            responseDecoderImports: [webDecoderPath, nativeDecoderPath],
          ),
        );
      }
    }
    final fields = <String, String>{};
    final Set<String> usedFields = {
      ..._memberNames,
      'apiVersion',
      'title',
      'specVersion',
      'operations',
      'baseUrl',
      'prepareRequest',
      'clients',
      'transport',
      config.rootApiClassName,
    };
    for (final client in clients) {
      String? companionName;
      String? companionPath;
      if (client.operations.isNotEmpty) {
        if (generateMetadata) {
          companionName = _identifier(
            '${client.clientName}Metadata',
            usedNames,
            type: true,
            preserveCase: true,
          );
          companionPath = metadataPath(
            '${client.relativePath.substring(0, client.relativePath.lastIndexOf('/'))}/${_clientSnakeCase(client.clientName)}_metadata',
          );
          metadataNames.add(companionName);
          for (final DartClientOperation op in client.operations) {
            operationConstants[(op.method, op.path)] =
                '$companionName.${op.name}';
          }
          libraries.add(
            DartLibraryModel(
              relativePath: companionPath,
              dtos: const [],
              metadataTypeName: metadataType,
              metadataTypePath: metadataTypePath,
              clientMetadataName: companionName,
              metadataOperations: client.operations,
            ),
          );
        }
        final String base = client.clientName.replaceFirst(
          RegExp(r'Client(?=\d*$)'),
          '',
        );
        fields[_identifier(base, usedFields)] = client.clientName;
      }
      libraries.add(
        DartLibraryModel(
          relativePath: client.relativePath,
          metadataTypeName: metadataType,
          metadataTypePath: metadataTypePath,
          clientMetadataName: companionName,
          clientMetadataPath: companionPath,
          attachOperationMetadata:
              config.apiMetadata == ApiMetadataMode.generateAndAttach,
          dtos: const [],
          modelPaths: paths,
          httpRequestOptionsPath: _fileName('http_request_options'),
          httpResponsePath: _fileName('http_response'),
          responseDecoderPath: decoderPath,
          results: client.results,
          clientName: client.clientName,
          operations: client.operations,
          constantImports: {
            for (final entry in mappingPrefixes.entries)
              if (client.operations.any(
                (op) => [
                  for (final p in op.parameters)
                    ...?p.defaultValue?.dependencies,
                  for (final f in op.body?.fields ?? <DartFormField>[])
                    ...?f.defaultValue?.dependencies,
                ].any((symbol) => symbol.startsWith('${entry.value}.')),
              ))
                entry.key: entry.value,
          },
          resultFile: client.resultFile,
        ),
      );
    }
    if (config.httpClient == HttpClientBackend.http && fields.isNotEmpty) {
      libraries.add(
        DartLibraryModel(
          relativePath: _fileName('http_request_options'),
          dtos: const [],
          httpRequestOptions: true,
        ),
      );
    }
    if (config.originalHttpResponse &&
        config.responseMode == ResponseMode.firstSuccess &&
        fields.isNotEmpty) {
      if (config.httpClient == HttpClientBackend.http) {
        libraries.add(
          DartLibraryModel(
            relativePath: _fileName('http_response'),
            dtos: const [],
            httpResponse: true,
          ),
        );
      } else {
        final uri = config.httpClient == HttpClientBackend.dio
            ? 'package:dio/dio.dart'
            : 'package:retrofit/retrofit.dart';
        final name = config.httpClient == HttpClientBackend.dio
            ? 'Response'
            : 'HttpResponse';
        typeExports[uri] = {...?typeExports[uri], name}.toList();
      }
    }
    final List<String> exports =
        libraries
            .where((l) => l.responseDecoder == null)
            .map((l) => l.relativePath)
            .toList()
          ..sort();
    return [
      ...libraries,
      DartLibraryModel(
        relativePath: 'exports.dart',
        typeExports: typeExports,
        dtos: const [],
        exports: exports,
      ),
      DartLibraryModel(
        relativePath: '${_clientSnakeCase(config.rootApiClassName)}.dart',
        dtos: const [],
        exports: const ['exports.dart'],
        facade: DartFacadeModel(
          config.rootApiClassName,
          api.apiVersion,
          fields,
          title: api.title,
          specVersion: api.specVersion.value,
          metadataTypeName: generateMetadata ? metadataType : null,
          metadataNames: metadataNames,
          operationConstants: [
            for (final op in selectedOperations)
              ?operationConstants[(op.method, op.path)],
          ],
          clientPaths: {
            for (final client in clients)
              if (client.operations.isNotEmpty)
                client.clientName: client.relativePath,
          },
        ),
      ),
    ];
  }

  Iterable<DartSchemaMatcher> _reachableMatchers(Iterable<String> roots) {
    final seen = <String>{};
    void visit(String name) {
      if (!seen.add(name)) {
        return;
      }
      final DartSchemaMatcher rule = matchers[name]!;
      for (final String child in [
        ...rule.properties.values,
        ?rule.items,
        ...rule.prefixItems,
        ?rule.contains,
        ?rule.additional,
        ...rule.allOf,
        ...rule.oneOf,
        ...rule.anyOf,
      ]) {
        visit(child);
      }
    }

    roots.forEach(visit);
    return seen.map((name) => matchers[name]!);
  }
}
