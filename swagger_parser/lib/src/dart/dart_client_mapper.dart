part of 'dart_model_mapper.dart';

extension on _Mapping {
  List<DartLibraryModel> _clientLibraries() {
    final folders = {'models'};
    final groups = <(String, String?), _ClientGroup>{};
    for (final ApiOperation op in selectedOperations) {
      final String tag = op.tags.firstOrNull?.trim() ?? '';
      final String replaced = _replaceName(tag, NamingTarget.clients);
      final String candidate = tag.isEmpty
          ? config.fallbackClientName
          : _identifierBase('${_clientSnakeCase(replaced)}_client', type: true);
      // Empty names and fallback routes retain their source group.
      final String? source = tag.isEmpty || !_word.hasMatch(replaced)
          ? tag
          : null;
      final _ClientGroup group = groups.putIfAbsent((
        candidate,
        source,
      ), () => _ClientGroup(candidate, fallback: tag.isEmpty));
      group.tags.add(tag);
      group.operations.add(op);
    }
    final clients = <DartLibraryModel>[];
    final Set<String> used = usedNames;
    final Set<String> objectTypes = Set.unmodifiable({
      for (final dto in dtos) dto.name,
      for (final union in unions) union.name,
    });
    final List<_ClientGroup> ordered = groups.values.toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    for (final group in ordered) {
      final List<DartClientOperation> operations = _clientOperations(
        group.operations,
        objectTypes,
      );
      if (operations.isEmpty) {
        continue;
      }
      final String name = _identifier(
        group.name,
        used,
        type: true,
        preserveCase: true,
      );
      final String stem = _clientSnakeCase(name);
      final String folder = group.fallback
          ? 'default_client'
          : stem.replaceFirst(RegExp(r'_client(?=\d*$)'), '');
      var uniqueFolder = folder;
      for (var n = 2; !folders.add(uniqueFolder); n++) {
        uniqueFolder = '${folder}_$n';
      }
      for (final String tag in group.tags) {
        clientFolders[tag] = uniqueFolder;
      }
      final String? resultFile = config.responseMode == ResponseMode.allStatuses
          ? _fileName('${stem}_results')
          : null;
      if (resultFile != null) {
        clients.add(
          DartLibraryModel(
            relativePath: '$uniqueFolder/$resultFile',
            dtos: const [],
            results: operations,
          ),
        );
      }
      clients.add(
        DartLibraryModel(
          clientName: name,
          relativePath: '$uniqueFolder/${_fileName(stem)}',
          resultFile: resultFile,
          dtos: const [],
          operations: operations,
        ),
      );
    }
    return clients;
  }

