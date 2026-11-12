import 'package:swagger_parser/src/extraction/api_definition.dart';
import 'package:swagger_parser/src/generation/generation_exception.dart';
import 'package:swagger_parser_core/swagger_parser_core.dart';

part 'schema_registry.dart';

/// Extracts route operations and schemas from a validated document.
interface class const ApiDefinitionExtractor() {
  /// Creates the built-in extractor.
  this;

  /// Uses the reference graph resolved from [document].
  ///
  /// Throws [GenerationException] for unsupported operation features.
  ApiDefinition extract(OpenApiDocument document, ReferenceGraph references) {
    final Map<String, Object?> root = document.toJson();
    final (
      String title,
      String apiVersion,
      String? dialect,
    ) = switch (document) {
      SwaggerV2Document() => (document.info.title, document.info.version, null),
      OpenApiV30Document() => (
        document.info.title,
        document.info.version,
        null,
      ),
      OpenApiV31Document() => (
        document.info.title,
        document.info.version,
        document.jsonSchemaDialect ?? OpenApiV31Schema.oasDialect,
      ),
      OpenApiV32Document() => (
        document.info.title,
        document.info.version,
        document.jsonSchemaDialect ?? OpenApiV32Schema.oasDialect,
      ),
    };
    final entry = LocatedNode(
      DocumentNode(NodeKind.document, root, ''),
      references.documentUri,
      document.version.family,
      dialect: dialect,
    );
    final extraction = _Extraction(entry, references);
    final names = <String, ReferenceLocation>{
      for (final schema in entry.children(NodeKind.schema))
        schema.node.key: extraction.registry.register(schema),
    };
    final routes = <ApiOperation>[];
    final webhooks = <ApiOperation>[];
    for (final LocatedNode item in entry.children(NodeKind.pathItem)) {
      if (item.node.pointer.startsWith('/paths/')) {
        routes.addAll(extraction.pathItem(item));
      } else if (item.node.pointer.startsWith('/webhooks/')) {
        webhooks.addAll(extraction.pathItem(item));
      }
    }
    return ApiDefinition(
      sourceUri: references.documentUri,
      title: title,
      apiVersion: apiVersion,
      specVersion: document.version,
      operations: routes,
      webhooks: webhooks,
      callbacks: extraction.callbacks,
      servers: extraction.servers(const {}, null),
      security: _objects(root['security']),
      securitySchemes: extraction.definitions(entry, NodeKind.securityScheme),
      namedSchemas: names,
      schemas: extraction.registry.schemas,
      dynamicAnchors: {
        for (final binding in references.dynamicAnchors.entries)
          if (extraction.registry.schemas.containsKey(binding.value.location))
            binding.key: binding.value.location,
      },
    );
  }
}

Never _fail(
  LocatedNode site,
  String message, {
  String code = 'unsupportedExtraction',
  String? field,
}) {
  final String pointer = field == null
      ? site.node.pointer
      : '${site.node.pointer}/$field';
  throw GenerationException(
    message,
    diagnostics: [
      Diagnostic(
        code: code,
        message: message,
        severity: DiagnosticSeverity.error,
        sourceUri: site.uri,
        documentPath: pointer,
      ),
    ],
  );
}

Iterable<JsonValue> _objects(Object? list) =>
    (list as List<Object?>? ?? const []).map(JsonValue.new);

final class _Extraction(final LocatedNode entry, final ReferenceGraph graph) {
  final _SchemaRegistry registry = _SchemaRegistry(graph);

  final callbacks = <ReferenceLocation, List<ApiOperation>>{};
  final activeMedia = <ReferenceLocation>{};

  Iterable<ApiOperation> pathItem(LocatedNode site) sync* {
    final List<LocatedNode> chain = site.referenceChain(graph).toList();
    final LocatedNode last = chain.last;
    if (last.node.fields.containsKey(r'$ref') &&
        graph.targetFor(last.at('${last.node.pointer}/\$ref')) == null) {
      _fail(
        last,
        'Missing resolved Path Item reference.',
        field: r'$ref',
        code: 'unresolvedDefinition',
      );
    }
    final item = EffectivePathItem.fromChain(chain);
    final Object? pathServers = chain
        .map((layer) => layer.node.fields['servers'])
        .nonNulls
        .firstOrNull;
    for (final MapEntry<String, LocatedNode> op in item.operations.entries) {
      final String method = op.key.startsWith('additionalOperations/')
          ? op.value.node.key
          : op.key.toUpperCase();
      yield _operation(
        method,
        site.node.key,
        op.value,
        item.parameterOwner,
        pathServers,
      );
    }
  }

  Map<String, JsonValue> definitions(LocatedNode owner, NodeKind kind) => {
    for (final use in owner.children(kind))
      use.node.key: JsonValue(_definition(use).node.value),
  };

