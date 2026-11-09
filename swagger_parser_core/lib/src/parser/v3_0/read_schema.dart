part of 'open_api_v3_0_document_parser.dart';

extension _SchemaReader on OpenApiV30DocumentParser {
  OpenApiV30Schema _schema(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'title',
      'description',
      'type',
      'format',
      'nullable',
      'default',
      'example',
      'enum',
      'multipleOf',
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
      'maxProperties',
      'minProperties',
      'required',
      'not',
      'allOf',
      'oneOf',
      'anyOf',
      'items',
      'properties',
      'additionalProperties',
      'discriminator',
      'readOnly',
      'writeOnly',
      'xml',
      'externalDocs',
      'deprecated',
    });
    _checkSchema(reader);
    return OpenApiV30Schema(
      title: reader.optional('title', context.string),
      description: reader.optional('description', context.string),
      type: reader.optional('type', enumOf(OpenApiV30Type.values)),
      format: reader.optional('format', context.string),
      nullable: reader.optional('nullable', context.boolean),
      defaultValue: reader.optional('default', context.jsonValue),
      example: reader.optional('example', context.jsonValue),
      enumValues: reader.optional('enum', listOf(context.jsonValue)),
      multipleOf: reader.optional('multipleOf', context.number),
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
      maxProperties: reader.optional('maxProperties', context.integer),
      minProperties: reader.optional('minProperties', context.integer),
      requiredProperties: reader.optional('required', listOf(context.string)),
      not: reader.optional('not', _refOr(_schema)),
      allOf: reader.optional('allOf', listOf(_refOr(_schema))),
      oneOf: reader.optional('oneOf', listOf(_refOr(_schema))),
      anyOf: reader.optional('anyOf', listOf(_refOr(_schema))),
      items: reader.optional('items', _refOr(_schema)),
      properties: reader.optional('properties', mapOf(_refOr(_schema))),
      additionalProperties: reader.optional(
        'additionalProperties',
        _additionalProperties,
      ),
      discriminator: reader.optional('discriminator', _discriminator),
      readOnly: reader.optional('readOnly', context.boolean),
      writeOnly: reader.optional('writeOnly', context.boolean),
      xml: reader.optional('xml', _xml),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      deprecated: reader.optional('deprecated', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Discriminator _discriminator(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'propertyName',
      'mapping',
    }, allowExtensions: false);
    return OpenApiV30Discriminator(
      propertyName: reader.required('propertyName', context.string),
      mapping: reader.optional('mapping', mapOf(context.string)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Xml _xml(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'namespace',
      'prefix',
      'attribute',
      'wrapped',
    });
    return OpenApiV30Xml(
      name: reader.optional('name', context.string),
      namespace: reader.optional('namespace', context.string),
      prefix: reader.optional('prefix', context.string),
      attribute: reader.optional('attribute', context.boolean),
      wrapped: reader.optional('wrapped', context.boolean),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30AdditionalProperties _additionalProperties(
    Object? value,
    String path,
  ) => value is bool
      ? OpenApiV30AdditionalPropertiesAllowed(allowed: value)
      : OpenApiV30AdditionalPropertiesSchema(_refOr(_schema)(value, path));

  void _checkSchema(ObjectReader reader) {
    if (reader.fields['type'] == 'array' &&
        !reader.fields.containsKey('items')) {
      failField(reader, 'items', 'Array schemas require items.');
    }
    if (reader.fields.containsKey('default') &&
        reader.fields.containsKey('type')) {
      final OpenApiV30Type type = reader.required(
        'type',
        enumOf(OpenApiV30Type.values),
      );
      final Object? value = reader.fields['default'];
      final bool matches = value == null
          ? reader.fields['nullable'] == true
          : switch (type) {
              OpenApiV30Type.string => value is String,
              OpenApiV30Type.boolean => value is bool,
              OpenApiV30Type.integer =>
                value is int ||
                    (value is double && value == value.truncateToDouble()),
              OpenApiV30Type.number => value is num,
              OpenApiV30Type.array => value is List<Object?>,
              OpenApiV30Type.object => value is Map<String, Object?>,
            };
      if (!matches) {
        failField(
          reader,
          'default',
          'Expected a default of the declared type.',
        );
      }
    }
    if (reader.fields['readOnly'] == true &&
        reader.fields['writeOnly'] == true) {
      failField(reader, 'writeOnly', 'Choose readOnly or writeOnly.');
    }
    for (final key in const [
      'maxLength',
      'minLength',
      'maxItems',
      'minItems',
      'maxProperties',
      'minProperties',
    ]) {
      final int? bound = reader.optional(key, context.integer);
      if (bound != null && bound < 0) {
        failField(reader, key, 'Expected a nonnegative integer.');
      }
    }
    final num? multiple = reader.optional('multipleOf', context.number);
    if (multiple != null && multiple <= 0) {
      failField(reader, 'multipleOf', 'Expected a positive number.');
    }
    for (final key in const ['enum', 'required', 'allOf', 'oneOf', 'anyOf']) {
      final Object? values = reader.fields[key];
      if (values is List<Object?> && values.isEmpty) {
        failField(reader, key, 'Expected a nonempty array.');
      }
    }
    final Object? required = reader.fields['required'];
    if (required is List<Object?> &&
        required.toSet().length != required.length) {
      failField(reader, 'required', 'Expected unique property names.');
    }
  }
}
