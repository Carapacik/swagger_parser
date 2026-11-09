part of 'open_api_v3_2_document_parser.dart';

extension _PayloadsReader on OpenApiV32DocumentParser {
  OpenApiV32Parameter _parameter(Object? value, String path) {
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
    final OpenApiV32ParameterLocation location = reader.required(
      'in',
      enumOf(OpenApiV32ParameterLocation.values),
    );
    _checkParameter(reader, location);
    return OpenApiV32Parameter(
      name: reader.required('name', context.string),
      location: location,
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      deprecated: reader.optional('deprecated', context.boolean),
      allowEmptyValue: reader.optional('allowEmptyValue', context.boolean),
      style: reader.optional('style', enumOf(OpenApiV32Style.values)),
      explode: reader.optional('explode', context.boolean),
      allowReserved: reader.optional('allowReserved', context.boolean),
      schema: reader.optional('schema', _schema),
      example: reader.optional('example', context.jsonValue),
      examples: reader.optional('examples', mapOf(_refOr(_example))),
      content: reader.optional('content', mapOf(_refOr(_mediaType))),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  void _checkEncoding(ObjectReader reader) {
    exclusiveFields(reader, 'encoding', 'prefixEncoding');
    exclusiveFields(reader, 'encoding', 'itemEncoding');
  }

  void _checkParameter(
    ObjectReader reader,
    OpenApiV32ParameterLocation location,
  ) {
    final Map<String, Object?> fields = reader.fields;
    exclusiveFields(reader, 'example', 'examples');
    exclusiveFields(reader, 'schema', 'content');
    if (location == OpenApiV32ParameterLocation.path &&
        fields['required'] != true) {
      failField(reader, 'required', 'Path parameters require required: true.');
    }
    if (fields.containsKey('allowEmptyValue') &&
        location != OpenApiV32ParameterLocation.query) {
      failField(
        reader,
        'allowEmptyValue',
        'allowEmptyValue requires a query parameter.',
      );
    }
    if (fields.containsKey('content')) {
      final Map<String, Object?> content = objectFields(
        fields['content'],
        appendPointer(reader.path, 'content'),
      );
      if (content.length != 1) {
        failField(reader, 'content', 'Expected one media type.');
      }
      for (final key in const ['style', 'explode', 'allowReserved']) {
        if (fields.containsKey(key)) {
          failField(reader, key, '$key requires schema.');
        }
      }
      return;
    }
    if (location == OpenApiV32ParameterLocation.querystring) {
      failField(reader, 'content', 'Querystring parameters require content.');
    }
    if (!fields.containsKey('schema')) {
      failField(reader, 'schema', 'Expected schema or content.');
    }
    _checkStyle(reader, location);
    if (location == OpenApiV32ParameterLocation.cookie &&
        fields['explode'] == false) {
      failField(
        reader,
        'explode',
        'Cookie parameters cannot set explode to false.',
      );
    }
    if (fields.containsKey('allowReserved') &&
        (location == OpenApiV32ParameterLocation.header ||
            (location == OpenApiV32ParameterLocation.cookie &&
                fields['style'] == 'cookie'))) {
      failField(
        reader,
        'allowReserved',
        'allowReserved requires a percent-encoded style.',
      );
    }
  }

  void _checkStyle(ObjectReader reader, OpenApiV32ParameterLocation location) {
    final OpenApiV32Style? style = reader.optional(
      'style',
      enumOf(OpenApiV32Style.values),
    );
    if (style == null) {
      return;
    }
    final Set<OpenApiV32Style> valid = switch (location) {
      OpenApiV32ParameterLocation.path => const {
        OpenApiV32Style.matrix,
        OpenApiV32Style.label,
        OpenApiV32Style.simple,
      },
      OpenApiV32ParameterLocation.query => const {
        OpenApiV32Style.form,
        OpenApiV32Style.spaceDelimited,
        OpenApiV32Style.pipeDelimited,
        OpenApiV32Style.deepObject,
      },
      OpenApiV32ParameterLocation.cookie => const {
        OpenApiV32Style.form,
        OpenApiV32Style.cookie,
      },
      OpenApiV32ParameterLocation.header => const {OpenApiV32Style.simple},
      OpenApiV32ParameterLocation.querystring => const <OpenApiV32Style>{},
    };
    if (!valid.contains(style)) {
      failField(reader, 'style', 'Invalid style for ${location.name}.');
    }
  }

  OpenApiV32Header _header(Object? value, String path) {
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
    for (final key in const [
      'name',
      'in',
      'allowEmptyValue',
      'allowReserved',
    ]) {
      if (reader.fields.containsKey(key)) {
        failField(reader, key, 'Header objects cannot set $key.');
      }
    }
    _checkParameter(reader, OpenApiV32ParameterLocation.header);
    return OpenApiV32Header(
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      deprecated: reader.optional('deprecated', context.boolean),
      style: reader.optional('style', enumOf(OpenApiV32Style.values)),
      explode: reader.optional('explode', context.boolean),
      schema: reader.optional('schema', _schema),
      example: reader.optional('example', context.jsonValue),
      examples: reader.optional('examples', mapOf(_refOr(_example))),
      content: reader.optional('content', mapOf(_refOr(_mediaType))),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32RequestBody _requestBody(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'content',
      'description',
      'required',
    });
    return OpenApiV32RequestBody(
      content: reader.required('content', mapOf(_refOr(_mediaType))),
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32MediaType _mediaType(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'itemSchema',
      'prefixEncoding',
      'itemEncoding',
      'schema',
      'example',
      'examples',
      'encoding',
    });
    exclusiveFields(reader, 'example', 'examples');
    _checkEncoding(reader);
    return OpenApiV32MediaType(
      itemSchema: reader.optional('itemSchema', _schema),
      prefixEncoding: reader.optional('prefixEncoding', listOf(_encoding)),
      itemEncoding: reader.optional('itemEncoding', _encoding),
      schema: reader.optional('schema', _schema),
      example: reader.optional('example', context.jsonValue),
      examples: reader.optional('examples', mapOf(_refOr(_example))),
      encoding: reader.optional('encoding', mapOf(_encoding)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32Encoding _encoding(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'encoding',
      'prefixEncoding',
      'itemEncoding',
      'contentType',
      'headers',
      'style',
      'explode',
      'allowReserved',
    });
    _checkEncoding(reader);
    _checkStyle(reader, OpenApiV32ParameterLocation.query);
    return OpenApiV32Encoding(
      encoding: reader.optional('encoding', mapOf(_encoding)),
      prefixEncoding: reader.optional('prefixEncoding', listOf(_encoding)),
      itemEncoding: reader.optional('itemEncoding', _encoding),
      contentType: reader.optional('contentType', context.string),
      headers: reader.optional('headers', mapOf(_refOr(_header))),
      style: reader.optional('style', enumOf(OpenApiV32Style.values)),
      explode: reader.optional('explode', context.boolean),
      allowReserved: reader.optional('allowReserved', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32Response _response(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'summary',
      'description',
      'headers',
      'content',
      'links',
    });
    return OpenApiV32Response(
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      headers: reader.optional('headers', mapOf(_refOr(_header))),
      content: reader.optional('content', mapOf(_refOr(_mediaType))),
      links: reader.optional('links', mapOf(_refOr(_link))),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32Example _example(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'dataValue',
      'serializedValue',
      'summary',
      'description',
      'value',
      'externalValue',
    });
    exclusiveFields(reader, 'value', 'externalValue');
    exclusiveFields(reader, 'value', 'dataValue');
    exclusiveFields(reader, 'value', 'serializedValue');
    exclusiveFields(reader, 'externalValue', 'serializedValue');
    return OpenApiV32Example(
      dataValue: reader.optional('dataValue', context.jsonValue),
      serializedValue: reader.optional('serializedValue', context.string),
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      value: reader.optional('value', context.jsonValue),
      externalValue: reader.optional('externalValue', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32Link _link(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'operationRef',
      'operationId',
      'parameters',
      'requestBody',
      'description',
      'server',
    });
    exclusiveFields(reader, 'operationId', 'operationRef');
    return OpenApiV32Link(
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