  Iterable<JsonValue> servers(
    Map<String, Object?> fields,
    Object? pathServers,
  ) {
    final Map<String, Object?> root = entry.node.fields;
    if (entry.family != OpenApiFamily.swaggerV2) {
      return _objects(fields['servers'] ?? pathServers ?? root['servers']);
    }
    final server = <String, Object?>{
      'host': ?root['host'],
      'basePath': ?root['basePath'],
      'schemes': ?(fields['schemes'] ?? root['schemes']),
    };
    return [if (server.isNotEmpty) JsonValue(server)];
  }

  ReferenceLocation _callback(LocatedNode site) {
    final LocatedNode callback = _definition(site);
    if (!callbacks.containsKey(callback.location)) {
      final operations = <ApiOperation>[];
      callbacks[callback.location] = operations;
      for (final LocatedNode item in callback.children(NodeKind.pathItem)) {
        operations.addAll(pathItem(item));
      }
    }
    return callback.location;
  }

  LocatedNode _definition(LocatedNode use) {
    final List<LocatedNode> chain = use.referenceChain(graph).toList();
    final LocatedNode result = chain.last;
    if (result.node.fields.containsKey(r'$ref')) {
      _fail(
        use,
        'The reference chain has no definition.',
        code: 'unresolvedDefinition',
      );
    }
    // Keep the target location for relative references in its children.
    if (switch (result.node.kind) {
      NodeKind.parameter ||
      NodeKind.header ||
      NodeKind.response ||
      NodeKind.requestBody ||
      NodeKind.securityScheme => true,
      _ => false,
    }) {
      for (final LocatedNode reference in chain.take(chain.length - 1)) {
        if (reference.node.fields['description'] case final String description
            when reference.family == OpenApiFamily.v31 ||
                reference.family == OpenApiFamily.v32) {
          return LocatedNode(
            DocumentNode(result.node.kind, {
              ...result.node.fields,
              'description': description,
            }, result.node.pointer),
            result.uri,
            result.family,
            dialect: result.dialect,
          );
        }
      }
    }
    return result;
  }

  ApiOperation _operation(
    String method,
    String path,
    LocatedNode site,
    LocatedNode? shared,
    Object? pathServers,
  ) {
    final Map<String, Object?> fields = site.node.fields;
    final effective = <(String, String), LocatedNode>{};
    for (final owner in [?shared, site]) {
      for (final LocatedNode use in owner.children(NodeKind.parameter)) {
        final LocatedNode parameter = _definition(use);
        if (parameter.node.fields case {
          'name': final String name,
          'in': final String location,
        }) {
          effective[(
                location,
                location == 'header' ? name.toLowerCase() : name,
              )] =
              parameter;
        } else {
          _fail(
            parameter,
            'Expected a parameter name and location.',
            code: 'invalidParameter',
          );
        }
      }
    }
    final responses = <String, ApiResponse>{
      for (final use in site.children(NodeKind.response))
        use.node.key: _response(
          _definition(use),
          fields['produces'] ?? entry.node.fields['produces'],
        ),
    };
    final List<LocatedNode> bodyParameters = effective.values
        .where((p) => p.node.fields['in'] == 'body')
        .toList();
    final List<ApiParameter> forms = effective.values
        .where((p) => p.node.fields['in'] == 'formData')
        .map(_parameter)
        .toList();
    if (bodyParameters.length > 1 ||
        (bodyParameters.isNotEmpty && forms.isNotEmpty)) {
      _fail(
        site,
        'Use one body parameter or a set of form parameters.',
        code: 'invalidRequestBody',
      );
    }
    return ApiOperation(
      method: method,
      servers: servers(fields, pathServers),
      security: _objects(fields['security'] ?? entry.node.fields['security']),
      callbacks: {
        for (final use in site.children(NodeKind.callback))
          use.node.key: _callback(use),
      },
      requestBody: _requestBody(site, bodyParameters.firstOrNull, forms),
      path: path,
      operationId: fields['operationId'] as String?,
      externalDocsUrl:
          (fields['externalDocs'] as Map<String, Object?>?)?['url'] as String?,
      source: site.location,
      summary: fields['summary'] as String?,
      description: fields['description'] as String?,
      tags: (fields['tags'] as List<Object?>? ?? []).cast<String>(),
      deprecated: fields['deprecated'] == true,
      parameters: effective.entries
          .where((e) => e.key.$1 != 'body' && e.key.$1 != 'formData')
          .map((e) => _parameter(e.value)),
      responses: responses,
    );
  }

