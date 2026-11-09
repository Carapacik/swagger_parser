part of 'open_api_v3_0_document_parser.dart';

extension _PathsReader on OpenApiV30DocumentParser {
  OpenApiV30PathItem _pathItem(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
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
    return OpenApiV30PathItem(
      ref: reader.optional(r'$ref', context.string),
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      get: reader.optional('get', _operation),
      put: reader.optional('put', _operation),
      post: reader.optional('post', _operation),
      delete: reader.optional('delete', _operation),
      options: reader.optional('options', _operation),
      head: reader.optional('head', _operation),
      patch: reader.optional('patch', _operation),
      trace: reader.optional('trace', _operation),
      servers: reader.optional('servers', listOf(_server)),
      parameters: reader.optional('parameters', listOf(_refOr(_parameter))),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Operation _operation(Object? value, String path) {
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
    return OpenApiV30Operation(
      responses: reader.required('responses', _responses),
      tags: reader.optional('tags', listOf(context.string)),
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      operationId: reader.optional('operationId', context.string),
      parameters: reader.optional('parameters', listOf(_refOr(_parameter))),
      requestBody: reader.optional('requestBody', _refOr(_requestBody)),
      callbacks: reader.optional('callbacks', mapOf(_refOr(_callback))),
      deprecated: reader.optional('deprecated', context.boolean),
      security: reader.optional('security', listOf(_securityRequirement)),
      servers: reader.optional('servers', listOf(_server)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Components _components(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'schemas',
      'responses',
      'parameters',
      'examples',
      'requestBodies',
      'headers',
      'securitySchemes',
      'links',
      'callbacks',
    });
    return OpenApiV30Components(
      schemas: reader.optional('schemas', componentsMap(_refOr(_schema))),
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

  OpenApiV30Paths _paths(Object? value, String path) {
    final ParsedEntries<OpenApiV30PathItem> data = readEntries(
      value,
      path,
      _pathItem,
      validKey: (key) => key.startsWith('/'),
    );
    return OpenApiV30Paths(entries: data.entries, extensions: data.extensions);
  }

  OpenApiV30Responses _responses(Object? value, String path) {
    final ParsedEntries<OpenApiV30RefOr<OpenApiV30Response>> data = readEntries(
      value,
      path,
      _refOr(_response),
      validKey: (key) =>
          key == 'default' || OpenApi3Reader.statusCode.hasMatch(key),
    );
    if (data.entries.isEmpty) {
      context.fail('Expected at least one response.', path);
    }
    return OpenApiV30Responses(
      entries: data.entries,
      extensions: data.extensions,
    );
  }

  OpenApiV30Callback _callback(Object? value, String path) {
    final ParsedEntries<OpenApiV30PathItem> data = readEntries(
      value,
      path,
      _pathItem,
    );
    return OpenApiV30Callback(
      entries: data.entries,
      extensions: data.extensions,
    );
  }
}
