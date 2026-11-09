part of 'open_api_v3_1_document_parser.dart';

extension _PayloadsReader on OpenApiV31DocumentParser {
  OpenApiV31Parameter _parameter(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'in',
      'description',
      'required',
      'deprecated',
      'allowEmptyValue',
      'style',
      'explode',
      'allowReserved',
      'schema',
      'example',
      'examples',
      'content',
    });
    checkParameter(reader, header: false);
    return OpenApiV31Parameter(
      name: reader.required('name', context.string),
      location: reader.required(
        'in',
        enumOf(OpenApiV31ParameterLocation.values),
      ),
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      deprecated: reader.optional('deprecated', context.boolean),
      allowEmptyValue: reader.optional('allowEmptyValue', context.boolean),
      style: reader.optional('style', enumOf(OpenApiV31Style.values)),
      explode: reader.optional('explode', context.boolean),
      allowReserved: reader.optional('allowReserved', context.boolean),
      schema: reader.optional('schema', _schema),
      example: reader.optional('example', context.jsonValue),
      examples: reader.optional('examples', mapOf(_refOr(_example))),
      content: reader.optional('content', mapOf(_mediaType)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Header _header(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'description',
      'required',
      'deprecated',
      'style',
      'explode',
      'schema',
      'example',
      'examples',
      'content',
    });
    checkParameter(reader, header: true);
    return OpenApiV31Header(
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      deprecated: reader.optional('deprecated', context.boolean),
      style: reader.optional('style', enumOf(OpenApiV31Style.values)),
      explode: reader.optional('explode', context.boolean),
      schema: reader.optional('schema', _schema),
      example: reader.optional('example', context.jsonValue),
      examples: reader.optional('examples', mapOf(_refOr(_example))),
      content: reader.optional('content', mapOf(_mediaType)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31RequestBody _requestBody(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'content',
      'description',
      'required',
    });
    return OpenApiV31RequestBody(
      content: reader.required('content', mapOf(_mediaType)),
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31MediaType _mediaType(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'schema',
      'example',
      'examples',
      'encoding',
    });
    exclusiveFields(reader, 'example', 'examples');
    return OpenApiV31MediaType(
      schema: reader.optional('schema', _schema),
      example: reader.optional('example', context.jsonValue),
      examples: reader.optional('examples', mapOf(_refOr(_example))),
      encoding: reader.optional('encoding', mapOf(_encoding)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Encoding _encoding(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'contentType',
      'headers',
      'style',
      'explode',
      'allowReserved',
    });
    checkStyle(reader, OpenApiV31ParameterLocation.query);
    return OpenApiV31Encoding(
      contentType: reader.optional('contentType', context.string),
      headers: reader.optional('headers', mapOf(_refOr(_header))),
      style: reader.optional('style', enumOf(OpenApiV31Style.values)),
      explode: reader.optional('explode', context.boolean),
      allowReserved: reader.optional('allowReserved', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Response _response(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'description',
      'headers',
      'content',
      'links',
    });
    return OpenApiV31Response(
      description: reader.required('description', context.string),
      headers: reader.optional('headers', mapOf(_refOr(_header))),
      content: reader.optional('content', mapOf(_mediaType)),
      links: reader.optional('links', mapOf(_refOr(_link))),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Example _example(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'summary',
      'description',
      'value',
      'externalValue',
    });
    exclusiveFields(reader, 'value', 'externalValue');
    return OpenApiV31Example(
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      value: reader.optional('value', context.jsonValue),
      externalValue: reader.optional('externalValue', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Link _link(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'operationRef',
      'operationId',
      'parameters',
      'requestBody',
      'description',
      'server',
    });
    exclusiveFields(reader, 'operationId', 'operationRef');
    return OpenApiV31Link(
      operationRef: reader.optional('operationRef', context.string),
      operationId: reader.optional('operationId', context.string),
      parameters: reader.optional('parameters', mapOf(context.jsonValue)),
      requestBody: reader.optional('requestBody', context.jsonValue),
      description: reader.optional('description', context.string),
      server: reader.optional('server', _server),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }
}