  ApiRequestBody? _requestBody(
    LocatedNode site,
    LocatedNode? body,
    List<ApiParameter> forms,
  ) {
    if (site.children(NodeKind.requestBody).firstOrNull case final use?) {
      final LocatedNode definition = _definition(use);
      return ApiRequestBody(
        source: definition.location,
        description: definition.node.fields['description'] as String?,
        isRequired: definition.node.fields['required'] == true,
        content: _content(definition),
      );
    }
    if (body == null && forms.isEmpty) {
      return null;
    }
    final Object? consumes =
        site.node.fields['consumes'] ?? entry.node.fields['consumes'];
    return ApiRequestBody(
      source: body?.location ?? site.location,
      description: body?.node.fields['description'] as String?,
      isRequired:
          body?.node.fields['required'] == true ||
          forms.any((p) => p.isRequired),
      formFields: forms,
      content: _swaggerContent(
        consumes,
        body == null
            ? null
            : registry.use(body.children(NodeKind.schema).single),
      ),
    );
  }

  Map<String?, ApiMediaType> _swaggerContent(
    Object? value,
    ReferenceLocation? schema,
  ) {
    final List<String> types = (value as List<Object?>? ?? []).cast<String>();
    final media = ApiMediaType(schema: schema);
    return {
      if (types.isEmpty) null: media,
      for (final type in types) type: media,
    };
  }

  ApiParameter _parameter(LocatedNode site, {String? header}) {
    final Map<String, Object?> fields = site.node.fields;
    final location = header == null ? fields['in']! as String : 'header';
    ReferenceLocation? schema;
    if (site.family == OpenApiFamily.swaggerV2) {
      // Swagger stores value constraints directly on the parameter.
      final constraints = <String, Object?>{
        for (final key in const [
          'type',
          'format',
          'x-nullable',
          'x-enumNames',
          'x-enum-varnames',
          'x-enum-metadata',
          'items',
          'default',
          'enum',
          'maximum',
          'minimum',
          'exclusiveMaximum',
          'exclusiveMinimum',
          'maxLength',
          'minLength',
          'pattern',
          'maxItems',
          'minItems',
          'uniqueItems',
          'multipleOf',
        ])
          if (fields.containsKey(key)) key: fields[key],
      };
      if (constraints['type'] is! String) {
        _fail(site, 'Expected a parameter type.', code: 'invalidParameter');
      }
      schema = registry.register(
        LocatedNode(
          DocumentNode(NodeKind.schema, constraints, site.node.pointer),
          site.uri,
          site.family,
        ),
      );
    } else {
      final LocatedNode? child = site.children(NodeKind.schema).firstOrNull;
      if (child == null && !fields.containsKey('content')) {
        _fail(site, 'Expected a parameter schema.', code: 'invalidParameter');
      }
      if (child != null) {
        schema = registry.use(child);
      }
    }
    return ApiParameter(
      description: fields['description'] as String?,
      deprecated: fields['deprecated'] == true,
      name: header ?? fields['name']! as String,
      allowReserved:
          site.family != OpenApiFamily.swaggerV2 &&
          fields['allowReserved'] == true,
      content: _content(site),
      location: location,
      isRequired: fields['required'] == true,
      schema: schema,
      source: site.location,
      serialization: ParameterSerialization.effective(site.family, {
        ...fields,
        'in': location,
      }),
    );
  }

  ApiResponse _response(LocatedNode site, Object? produces) {
    final LocatedNode? schema = site.children(NodeKind.schema).firstOrNull;
    return ApiResponse(
      description: site.node.fields['description'] as String?,
      source: site.location,
      headers: _headers(site),
      links: definitions(site, NodeKind.link),
      content: schema == null
          ? _content(site)
          : _swaggerContent(produces, registry.use(schema)),
    );
  }

  Map<String, ApiParameter> _headers(LocatedNode site) => {
    for (final use in site.children(NodeKind.header))
      use.node.key: _parameter(_definition(use), header: use.node.key),
  };

  Map<String?, ApiMediaType> _content(LocatedNode site) => {
    for (final use in site.children(NodeKind.mediaType))
      use.node.key: _media(_definition(use)),
  };

  ApiMediaType _media(LocatedNode site) {
    if (!activeMedia.add(site.location)) {
      _fail(site, 'Cyclic encoding headers cannot be expanded.');
    }
    final Map<String, ReferenceLocation> schemas = {
      for (final child in site.children(NodeKind.schema))
        child.node.key: registry.use(child),
    };
    final encodings = <String, ApiEncoding>{};
    void visit(LocatedNode parent) {
      for (final LocatedNode encoding in parent.children(NodeKind.encoding)) {
        encodings[encoding.node.pointer.substring(
          site.node.pointer.length,
        )] = ApiEncoding(
          definition: JsonValue(encoding.node.value),
          headers: _headers(encoding),
        );
        visit(encoding);
      }
    }

    visit(site);
    activeMedia.remove(site.location);
    return ApiMediaType(
      schema: schemas['schema'],
      itemSchema: schemas['itemSchema'],
      encodings: encodings,
    );
  }
}