  List<DartClientOperation> _clientOperations(
    List<ApiOperation> group,
    Set<String> objectTypes,
  ) {
    final operations = <DartClientOperation>[];
    final Set<String> methodNames = {
      ..._memberNames,
      'models',
      'convert',
      'http',
      'baseUrl',
      'errorLogger',
      'newRequestOptions',
      if (config.httpClient == HttpClientBackend.http) 'prepareRequest',
    };
    for (final op in group) {
      void skip(String reason, [ReferenceLocation? at]) {
        final ReferenceLocation source = at ?? op.source;
        diagnostics.add(
          Diagnostic(
            severity: DiagnosticSeverity.warning,
            code: 'unsupportedClientOperation',
            message: 'Skipped ${op.method} ${op.path}. $reason',
            sourceUri: source.documentUri,
            documentPath: source.pointer,
          ),
        );
      }

      final ApiRequestBody? request = op.requestBody;
      final Set<String> arguments = {
        ..._memberNames,
        'data',
        'request',
        'query',
        'options',
        'response',
        'dio',
        'models',
        'queryParameters',
        'errorLogger',
        'baseUrl',
        'body',
        'extra',
        'cancelToken',
        'abortTrigger',
        'convert',
        'sendNullBody',
        'formData',
        if (config.httpClient == HttpClientBackend.http) ...{
          'http',
          'prepareRequest',
        },
      };
      final DartClientBody? body = request == null
          ? null
          : _httpBody(op, request, arguments);
      if (request != null && body == null) {
        skip(
          'Unsupported request media type or form encoding.',
          request.source,
        );
        continue;
      }
      if (config.httpClient == HttpClientBackend.http &&
          request != null &&
          body != null &&
          DartHttpMedia.parse(body.mediaType) == DartHttpMedia.multipart &&
          (request.content[body.mediaType]?.encodings.values.any(
                (e) => e.headers.isNotEmpty,
              ) ??
              false)) {
        skip(
          'package:http does not support custom multipart part headers.',
          request.source,
        );
        continue;
      }
      final all = config.responseMode == ResponseMode.allStatuses;
      final List<String> codes = op.responses.keys.toList()..sort();
      final Iterable<String> selected = all
          ? codes
          : codes
                .where(
                  (code) => code.startsWith('2') && int.tryParse(code) != null,
                )
                .take(1);
      if (all && codes.isEmpty) {
        skip('Expected at least one response.');
        continue;
      }
      final payloads = <String, DartTypeReference?>{};
      final mediaTypes = <String, String>{};
      for (final status in selected) {
        final ApiResponse response = op.responses[status]!;
        if (response.content.isEmpty) {
          payloads[status] = null;
          continue;
        }
        final MapEntry<String?, ApiMediaType>? entry = _selectMedia(
          response.content,
        );
        if (entry == null) {
          skip('Unsupported response media type.', response.source);
          break;
        }
        final ReferenceLocation? schema = entry.value.schema;
        final bool file =
            schema != null && index.use(schema).types.contains('file');
        final String media =
            entry.key ??
            (file ? 'application/octet-stream' : 'application/json');
        final DartTypeReference? type = _responseType(
          entry.value,
          media,
          '${_operationNameCandidate(op)}Response$status',
        );
        if (type == null) {
          skip('Unsupported response schema for $media.', response.source);
          break;
        }
        payloads[status] = type;
        mediaTypes[status] = media;
      }
      if (payloads.length != selected.length) {
        continue;
      }
      final parameters = <DartClientParameter>[];
      final List<ApiParameter> effective = op.parameters
          .where(
            (p) =>
                api.specVersion.family == OpenApiFamily.swaggerV2 ||
                p.location != 'header' ||
                !const {
                  'accept',
                  'content-type',
                  'authorization',
                }.contains(p.name.toLowerCase()),
          )
          .toList();
      for (final parameter in effective) {
        final DartClientParameter? mapped = _clientParameter(
          op,
          parameter,
          arguments,
        );
        if (mapped == null) {
          skip(
            'Unsupported ${parameter.location} parameter: ${parameter.name}.',
            parameter.source,
          );
          break;
        }
        parameters.add(mapped);
      }
      if (parameters.length != effective.length) {
        continue;
      }
      final String method = _identifier(
        _replaceName(_operationNameCandidate(op), NamingTarget.methods),
        methodNames,
      );
      final variants = <String, DartStatusVariant>{};
      final DartTypeReference result;
      if (!all) {
        result =
            payloads.values.firstOrNull ?? DartTypeReference(symbol: 'void');
      } else {
        result = DartTypeReference(
          symbol: _identifier('${method}Result', usedNames, type: true),
        );
        for (final MapEntry<String, DartTypeReference?> entry
            in payloads.entries) {
          final DartTypeReference? type = entry.value;
          variants[entry.key] = DartStatusVariant(
            _identifier('${method}_${entry.key}', usedNames, type: true),
            type,
            mediaType: mediaTypes[entry.key] ?? 'application/json',
            objectPayload: type != null && _objectDto(type),
          );
        }
      }
      operations.add(
        DartClientOperation(
          name: method,
          summary: config.generateDocs ? op.summary : null,
          description: config.generateDocs ? op.description : null,
          deprecated: op.deprecated,
          operationId: op.operationId,
          tags: op.tags,
          externalDocsUrl: op.externalDocsUrl,
          method: op.method,
          path: op.path,
          status: all ? null : int.tryParse(payloads.keys.firstOrNull ?? ''),
          variants: variants,
          parameters: parameters,
          response: result,
          objectResponse: _objectDto(result),
          body: body,
          extra: _operationExtra(op),
          objectTypes: objectTypes,
          mediaType: mediaTypes.values.firstOrNull ?? 'application/json',
        ),
      );
    }
    return operations;
  }

  bool _objectDto(DartTypeReference type) =>
      dtos.any((dto) => dto.name == type.symbol) ||
      unions.any((union) => union.name == type.symbol);

