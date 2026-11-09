part of 'mustache_source_renderer.dart';

String _kind(DartLibraryModel model) {
  if (model.httpRequestOptions ||
      model.httpResponse ||
      model.responseDecoder != null ||
      model.validationErrors ||
      model.apiMetadata ||
      model.metadataOperations.isNotEmpty) {
    return 'support';
  }
  if (model.facade != null) {
    return 'api';
  }
  if (model.relativePath == 'exports.dart') {
    return 'exports';
  }
  if (model.operations.isNotEmpty) {
    return 'client';
  }
  if (model.results.isNotEmpty) {
    return 'results';
  }
  return 'models';
}

Map<String, Object?> _context(
  DartLibraryModel m,
  String kind,
  GenerationConfig config,
  String source,
) => {
  'contractVersion': 1,
  'relativePath': m.relativePath,
  'kind': kind,
  'defaultSource': source,
  'options': {
    'rootApiClassName': config.rootApiClassName,
    'fallbackClientName': config.fallbackClientName,
    'naming': {
      'preserveSchemaCasing': config.naming.preserveSchemaCasing,
      'replaceRules': [
        for (final rule in config.naming.replaceRules)
          {
            'target': rule.target.name,
            'pattern': rule.pattern,
            'replacement': rule.replacement,
          },
      ],
    },
    'operationFilters': {
      'includePaths': config.operationFilters.includePaths,
      'excludePaths': config.operationFilters.excludePaths,
      'includeTags': config.operationFilters.includeTags,
      'excludeTags': config.operationFilters.excludeTags,
    },
    'pruneUnusedModels': config.pruneUnusedModels,
    'keepModels': config.keepModels,
    'excludeParameters': [
      for (final rule in config.excludeParameters)
        {
          'name': rule.name,
          'location': rule.location,
          'paths': rule.paths,
          'methods': rule.methods,
        },
    ],
    'typeMappings': [
      for (final rule in config.typeMappings)
        {
          'schema': rule.schema,
          'direction': rule.direction.name,
          'type': rule.type,
          'format': rule.format,
          'defaults': [
            for (final entry in rule.defaults)
              {
                'value': entry.value,
                'importUrl': entry.importUrl,
                'constant': entry.constant,
              },
          ],
          'dartType': rule.dartType,
          'importUrl': rule.importUrl,
          'codec': {
            'importUrl': rule.codec.importUrl,
            'fromJson': rule.codec.fromJson,
            'toJson': rule.codec.toJson,
          },
        },
    ],
    'httpClient': config.httpClient.name,
    'serializer': config.serializer.name,
    'responseMode': config.responseMode.name,
    'unknownEnumValues': config.unknownEnumValues.name,
    'unknownDiscriminatorValues': config.unknownDiscriminatorValues.name,
    'generateDocs': config.generateDocs,
    'bodyPositional': config.bodyPositional,
    'usePathForMethodNames': config.usePathForMethodNames,
    'originalHttpResponse': config.originalHttpResponse,
    'applyParameterDefaults': config.applyParameterDefaults,
    'inferMissingRequired': config.inferMissingRequired,
    'usePresenceRecords': config.usePresenceRecords,
    'generateValidators': config.generateValidators,
    'streamBinaryResponses': config.streamBinaryResponses,
    'decodeResponsesInBackground': config.decodeResponsesInBackground,
    'pageWidth': config.pageWidth,
    'fileSuffix': config.fileSuffix,
    'apiMetadata': config.apiMetadata.name,
  },
  'library': {
    'documentation': {
      for (final e in m.documentation.entries) e.key: _documentation(e.value),
    },
    'fieldDocumentation': {
      for (final e in m.fieldDocumentation.entries)
        e.key: {
          for (final f in e.value.entries) f.key: _documentation(f.value),
        },
    },
    'validators': m.validators,
    'validatorExtensions': m.validatorExtensions,
    'validationErrors': m.validationErrors,
    'validationErrorName': m.validationErrorName,
    'validationErrorImport': m.validationErrorImport,
    'imports': m.imports,
    'exports': m.exports,
    'modelPaths': m.modelPaths,
    'httpRequestOptionsPath': m.httpRequestOptionsPath,
    'httpResponsePath': m.httpResponsePath,
    'typeExports': m.typeExports,
    'constantImports': m.constantImports,
    'apiMetadata': m.apiMetadata,
    'metadataTypeName': m.metadataTypeName,
    'metadataTypePath': m.metadataTypePath,
    'clientMetadataName': m.clientMetadataName,
    'clientMetadataPath': m.clientMetadataPath,
    'attachOperationMetadata': m.attachOperationMetadata,
    'metadataOperations': m.metadataOperations.map(_operation).toList(),
    if (m.facade case final f?) ...{
      'name': f.name,
      'version': f.version,
      'title': f.title,
      'specVersion': f.specVersion,
      'operationConstants': f.operationConstants,
      'metadataNames': f.metadataNames,
      'metadataTypeName': f.metadataTypeName,
      'clients': [
        for (final entry in f.clients.entries)
          {
            'name': entry.key,
            'type': entry.value,
            'importPath': f.clientPaths[entry.value],
          },
      ],
    },
    if (kind == 'client') ...{
      'clientName': m.clientName,
      'resultFile': m.resultFile,
      'operations': m.operations.map(_operation).toList(),
    },
    if (kind == 'results') 'results': m.results.map(_operation).toList(),
    if (kind == 'models') ...{
      'dtos': [
        for (final d in m.dtos)
          {
            'name': d.name,
            'json': d.json,
            'ignoredWireKeys': d.ignoredWireKeys.toList(),
            'extraValueType': _type(d.extraValueType),
            'fields': [
              for (final f in d.fields)
                {
                  'name': f.name,
                  'wireName': f.wireName ?? f.name,
                  'type': _type(f.type),
                  'isRequired': f.isRequired,
                  'acceptsNull': f.acceptsNull,
                  'tracksPresence': f.tracksPresence,
                  'discriminatorValues': f.discriminatorValues,
                  'isFixed': f.fixedValue != null,
                  'fixedValue': f.fixedValue?.value,
                  'fixedExpression': f.fixedExpression,
                  'hasDefault': f.defaultValue != null,
                  'defaultValue': f.defaultValue?.value,
                  'defaultExpression': f.defaultExpression,
                },
            ],
          },
      ],
      'enums': [
        for (final e in m.enums)
          {
            'name': e.name,
            'openNames': e.openNames == null
                ? null
                : {
                    'values': e.openNames!.values,
                    'known': e.openNames!.known,
                    'unknown': e.openNames!.unknown,
                    'rawType': e.openNames!.rawType,
                  },
            'values': [
              for (final v in e.values.entries)
                {'name': v.key, 'value': v.value},
            ],
          },
      ],
      'values': [
        for (final v in m.values) {'name': v.name, 'type': _type(v.type)},
      ],
      'unions': [
        for (final u in m.unions)
          {
            'name': u.name,
            'propertyName': u.propertyName,
            'mapping': u.mapping,
            'defaultType': u.defaultType,
            'unknownType': u.unknownType,
          },
      ],
      'structuralUnions': [
        for (final u in m.structuralUnions)
          {
            'name': u.name,
            'exclusive': u.exclusive,
            'commonMatcher': u.commonMatcher,
            'projectionMatcher': u.projectionMatcher,
            'branches': [
              for (final b in u.branches)
                {
                  'label': b.label,
                  'matcher': b.matcher,
                  'type': _type(b.type),
                  'implementation': b.implementation,
                },
            ],
          },
      ],
      'tuples': [
        for (final t in m.tuples)
          {
            'name': t.name,
            'positions': t.positions.map(_type).toList(),
            'requiredCount': t.requiredCount,
            'arrayOnly': t.arrayOnly,
            'matcher': t.matcher,
            'project': t.project,
            'restType': _type(t.restType),
          },
      ],
      'matchers': [
        for (final r in m.matchers)
          {
            'name': r.name,
            'types': r.types.toList()..sort(),
            'constraints': r.constraints,
            'ignoredWireKeys': r.ignoredWireKeys.toList(),
            'properties': r.properties,
            'items': r.items,
            'prefixItems': r.prefixItems,
            'contains': r.contains,
            'additional': r.additional,
            'allOf': r.allOf,
            'oneOf': r.oneOf,
            'anyOf': r.anyOf,
            'reject': r.reject,
          },
      ],
    },
  },
};

