part of 'open_api_v3_2_document_parser.dart';

extension _SchemaReader on OpenApiV32DocumentParser {
  OpenApiV32Schema _schema(Object? value, String path) =>
      _readSchema(value, path, defaultDialect);

  OpenApiV32Schema _readSchema(
    Object? value,
    String path,
    String inheritedDialect,
  ) {
    if (value is bool) {
      return OpenApiV32BooleanSchema(value: value, dialect: inheritedDialect);
    }
    final Map<String, Object?> fields = objectFields(value, path);
    final String dialect = fields.containsKey(r'$schema')
        ? context.absoluteUri(
            fields[r'$schema'],
            appendPointer(path, r'$schema'),
          )
        : inheritedDialect;
    final SchemaDialect kind = SchemaDialect.identify(
      dialect,
      OpenApiFamily.v32,
    );
    final oas = kind == SchemaDialect.openApi;
    if (kind == SchemaDialect.unknown) {
      return OpenApiV32ForeignSchema(dialect: dialect, fields: fields);
    }
    const standardKeywords = {
      r'$schema',
      r'$id',
      r'$ref',
      r'$anchor',
      r'$dynamicRef',
      r'$dynamicAnchor',
      r'$vocabulary',
      r'$comment',
      r'$defs',
      'type',
      'title',
      'description',
      'default',
      'deprecated',
      'readOnly',
      'writeOnly',
      'examples',
      'const',
      'enum',
      'multipleOf',
      'minimum',
      'maximum',
      'exclusiveMinimum',
      'exclusiveMaximum',
      'minLength',
      'maxLength',
      'pattern',
      'format',
      'minItems',
      'maxItems',
      'uniqueItems',
      'minContains',
      'maxContains',
      'minProperties',
      'maxProperties',
      'required',
      'dependentRequired',
      'allOf',
      'anyOf',
      'oneOf',
      'not',
      'if',
      'then',
      'else',
      'items',
      'prefixItems',
      'contains',
      'unevaluatedItems',
      'properties',
      'patternProperties',
      'propertyNames',
      'additionalProperties',
      'dependentSchemas',
      'unevaluatedProperties',
      'contentEncoding',
      'contentMediaType',
      'contentSchema',
    };
    const oasKeywords = {
      ...standardKeywords,
      'discriminator',
      'externalDocs',
      'xml',
      'example',
    };
    final reader = ObjectReader(
      context,
      fields,
      path,
      oas ? oasKeywords : standardKeywords,
      allowUnknown: true,
    );
    OpenApiV32Schema child(Object? node, String childPath) =>
        _readSchema(node, childPath, dialect);
    return OpenApiV32ObjectSchema(
      dialect: dialect,
      schemaDialect: reader.optional(r'$schema', context.absoluteUri),
      id: reader.optional(r'$id', _id),
      ref: reader.optional(r'$ref', context.string),
      anchor: reader.optional(r'$anchor', _anchor),
      dynamicRef: reader.optional(r'$dynamicRef', context.string),
      dynamicAnchor: reader.optional(r'$dynamicAnchor', _anchor),
      vocabulary: reader.optional(r'$vocabulary', mapOf(context.boolean)),
      comment: reader.optional(r'$comment', context.string),
      defs: reader.optional(r'$defs', mapOf(child)),
      type: reader.optional('type', _schemaType),
      title: reader.optional('title', context.string),
      description: reader.optional('description', context.string),
      defaultValue: reader.optional('default', context.jsonValue),
      deprecated: reader.optional('deprecated', context.boolean),
      readOnly: reader.optional('readOnly', context.boolean),
      writeOnly: reader.optional('writeOnly', context.boolean),
      examples: reader.optional('examples', listOf(context.jsonValue)),
      constValue: reader.optional('const', context.jsonValue),
      enumValues: reader.optional('enum', listOf(context.jsonValue)),
      multipleOf: reader.optional('multipleOf', _positive),
      minimum: reader.optional('minimum', context.number),
      maximum: reader.optional('maximum', context.number),
      exclusiveMinimum: reader.optional('exclusiveMinimum', context.number),
      exclusiveMaximum: reader.optional('exclusiveMaximum', context.number),
      minLength: reader.optional('minLength', _nonnegative),
      maxLength: reader.optional('maxLength', _nonnegative),
      pattern: reader.optional('pattern', context.string),
      format: reader.optional('format', context.string),
      minItems: reader.optional('minItems', _nonnegative),
      maxItems: reader.optional('maxItems', _nonnegative),
      uniqueItems: reader.optional('uniqueItems', context.boolean),
      minContains: reader.optional('minContains', _nonnegative),
      maxContains: reader.optional('maxContains', _nonnegative),
      minProperties: reader.optional('minProperties', _nonnegative),
      maxProperties: reader.optional('maxProperties', _nonnegative),
      requiredProperties: reader.optional('required', _uniqueStrings),
      dependentRequired: reader.optional(
        'dependentRequired',
        mapOf(_uniqueStrings),
      ),
      allOf: reader.optional('allOf', _schemaArray(child)),
      anyOf: reader.optional('anyOf', _schemaArray(child)),
      oneOf: reader.optional('oneOf', _schemaArray(child)),
      not: reader.optional('not', child),
      ifSchema: reader.optional('if', child),
      thenSchema: reader.optional('then', child),
      elseSchema: reader.optional('else', child),
      items: reader.optional('items', child),
      prefixItems: reader.optional('prefixItems', _schemaArray(child)),
      contains: reader.optional('contains', child),
      unevaluatedItems: reader.optional('unevaluatedItems', child),
      properties: reader.optional('properties', mapOf(child)),
      patternProperties: reader.optional('patternProperties', mapOf(child)),
      propertyNames: reader.optional('propertyNames', child),
      additionalProperties: reader.optional('additionalProperties', child),
      dependentSchemas: reader.optional('dependentSchemas', mapOf(child)),
      unevaluatedProperties: reader.optional('unevaluatedProperties', child),
      contentEncoding: reader.optional('contentEncoding', context.string),
      contentMediaType: reader.optional('contentMediaType', context.string),
      contentSchema: reader.optional('contentSchema', child),
      discriminator: oas
          ? reader.optional('discriminator', _discriminator)
          : null,
      xml: oas ? reader.optional('xml', _xml) : null,
      externalDocs: oas
          ? reader.optional('externalDocs', _externalDocumentation)
          : null,
      example: oas ? reader.optional('example', context.jsonValue) : null,
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  static final _anchorName = RegExp(r'^[A-Za-z_][-A-Za-z0-9._]*$');

  String _id(Object? value, String path) {
    final String id = context.string(value, path);
    if (id.contains('#') && id.indexOf('#') != id.length - 1) {
      context.fail(r'$id cannot contain a nonempty fragment.', path);
    }
    return id;
  }

  String _anchor(Object? value, String path) {
    final String name = context.string(value, path);
    if (!_anchorName.hasMatch(name)) {
      context.fail('Invalid schema anchor.', path);
    }
    return name;
  }

  OpenApiV32Type _type(Object? value, String path) {
    final String name = context.string(value, path);
    for (final OpenApiV32Type type in OpenApiV32Type.values) {
      if (type.wireName == name) {
        return type;
      }
    }
    context.fail('Unknown schema type.', path);
  }

  OpenApiV32SchemaType _schemaType(Object? value, String path) {
    if (value is! List<Object?>) {
      return OpenApiV32SingleType(_type(value, path));
    }
    final List<OpenApiV32Type> types = context.list(value, path, _type);
    if (types.isEmpty || types.toSet().length != types.length) {
      context.fail('Expected a nonempty array of distinct types.', path);
    }
    return OpenApiV32TypeSet(types);
  }

  ValueParser<List<OpenApiV32Schema>> _schemaArray(
    ValueParser<OpenApiV32Schema> read,
  ) => (value, path) {
    final List<OpenApiV32Schema> schemas = context.list(value, path, read);
    if (schemas.isEmpty) {
      context.fail('Expected at least one schema.', path);
    }
    return schemas;
  };

  List<String> _uniqueStrings(Object? value, String path) {
    final List<String> names = context.list(value, path, context.string);
    if (names.toSet().length != names.length) {
      context.fail('Expected unique strings.', path);
    }
    return names;
  }

  num _positive(Object? value, String path) {
    final num number = context.number(value, path);
    return number > 0
        ? number
        : context.fail('Expected a positive number.', path);
  }

  int _nonnegative(Object? value, String path) {
    final int count = context.integer(value, path);
    return count >= 0
        ? count
        : context.fail('Expected a nonnegative integer.', path);
  }

  OpenApiV32Discriminator _discriminator(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'defaultMapping',
      'propertyName',
      'mapping',
    });
    return OpenApiV32Discriminator(
      defaultMapping: reader.optional('defaultMapping', context.string),
      propertyName: reader.required('propertyName', context.string),
      mapping: reader.optional('mapping', mapOf(context.string)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV32Xml _xml(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'nodeType',
      'name',
      'namespace',
      'prefix',
      'attribute',
      'wrapped',
    });
    exclusiveFields(reader, 'nodeType', 'attribute');
    exclusiveFields(reader, 'nodeType', 'wrapped');
    return OpenApiV32Xml(
      nodeType: reader.optional(
        'nodeType',
        enumOf(OpenApiV32XmlNodeType.values),
      ),
      name: reader.optional('name', context.string),
      namespace: reader.optional('namespace', context.absoluteUri),
      prefix: reader.optional('prefix', context.string),
      attribute: reader.optional('attribute', context.boolean),
      wrapped: reader.optional('wrapped', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }
}