  DartClientParameter? _clientParameter(
    ApiOperation op,
    ApiParameter parameter,
    Set<String> arguments,
  ) {
    final DartClientParameterLocation? location = switch (parameter.location) {
      'path' => DartClientParameterLocation.path,
      'query' => DartClientParameterLocation.query,
      'header' => DartClientParameterLocation.header,
      'cookie' => DartClientParameterLocation.cookie,
      'querystring' => DartClientParameterLocation.querystring,
      _ => null,
    };
    if (location == null) {
      return null;
    }
    if (parameter.content.isNotEmpty) {
      final MapEntry<String?, ApiMediaType> entry =
          parameter.content.entries.single;
      final String? media = entry.key;
      if (media == null) {
        return null;
      }
      final ReferenceLocation? schema = entry.value.schema;
      final DartTypeReference type = _isJsonMedia(media) || media == _urlencoded
          ? (schema == null
                ? _any
                : _type(
                    index.use(schema, const {}, _Direction.request),
                    '${_operationNameCandidate(op)}_${parameter.name}',
                  ))
          : DartTypeReference(symbol: 'String');
      return DartClientParameter.at(
        name: _identifier(parameter.name, arguments),
        documentation: _parameterDocumentation(parameter),
        wireName: parameter.name,
        type: type,
        location: location,
        contentType: media,
        defaultValue: schema == null
            ? null
            : _argumentDefault(
                index.use(schema, const {}, _Direction.request),
                required:
                    parameter.isRequired ||
                    location == DartClientParameterLocation.path,
              ),
        isRequired:
            location == DartClientParameterLocation.path ||
            parameter.isRequired,
      );
    }
    final ReferenceLocation? id = parameter.schema;
    if (id == null || location == DartClientParameterLocation.querystring) {
      return null;
    }
    final query = location == DartClientParameterLocation.query;
    final cookie = location == DartClientParameterLocation.cookie;
    // The JSON backend sets these media headers for Swagger requests.
    if (location == DartClientParameterLocation.header &&
        const {
          'accept',
          'content-type',
        }.contains(parameter.name.toLowerCase())) {
      return null;
    }
    final ParameterSerialization wire = parameter.serialization;
    final DartTypeReference type = _wireType(
      _type(
        index.use(id, const {}, _Direction.request),
        '${_operationNameCandidate(op)}_${parameter.name}',
      ),
    );
    if (type.isNullable) {
      return null;
    }
    const scalars = {'String', 'int', 'num', 'bool'};
    bool scalarItem(DartTypeReference item) {
      final String symbol = _unwrappedParameterType(item).symbol;
      return !item.isNullable &&
          (scalars.contains(symbol) || enums.any((e) => e.name == symbol));
    }

    final bool scalarCodec =
        enums.any((e) => e.name == type.symbol) ||
        (scalars.contains(_unwrappedParameterType(type).symbol) &&
            !scalars.contains(type.symbol));
    final bool scalar = scalars.contains(type.symbol) || scalarCodec;
    final DartPathStyle pathStyle = switch ((location, wire.style)) {
      (DartClientParameterLocation.path, 'label') => DartPathStyle.label,
      (DartClientParameterLocation.path, 'matrix') => DartPathStyle.matrix,
      _ => DartPathStyle.simple,
    };
    String? separator;
    DartQueryListFormat? format;
    DartParameterObjectShape? objectShape;
    if (cookie && (wire.style == 'form' || wire.style == 'cookie')) {
      if (type.symbol == 'List') {
        if (!scalarItem(type.typeArguments.single)) {
          return null;
        }
      } else if (!scalar) {
        objectShape = _parameterObjectShape(type);
        if (objectShape == null) {
          return null;
        }
      }
    } else if (query &&
        {'spaceDelimited', 'pipeDelimited'}.contains(wire.style) &&
        wire.explode == false &&
        type.symbol != 'List') {
      objectShape = _parameterObjectShape(type);
      if (objectShape == null) {
        return null;
      }
      format = wire.style == 'spaceDelimited'
          ? DartQueryListFormat.ssv
          : DartQueryListFormat.pipes;
    } else if (query && wire.style == 'deepObject') {
      if (api.specVersion.family != OpenApiFamily.v32 && wire.explode != true) {
        return null;
      }
      objectShape = _parameterObjectShape(type);
      if (objectShape == null) {
        return null;
      }
    } else if (type.symbol == 'List') {
      final DartTypeReference item = type.typeArguments.single;
      if (!scalarItem(item)) {
        return null;
      }
      if (query) {
        format = switch ((wire.collectionFormat, wire.style, wire.explode)) {
          ('multi', _, _) || (null, 'form', true) => DartQueryListFormat.multi,
          ('csv', _, _) || (null, 'form', false) => DartQueryListFormat.csv,
          ('ssv', _, _) ||
          (null, 'spaceDelimited', false) => DartQueryListFormat.ssv,
          ('pipes', _, _) ||
          (null, 'pipeDelimited', false) => DartQueryListFormat.pipes,
          ('tsv', _, _) => DartQueryListFormat.tsv,
          _ => null,
        };
        if (format == null) {
          return null;
        }
      } else {
        separator = switch ((wire.collectionFormat, wire.style)) {
          ('csv', null) || (null, 'simple' || 'label' || 'matrix') => ',',
          ('ssv', null) => ' ',
          ('tsv', null) => '\t',
          ('pipes', null) => '|',
          _ => null,
        };
        if (separator == null) {
          return null;
        }
      }
    } else if (wire.style == (query ? 'form' : pathStyle.name) && !scalar) {
      objectShape = _parameterObjectShape(type);
      if (objectShape == null) {
        return null;
      }
    } else if (!scalar ||
        (wire.style != null &&
            wire.style != (query ? 'form' : pathStyle.name))) {
      return null;
    }
    return DartClientParameter.at(
      name: _identifier(parameter.name, arguments),
      documentation: _parameterDocumentation(parameter),
      wireName: parameter.name,
      defaultValue: _argumentDefault(
        index.use(id, const {}, _Direction.request),
        required:
            parameter.isRequired ||
            location == DartClientParameterLocation.path,
      ),
      type: type,
      location: location,
      allowReserved: parameter.allowReserved,
      scalarCodec: scalarCodec,
      rawCookie: wire.style == 'cookie',
      pathStyle: pathStyle,
      explode: wire.explode == true,
      listSeparator: separator,
      queryListFormat: format,
      objectShape: objectShape,
      isFormQueryObject:
          query && wire.style != 'deepObject' && objectShape != null,
      isRequired:
          location == DartClientParameterLocation.path || parameter.isRequired,
    );
  }