Map<String, Object?>? _type(DartTypeReference? type) => type == null
    ? null
    : {
        'symbol': type.symbol,
        'importUrl': type.importUrl,
        'isNullable': type.isNullable,
        if (type.scalarCodec case final codec?)
          'scalarCodec': {
            'dartType': codec.dartType,
            'wireType': codec.wireType,
            'typeImport': codec.typeImport,
            'typePrefix': codec.typePrefix,
            'codecImport': codec.codecImport,
            'codecPrefix': codec.codecPrefix,
            'fromJson': codec.fromJson,
            'toJson': codec.toJson,
            'adapter': codec.adapter,
            'matcher': codec.matcher,
            'defaults': [
              for (final entry in codec.defaults)
                {'value': entry.value.value, 'expression': entry.expression},
            ],
          }
        else
          'scalarCodec': null,
        'typeArguments': type.typeArguments.map(_type).toList(),
      };

Map<String, Object?> _operation(DartClientOperation op) => {
  'name': op.name,
  'operationId': op.operationId,
  'tags': op.tags,
  'externalDocsUrl': op.externalDocsUrl,
  'method': op.method,
  'path': op.path,
  'pathLiteral': jsonEncode(op.path).replaceAll(r'$', r'\$'),
  'summary': op.summary,
  'description': op.description,
  'deprecated': op.deprecated,
  'extra': op.extra,
  'response': _type(op.response),
  'status': op.status,
  'mediaType': op.mediaType,
  'objectResponse': op.objectResponse,
  'objectTypes': op.objectTypes.toList()..sort(),
  'body': switch (op.body) {
    null => null,
    final DartClientBody b => {
      ..._documentation(b.documentation),
      'type': _type(b.type),
      'isRequired': b.isRequired,
      'mediaType': b.mediaType,
      'isObjectDto': b.isObjectDto,
      'allowsAbsentAndNull': b.allowsAbsentAndNull,
      'fields': [
        for (final f in b.fields)
          {
            ..._documentation(f.documentation),
            'name': f.name,
            'key': f.key,
            'type': _type(f.type),
            'required': f.required,
            'file': f.file,
            'separator': f.separator,
            'contentType': f.contentType,
            'defaultExpression': f.defaultValue?.expression,
          },
      ],
    },
  },
  'parameters': [
    for (final p in op.parameters)
      {
        ..._documentation(p.documentation),
        'name': p.name,
        'wireName': p.wireName,
        'type': _type(p.type),
        'isRequired': p.isRequired,
        'defaultExpression': p.defaultValue?.expression,
        'location': p.location.name,
        'pathStyle': p.pathStyle.name,
        'explode': p.explode,
        'listSeparator': p.listSeparator,
        'queryListFormat': p.queryListFormat?.name,
        'allowReserved': p.allowReserved,
        'contentType': p.contentType,
        'scalarCodec': p.scalarCodec,
        'rawCookie': p.rawCookie,
        'isFormQueryObject': p.isFormQueryObject,
        'objectShape': p.objectShape?.name,
      },
  ],
  'variants': [
    for (final e in op.variants.entries)
      {
        'statusKey': e.key,
        'name': e.value.name,
        'type': _type(e.value.type),
        'mediaType': e.value.mediaType,
        'objectPayload': e.value.objectPayload,
      },
  ],
};

Map<String, Object?> _documentation(DartDocumentation value) => {
  'summary': value.summary,
  'description': value.description,
  'deprecated': value.deprecated,
};
