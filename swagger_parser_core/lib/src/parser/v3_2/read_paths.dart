part of 'open_api_v3_2_document_parser.dart';

extension _PathsReader on OpenApiV32DocumentParser {
  OpenApiV32PathItem _pathItem(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'query',
      'additionalOperations',
      r'$ref',
      'summary',
      'description',
      'get',
      'put',
      'post',
      'delete',
      'options',
      'head',
      'patch',
      'trace',
      'servers',
      'parameters',
    });
    final List<OpenApiV32RefOr<OpenApiV32Parameter>>? parameters = _parameters(
      reader,
    );
    final Iterable<OpenApiV32Parameter> inherited =
        parameters?.whereType<OpenApiV32Inline<OpenApiV32Parameter>>().map(
          (item) => item.value,
        ) ??
        const <OpenApiV32Parameter>[];
    OpenApiV32Operation readOperation(Object? value, String path) =>
        _operation(value, path, inherited);
    return OpenApiV32PathItem(
      query: reader.optional('query', readOperation),
      additionalOperations: reader.optional(
        'additionalOperations',
        (value, path) => _additionalOperations(value, path, readOperation),
      ),
      ref: reader.optional(r'$ref', context.string),
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      get: reader.optional('get', readOperation),
      put: reader.optional('put', readOperation),
      post: reader.optional('post', readOperation),
      delete: reader.optional('delete', readOperation),
      options: reader.optional('options', readOperation),
      head: reader.optional('head', readOperation),
      patch: reader.optional('patch', readOperation),
      trace: reader.optional('trace', readOperation),
      servers: reader.optional('servers', listOf(_server)),
      parameters: parameters,
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  static final _httpToken = RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$");
  static const _fixedMethods = {
    'GET',
    'PUT',
    'POST',
    'DELETE',
    'OPTIONS',
    'HEAD',
    'PATCH',
    'TRACE',
    'QUERY',
  };

  Map<String, OpenApiV32Operation> _additionalOperations(
    Object? value,
    String path,
    ValueParser<OpenApiV32Operation> readOperation,
  ) {
    final Map<String, Object?> fields = objectFields(value, path);
    final operations = <String, OpenApiV32Operation>{};
    for (final MapEntry<String, Object?> entry in fields.entries) {
      final String method = entry.key;
      final String methodPath = appendPointer(path, method);
      if (!_httpToken.hasMatch(method) || _fixedMethods.contains(method)) {
        context.fail('Expected an additional HTTP method.', methodPath);
      }
      operations[method] = readOperation(entry.value, methodPath);
    }
    return operations;
  }

  OpenApiV32Operation _operation(
    Object? value,
    String path,
    Iterable<OpenApiV32Parameter> inherited,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'responses',
      'tags',
      'summary',
      'description',
      'externalDocs',
      'operationId',
      'parameters',
      'requestBody',
      'callbacks',
      'deprecated',
      'security',
      'servers',
    });
    return OpenApiV32Operation(
      responses: reader.optional('responses', _responses),
      tags: reader.optional('tags', listOf(context.string)),
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      operationId: reader.optional('operationId', context.string),
      parameters: _parameters(reader, inherited),
      requestBody: reader.optional('requestBody', _refOr(_requestBody)),
      callbacks: reader.optional('callbacks', mapOf(_refOr(_callback))),
      deprecated: reader.optional('deprecated', context.boolean),
      security: reader.optional('security', listOf(_securityRequirement)),
      servers: reader.optional('servers', listOf(_server)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  List<OpenApiV32RefOr<OpenApiV32Parameter>>? _parameters(
    ObjectReader reader, [
    Iterable<OpenApiV32Parameter> inherited = const [],
  ]) {
    final List<OpenApiV32RefOr<OpenApiV32Parameter>>? parameters = reader
        .optional('parameters', listOf(_refOr(_parameter)));
    if (parameters == null) {
      return null;
    }

    var hasQuery = false;
    String? querystring;
    for (final parameter in inherited) {
      if (parameter.location == OpenApiV32ParameterLocation.query) {
        hasQuery = true;
      }
      if (parameter.location == OpenApiV32ParameterLocation.querystring) {
        querystring = parameter.name;
      }
    }
    final names = <(OpenApiV32ParameterLocation, String)>{};
    for (var index = 0; index < parameters.length; index++) {
      if (parameters[index] case OpenApiV32Inline<OpenApiV32Parameter>(
        :final value,
      )) {
        final path = '${reader.path}/parameters/$index';
        if (!names.add((value.location, value.name))) {
          context.fail('Duplicate parameter.', path);
        }
        switch (value.location) {
          case OpenApiV32ParameterLocation.querystring:
            if (hasQuery ||
                (querystring != null && querystring != value.name)) {
              context.fail(
                'A querystring parameter must describe the entire query.',
                '$path/in',
              );
            }
            querystring = value.name;
          case OpenApiV32ParameterLocation.query:
            if (querystring != null) {
              context.fail(
                'Cannot combine query and querystring parameters.',
                '$path/in',
              );
            }
            hasQuery = true;
          case OpenApiV32ParameterLocation.header:
          case OpenApiV32ParameterLocation.cookie:
          case OpenApiV32ParameterLocation.path:
            break;
        }
      }
    }
    return parameters;
  }

  OpenApiV32Components _components(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'mediaTypes',
      'schemas',
      'pathItems',
      'responses',
      'parameters',
      'examples',
      'requestBodies',
      'headers',
      'securitySchemes',
      'links',
      'callbacks',
    });
    return OpenApiV32Components(
      mediaTypes: reader.optional(
        'mediaTypes',
        componentsMap(_refOr(_mediaType)),
      ),
      pathItems: reader.optional('pathItems', componentsMap(_pathItem)),
      schemas: reader.optional('schemas', componentsMap(_schema)),
      responses: reader.optional('responses', componentsMap(_refOr(_response))),
      parameters: reader.optional(
        'parameters',
        componentsMap(_refOr(_parameter)),
      ),
      examples: reader.optional('examples', componentsMap(_refOr(_example))),
      requestBodies: reader.optional(
        'requestBodies',
        componentsMap(_refOr(_requestBody)),
      ),
      headers: reader.optional('headers', componentsMap(_refOr(_header))),
      securitySchemes: reader.optional(
        'securitySchemes',
        componentsMap(_refOr(_securityScheme)),
      ),
      links: reader.optional('links', componentsMap(_refOr(_link))),
      callbacks: reader.optional('callbacks', componentsMap(_refOr(_callback))),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32Paths _paths(Object? value, String path) {
    final ParsedEntries<OpenApiV32PathItem> data = readEntries(
      value,
      path,
      _pathItem,
      validKey: (key) => key.startsWith('/'),
    );
    return OpenApiV32Paths(entries: data.entries, extensions: data.extensions);
  }

  OpenApiV32Responses _responses(Object? value, String path) {
    final ParsedEntries<OpenApiV32RefOr<OpenApiV32Response>> data = readEntries(
      value,
      path,
      _refOr(_response),
      validKey: (key) =>
          key == 'default' || OpenApi3Reader.statusCode.hasMatch(key),
    );
    if (data.entries.isEmpty) {
      context.fail('Expected at least one response.', path);
    }
    return OpenApiV32Responses(
      entries: data.entries,
      extensions: data.extensions,
    );
  }

  OpenApiV32Callback _callback(Object? value, String path) {
    final ParsedEntries<OpenApiV32PathItem> data = readEntries(
      value,
      path,
      _pathItem,
    );
    return OpenApiV32Callback(
      entries: data.entries,
      extensions: data.extensions,
    );
  }
}