  DartParameterObjectShape? _parameterObjectShape(DartTypeReference type) {
    if (type.scalarCodec case final codec?) {
      return codec.parameterObjectShape;
    }
    final DartTypeReference wire = _unwrappedParameterType(type);
    final String symbol = wire.symbol;
    final Iterable<DartTypeReference> fields;
    if (symbol == 'Map') {
      fields = [wire.typeArguments.last];
    } else {
      final DartDtoModel? dto = dtos.where((d) => d.name == symbol).firstOrNull;
      if (dto == null) {
        return null;
      }
      fields = [for (final f in dto.fields) f.type, ?dto.extraValueType];
    }
    DartParameterObjectShape shape = DartParameterObjectShape.flat;
    for (final field in fields) {
      final DartTypeReference item = _unwrappedParameterType(field);
      if (item.symbol == 'Object') {
        shape = DartParameterObjectShape.open;
      } else if (!_dartScalars.containsValue(item.symbol) &&
          item.symbol != 'Null' &&
          !enums.any((e) => e.name == item.symbol)) {
        return null;
      }
    }
    return shape;
  }

  DartTypeReference _unwrappedParameterType(DartTypeReference type) {
    if (type.scalarCodec case final codec?) {
      return DartTypeReference(
        symbol: codec.wireType,
        isNullable: type.isNullable,
      );
    }
    final DartValueModel? wrapper = values
        .where((v) => v.name == type.symbol)
        .firstOrNull;
    return wrapper == null
        ? _wireType(type)
        : _unwrappedParameterType(wrapper.type);
  }
}

// Inline URI and form values use their wire types.
DartTypeReference _wireType(DartTypeReference type) {
  if (type.symbol != 'DateTime' && type.typeArguments.isEmpty) {
    return type;
  }
  return DartTypeReference(
    symbol: type.symbol == 'DateTime' ? 'String' : type.symbol,
    importUrl: type.importUrl,
    scalarCodec: type.scalarCodec,
    isNullable: type.isNullable,
    typeArguments: type.typeArguments.map(_wireType),
  );
}

String _clientSnakeCase(String name) => name
    .replaceAll(r'$', '_')
    .replaceAllMapped(RegExp('([A-Z])([A-Z][a-z])'), (m) => '${m[1]}_${m[2]}')
    .replaceAllMapped(RegExp('([a-z0-9])([A-Z])'), (m) => '${m[1]}_${m[2]}')
    .toLowerCase();

final class _ClientGroup(final String name, {required final bool fallback}) {
  final tags = <String>{};
  final operations = <ApiOperation>[];

  String get sortKey => tags.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
}
