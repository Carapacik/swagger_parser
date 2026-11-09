import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/v2/swagger_v2_objects.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/object_reader.dart';

/// Reads the fixed fields and maps of a Swagger 2.0 document.
final class const SwaggerV2DocumentParser(
  /// Typed readers and error locations for the source document.
  final ReadContext context,
) {
  /// Uses the source positions and options in [context].
  this;

  /// Reads a typed document from decoded source fields.
  SwaggerV2Document parse(Object? value) => _document(value, '');

  SwaggerV2Document _document(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'info',
      'paths',
      'host',
      'basePath',
      'schemes',
      'consumes',
      'produces',
      'definitions',
      'parameters',
      'responses',
      'securityDefinitions',
      'security',
      'tags',
      'externalDocs',
      'swagger',
    });
    final result = SwaggerV2Document(
      info: reader.required('info', _info),
      paths: reader.required('paths', _paths),
      host: reader.optional('host', context.string),
      basePath: reader.optional('basePath', context.string),
      schemes: reader.optional(
        'schemes',
        (value, path) => context.list(value, path, context.string),
      ),
      consumes: reader.optional(
        'consumes',
        (value, path) => context.list(value, path, context.string),
      ),
      produces: reader.optional(
        'produces',
        (value, path) => context.list(value, path, context.string),
      ),
      definitions: reader.optional(
        'definitions',
        (value, path) => context.map(value, path, _schema),
      ),
      parameters: reader.optional(
        'parameters',
        (value, path) => context.map(value, path, _parameter),
      ),
      responses: reader.optional(
        'responses',
        (value, path) => context.map(value, path, _response),
      ),
      securityDefinitions: reader.optional(
        'securityDefinitions',
        (value, path) => context.map(value, path, _securityScheme),
      ),
      security: reader.optional(
        'security',
        (value, path) => context.list(value, path, _securityRequirement),
      ),
      tags: reader.optional(
        'tags',
        (value, path) => context.list(value, path, _tag),
      ),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    if (result.schemes != null) {
      for (var i = 0; i < result.schemes!.length; i++) {
        if (!const {
          'http',
          'https',
          'ws',
          'wss',
        }.contains(result.schemes![i])) {
          context.fail('Unsupported transport scheme.', '$path/schemes/$i');
        }
      }
    }
    return result;
  }

  SwaggerV2Contact _contact(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {'name', 'url', 'email'});
    final result = SwaggerV2Contact(
      name: reader.optional('name', context.string),
      url: reader.optional('url', context.string),
      email: reader.optional('email', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2License _license(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {'name', 'url'});
    final result = SwaggerV2License(
      name: reader.required('name', context.string),
      url: reader.optional('url', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2Info _info(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'title',
      'version',
      'description',
      'termsOfService',
      'contact',
      'license',
    });
    final result = SwaggerV2Info(
      title: reader.required('title', context.string),
      version: reader.required('version', context.string),
      description: reader.optional('description', context.string),
      termsOfService: reader.optional('termsOfService', context.string),
      contact: reader.optional('contact', _contact),
      license: reader.optional('license', _license),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2ExternalDocumentation _externalDocumentation(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, {'url', 'description'});
    final result = SwaggerV2ExternalDocumentation(
      url: reader.required('url', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2Xml _xml(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'name',
      'namespace',
      'prefix',
      'attribute',
      'wrapped',
    });
    final result = SwaggerV2Xml(
      name: reader.optional('name', context.string),
      namespace: reader.optional('namespace', context.string),
      prefix: reader.optional('prefix', context.string),
      attribute: reader.optional('attribute', context.boolean),
      wrapped: reader.optional('wrapped', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2Tag _tag(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'name',
      'description',
      'externalDocs',
    });
    final result = SwaggerV2Tag(
      name: reader.required('name', context.string),
      description: reader.optional('description', context.string),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2Items _items(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'type',
      'format',
      'items',
      'collectionFormat',
      'maximum',
      'exclusiveMaximum',
      'minimum',
      'exclusiveMinimum',
      'maxLength',
      'minLength',
      'pattern',
      'maxItems',
      'minItems',
      'uniqueItems',
      'enum',
      'multipleOf',
      'default',
    });
    final result = SwaggerV2Items(
      type: reader.required('type', _primitiveType),
      format: reader.optional('format', context.string),
      items: reader.optional('items', _items),
      collectionFormat: reader.optional(
        'collectionFormat',
        (value, path) =>
            context.enumeration(value, path, SwaggerV2CollectionFormat.values),
      ),
      maximum: reader.optional('maximum', context.number),
      exclusiveMaximum: reader.optional('exclusiveMaximum', context.boolean),
      minimum: reader.optional('minimum', context.number),
      exclusiveMinimum: reader.optional('exclusiveMinimum', context.boolean),
      maxLength: reader.optional('maxLength', context.integer),
      minLength: reader.optional('minLength', context.integer),
      pattern: reader.optional('pattern', context.string),
      maxItems: reader.optional('maxItems', context.integer),
      minItems: reader.optional('minItems', context.integer),
      uniqueItems: reader.optional('uniqueItems', context.boolean),
      enumValues: reader.optional(
        'enum',
        (value, path) => context.list(value, path, context.jsonValue),
      ),
      multipleOf: reader.optional('multipleOf', context.number),
      defaultValue: reader.optional('default', context.jsonValue),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    _checkConstraints(reader);
    _checkPrimitive(result.type, result.items, path);
    if (result.collectionFormat == SwaggerV2CollectionFormat.multi) {
      context.fail(
        'multi is not valid here.',
        appendPointer(path, 'collectionFormat'),
      );
    }
    return result;
  }

  SwaggerV2Header _header(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'type',
      'description',
      'format',
      'items',
      'collectionFormat',
      'maximum',
      'exclusiveMaximum',
      'minimum',
      'exclusiveMinimum',
      'maxLength',
      'minLength',
      'pattern',
      'maxItems',
      'minItems',
      'uniqueItems',
      'enum',
      'multipleOf',
      'default',
    });
    final result = SwaggerV2Header(
      type: reader.required('type', _primitiveType),
      description: reader.optional('description', context.string),
      format: reader.optional('format', context.string),
      items: reader.optional('items', _items),
      collectionFormat: reader.optional(
        'collectionFormat',
        (value, path) =>
            context.enumeration(value, path, SwaggerV2CollectionFormat.values),
      ),
      maximum: reader.optional('maximum', context.number),
      exclusiveMaximum: reader.optional('exclusiveMaximum', context.boolean),
      minimum: reader.optional('minimum', context.number),
      exclusiveMinimum: reader.optional('exclusiveMinimum', context.boolean),
      maxLength: reader.optional('maxLength', context.integer),
      minLength: reader.optional('minLength', context.integer),
      pattern: reader.optional('pattern', context.string),
      maxItems: reader.optional('maxItems', context.integer),
      minItems: reader.optional('minItems', context.integer),
      uniqueItems: reader.optional('uniqueItems', context.boolean),
      enumValues: reader.optional(
        'enum',
        (value, path) => context.list(value, path, context.jsonValue),
      ),
      multipleOf: reader.optional('multipleOf', context.number),
      defaultValue: reader.optional('default', context.jsonValue),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    _checkConstraints(reader);
    _checkPrimitive(result.type, result.items, path);
    if (result.collectionFormat == SwaggerV2CollectionFormat.multi) {
      context.fail(
        'multi is not valid here.',
        appendPointer(path, 'collectionFormat'),
      );
    }
    return result;
  }

  SwaggerV2Schema _schema(
    Object? value,
    String path, {
    bool allowFile = false,
  }) {
    final reader = ObjectReader(context, value, path, {
      r'$ref',
      'type',
      'format',
      'title',
      'description',
      'items',
      'allOf',
      'properties',
      'additionalProperties',
      'required',
      'maxProperties',
      'minProperties',
      'discriminator',
      'readOnly',
      'xml',
      'externalDocs',
      'example',
      'maximum',
      'exclusiveMaximum',
      'minimum',
      'exclusiveMinimum',
      'maxLength',
      'minLength',
      'pattern',
      'maxItems',
      'minItems',
      'uniqueItems',
      'enum',
      'multipleOf',
      'default',
    });
    final result = SwaggerV2Schema(
      ref: reader.optional(r'$ref', context.string),
      type: reader.optional(
        'type',
        (value, path) => _schemaType(value, path, allowFile: allowFile),
      ),
      format: reader.optional('format', context.string),
      title: reader.optional('title', context.string),
      description: reader.optional('description', context.string),
      items: reader.optional('items', _schemaItems),
      allOf: reader.optional(
        'allOf',
        (value, path) => context.list(value, path, _schema),
      ),
      properties: reader.optional(
        'properties',
        (value, path) => context.map(value, path, _schema),
      ),
      additionalProperties: reader.optional(
        'additionalProperties',
        _additionalProperties,
      ),
      requiredProperties: reader.optional(
        'required',
        (value, path) => context.list(value, path, context.string),
      ),
      maxProperties: reader.optional('maxProperties', context.integer),
      minProperties: reader.optional('minProperties', context.integer),
      discriminator: reader.optional('discriminator', context.string),
      readOnly: reader.optional('readOnly', context.boolean),
      xml: reader.optional('xml', _xml),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      example: reader.optional('example', context.jsonValue),
      maximum: reader.optional('maximum', context.number),
      exclusiveMaximum: reader.optional('exclusiveMaximum', context.boolean),
      minimum: reader.optional('minimum', context.number),
      exclusiveMinimum: reader.optional('exclusiveMinimum', context.boolean),
      maxLength: reader.optional('maxLength', context.integer),
      minLength: reader.optional('minLength', context.integer),
      pattern: reader.optional('pattern', context.string),
      maxItems: reader.optional('maxItems', context.integer),
      minItems: reader.optional('minItems', context.integer),
      uniqueItems: reader.optional('uniqueItems', context.boolean),
      enumValues: reader.optional(
        'enum',
        (value, path) => context.list(value, path, context.jsonValue),
      ),
      multipleOf: reader.optional('multipleOf', context.number),
      defaultValue: reader.optional('default', context.jsonValue),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    _checkConstraints(reader);
    return result;
  }

  SwaggerV2BodyParameter _bodyParameter(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'name',
      'schema',
      'description',
      'required',
      'in',
    });
    final result = SwaggerV2BodyParameter(
      name: reader.required('name', context.string),
      schema: reader.required('schema', _schema),
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2ValueParameter _valueParameter(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'name',
      'in',
      'type',
      'description',
      'required',
      'format',
      'allowEmptyValue',
      'items',
      'collectionFormat',
      'maximum',
      'exclusiveMaximum',
      'minimum',
      'exclusiveMinimum',
      'maxLength',
      'minLength',
      'pattern',
      'maxItems',
      'minItems',
      'uniqueItems',
      'enum',
      'multipleOf',
      'default',
    });
    final result = SwaggerV2ValueParameter(
      name: reader.required('name', context.string),
      location: reader.required(
        'in',
        (value, path) =>
            context.enumeration(value, path, SwaggerV2ParameterLocation.values),
      ),
      type: reader.required('type', _primitiveType),
      description: reader.optional('description', context.string),
      isRequired: reader.optional('required', context.boolean),
      format: reader.optional('format', context.string),
      allowEmptyValue: reader.optional('allowEmptyValue', context.boolean),
      items: reader.optional('items', _items),
      collectionFormat: reader.optional(
        'collectionFormat',
        (value, path) =>
            context.enumeration(value, path, SwaggerV2CollectionFormat.values),
      ),
      maximum: reader.optional('maximum', context.number),
      exclusiveMaximum: reader.optional('exclusiveMaximum', context.boolean),
      minimum: reader.optional('minimum', context.number),
      exclusiveMinimum: reader.optional('exclusiveMinimum', context.boolean),
      maxLength: reader.optional('maxLength', context.integer),
      minLength: reader.optional('minLength', context.integer),
      pattern: reader.optional('pattern', context.string),
      maxItems: reader.optional('maxItems', context.integer),
      minItems: reader.optional('minItems', context.integer),
      uniqueItems: reader.optional('uniqueItems', context.boolean),
      enumValues: reader.optional(
        'enum',
        (value, path) => context.list(value, path, context.jsonValue),
      ),
      multipleOf: reader.optional('multipleOf', context.number),
      defaultValue: reader.optional('default', context.jsonValue),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    _checkConstraints(reader);
    _checkPrimitive(
      result.type,
      result.items,
      path,
      allowFile: result.location == SwaggerV2ParameterLocation.formData,
    );
    if (result.location == SwaggerV2ParameterLocation.path &&
        result.isRequired != true) {
      context.fail(
        'Path parameters must be required.',
        appendPointer(path, 'required'),
        parent: path,
      );
    }
    if (result.collectionFormat == SwaggerV2CollectionFormat.multi &&
        result.location != SwaggerV2ParameterLocation.query &&
        result.location != SwaggerV2ParameterLocation.formData) {
      context.fail(
        'multi is only valid for query or formData.',
        appendPointer(path, 'collectionFormat'),
      );
    }
    if (result.allowEmptyValue != null &&
        result.location != SwaggerV2ParameterLocation.query &&
        result.location != SwaggerV2ParameterLocation.formData) {
      context.fail(
        'allowEmptyValue is only valid for query or formData.',
        appendPointer(path, 'allowEmptyValue'),
      );
    }
    return result;
  }

  SwaggerV2Response _response(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'description',
      'schema',
      'headers',
      'examples',
    });
    final result = SwaggerV2Response(
      description: reader.required('description', context.string),
      schema: reader.optional(
        'schema',
        (value, path) => _schema(value, path, allowFile: true),
      ),
      headers: reader.optional(
        'headers',
        (value, path) => context.map(value, path, _header),
      ),
      examples: reader.optional(
        'examples',
        (value, path) => context.map(value, path, context.jsonValue),
      ),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2Operation _operation(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      'responses',
      'tags',
      'summary',
      'description',
      'externalDocs',
      'operationId',
      'consumes',
      'produces',
      'parameters',
      'schemes',
      'deprecated',
      'security',
    });
    final result = SwaggerV2Operation(
      responses: reader.required('responses', _responses),
      tags: reader.optional(
        'tags',
        (value, path) => context.list(value, path, context.string),
      ),
      summary: reader.optional('summary', context.string),
      description: reader.optional('description', context.string),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      operationId: reader.optional('operationId', context.string),
      consumes: reader.optional(
        'consumes',
        (value, path) => context.list(value, path, context.string),
      ),
      produces: reader.optional(
        'produces',
        (value, path) => context.list(value, path, context.string),
      ),
      parameters: reader.optional(
        'parameters',
        (value, path) => context.list(
          value,
          path,
          (value, path) => _refOr(value, path, _parameter),
        ),
      ),
      schemes: reader.optional(
        'schemes',
        (value, path) => context.list(value, path, context.string),
      ),
      deprecated: reader.optional('deprecated', context.boolean),
      security: reader.optional(
        'security',
        (value, path) => context.list(value, path, _securityRequirement),
      ),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    if (result.schemes != null) {
      for (var i = 0; i < result.schemes!.length; i++) {
        if (!const {
          'http',
          'https',
          'ws',
          'wss',
        }.contains(result.schemes![i])) {
          context.fail('Unsupported transport scheme.', '$path/schemes/$i');
        }
      }
    }
    return result;
  }

  SwaggerV2PathItem _pathItem(Object? value, String path) {
    final reader = ObjectReader(context, value, path, {
      r'$ref',
      'get',
      'put',
      'post',
      'delete',
      'options',
      'head',
      'patch',
      'parameters',
    });
    final result = SwaggerV2PathItem(
      ref: reader.optional(r'$ref', context.string),
      get: reader.optional('get', _operation),
      put: reader.optional('put', _operation),
      post: reader.optional('post', _operation),
      delete: reader.optional('delete', _operation),
      options: reader.optional('options', _operation),
      head: reader.optional('head', _operation),
      patch: reader.optional('patch', _operation),
      parameters: reader.optional(
        'parameters',
        (value, path) => context.list(
          value,
          path,
          (value, path) => _refOr(value, path, _parameter),
        ),
      ),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2BasicSecurityScheme _basicSecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, {'description', 'type'});
    final result = SwaggerV2BasicSecurityScheme(
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2ApiKeySecurityScheme _apiKeySecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, {
      'name',
      'in',
      'description',
      'type',
    });
    final result = SwaggerV2ApiKeySecurityScheme(
      name: reader.required('name', context.string),
      location: reader.required(
        'in',
        (value, path) =>
            context.enumeration(value, path, SwaggerV2ApiKeyLocation.values),
      ),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    return result;
  }

  SwaggerV2OAuth2SecurityScheme _oAuth2SecurityScheme(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, {
      'flow',
      'scopes',
      'authorizationUrl',
      'tokenUrl',
      'description',
      'type',
    });
    final result = SwaggerV2OAuth2SecurityScheme(
      flow: reader.required(
        'flow',
        (value, path) =>
            context.enumeration(value, path, SwaggerV2OAuthFlow.values),
      ),
      scopes: reader.required(
        'scopes',
        (value, path) => context.map(value, path, context.string),
      ),
      authorizationUrl: reader.optional('authorizationUrl', context.string),
      tokenUrl: reader.optional('tokenUrl', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
    if (result.flow == SwaggerV2OAuthFlow.implicit ||
        result.flow == SwaggerV2OAuthFlow.accessCode) {
      reader.required('authorizationUrl', context.string);
    }
    if (result.flow != SwaggerV2OAuthFlow.implicit) {
      reader.required('tokenUrl', context.string);
    }
    return result;
  }

  SwaggerV2RefOr<T> _refOr<T extends SwaggerV2JsonSerializable>(
    Object? value,
    String path,
    ValueParser<T> parse,
  ) {
    if (value is Map<String, Object?> && value.containsKey(r'$ref')) {
      final reader = ObjectReader(context, value, path, {
        r'$ref',
      }, allowExtensions: false);
      return SwaggerV2Reference<T>(
        reader.required(r'$ref', context.string),
        extraFields: reader.extras,
      );
    }
    return SwaggerV2Inline<T>(parse(value, path));
  }

  SwaggerV2Parameter _parameter(Object? value, String path) {
    if (value is! Map<String, Object?>) {
      context.fail('Expected a parameter object.', path);
    }
    if (!value.containsKey('in')) {
      context.fail(
        'Missing required field: in.',
        appendPointer(path, 'in'),
        parent: path,
      );
    }
    final SwaggerV2ParameterLocation location = context.enumeration(
      value['in'],
      appendPointer(path, 'in'),
      SwaggerV2ParameterLocation.values,
    );
    return location == SwaggerV2ParameterLocation.body
        ? _bodyParameter(value, path)
        : _valueParameter(value, path);
  }

  SwaggerV2SecurityScheme _securityScheme(Object? value, String path) {
    if (value is! Map<String, Object?>) {
      context.fail('Expected a security scheme.', path);
    }
    if (!value.containsKey('type')) {
      context.fail(
        'Missing required field: type.',
        appendPointer(path, 'type'),
        parent: path,
      );
    }
    return switch (context.string(value['type'], appendPointer(path, 'type'))) {
      'basic' => _basicSecurityScheme(value, path),
      'apiKey' => _apiKeySecurityScheme(value, path),
      'oauth2' => _oAuth2SecurityScheme(value, path),
      _ => context.fail(
        'Unsupported security scheme type.',
        appendPointer(path, 'type'),
      ),
    };
  }

  SwaggerV2Paths _paths(Object? value, String path) {
    if (value is! Map<String, Object?>) {
      context.fail('Expected a paths object.', path);
    }
    final Set<String> keys = value.keys
        .where((key) => !key.startsWith('x-'))
        .toSet();
    for (final key in keys) {
      if (!key.startsWith('/')) {
        context.fail('A path must start with /.', appendPointer(path, key));
      }
    }
    final reader = ObjectReader(context, value, path, keys);
    return SwaggerV2Paths(
      entries: {for (final key in keys) key: reader.required(key, _pathItem)},
      extensions: reader.extensions,
    );
  }

  SwaggerV2Responses _responses(Object? value, String path) {
    if (value is! Map<String, Object?>) {
      context.fail('Expected a responses object.', path);
    }
    final Set<String> keys = value.keys
        .where((key) => !key.startsWith('x-'))
        .toSet();
    if (keys.isEmpty) {
      context.fail('Expected at least one response.', path);
    }
    for (final key in keys) {
      if (key != 'default' && !RegExp(r'^[1-5][0-9]{2}$').hasMatch(key)) {
        context.fail(
          'Expected an HTTP status code or default.',
          appendPointer(path, key),
        );
      }
    }
    final reader = ObjectReader(context, value, path, keys);
    return SwaggerV2Responses(
      entries: {
        for (final key in keys)
          key: reader.required(
            key,
            (value, path) => _refOr(value, path, _response),
          ),
      },
      extensions: reader.extensions,
    );
  }

  SwaggerV2SecurityRequirement _securityRequirement(
    Object? value,
    String path,
  ) => SwaggerV2SecurityRequirement(
    context.map(
      value,
      path,
      (value, path) => context.list(value, path, context.string),
    ),
  );

  SwaggerV2AdditionalProperties _additionalProperties(
    Object? value,
    String path,
  ) => value is bool
      ? SwaggerV2AdditionalPropertiesAllowed(allowed: value)
      : SwaggerV2AdditionalPropertiesSchema(_schema(value, path));

  SwaggerV2SchemaItems _schemaItems(Object? value, String path) {
    if (value is List<Object?>) {
      if (value.isEmpty) {
        context.fail('A tuple must contain at least one schema.', path);
      }
      return SwaggerV2TupleItems(context.list(value, path, _schema));
    }
    return SwaggerV2SingleItems(_schema(value, path));
  }

  SwaggerV2SchemaType _schemaType(
    Object? value,
    String path, {
    bool allowFile = false,
  }) {
    SwaggerV2Type parse(Object? value, String path) {
      final SwaggerV2Type type = _primitiveType(value, path);
      if (type == SwaggerV2Type.file && !allowFile) {
        context.fail('file is only valid in a response schema.', path);
      }
      return type;
    }

    if (value is List<Object?>) {
      if (value.isEmpty) {
        context.fail('Expected at least one type.', path);
      }
      final List<SwaggerV2Type> values = context.list(value, path, parse);
      if (values.toSet().length != values.length) {
        context.fail('Duplicate schema type.', path);
      }
      return SwaggerV2TypeSet(values);
    }
    return SwaggerV2SingleType(parse(value, path));
  }

  SwaggerV2Type _primitiveType(Object? value, String path) {
    final String name = context.string(value, path);
    for (final SwaggerV2Type type in SwaggerV2Type.values) {
      if (type.wireName == name) {
        return type;
      }
    }
    context.fail('Unsupported type: $name.', path);
  }

  void _checkPrimitive(
    SwaggerV2Type type,
    SwaggerV2Items? items,
    String path, {
    bool allowFile = false,
  }) {
    if (type == SwaggerV2Type.object ||
        type == SwaggerV2Type.nullValue ||
        (type == SwaggerV2Type.file && !allowFile)) {
      context.fail(
        'Invalid parameter, header or item type.',
        appendPointer(path, 'type'),
      );
    }
    if (type == SwaggerV2Type.array && items == null) {
      context.fail(
        'Array items are required.',
        appendPointer(path, 'items'),
        parent: path,
      );
    }
  }

  void _checkConstraints(ObjectReader reader) {
    for (final key in [
      'maxLength',
      'minLength',
      'maxItems',
      'minItems',
      'maxProperties',
      'minProperties',
    ]) {
      if (reader.known.contains(key) && reader.fields.containsKey(key)) {
        final int value = reader.required(key, context.integer);
        if (value < 0) {
          context.fail(
            'Expected a non-negative integer.',
            appendPointer(reader.path, key),
          );
        }
      }
    }
    if (reader.fields.containsKey('multipleOf') &&
        reader.required('multipleOf', context.number) <= 0) {
      context.fail(
        'multipleOf must be positive.',
        appendPointer(reader.path, 'multipleOf'),
      );
    }
    for (final key in ['enum', 'allOf', 'required']) {
      final Object? value = reader.known.contains(key)
          ? reader.fields[key]
          : null;
      if (value is List<Object?> && value.isEmpty) {
        context.fail(
          'Expected a non-empty array.',
          appendPointer(reader.path, key),
        );
      }
    }
  }
}
