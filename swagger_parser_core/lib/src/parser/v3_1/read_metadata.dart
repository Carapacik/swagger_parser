part of 'open_api_v3_1_document_parser.dart';

extension _MetadataReader on OpenApiV31DocumentParser {
  OpenApiV31Info _info(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'title',
      'version',
      'summary',
      'description',
      'termsOfService',
      'contact',
      'license',
    });
    return OpenApiV31Info(
      title: reader.required('title', context.string),
      summary: reader.optional('summary', context.string),
      version: reader.required('version', context.string),
      description: reader.optional('description', context.string),
      termsOfService: reader.optional('termsOfService', context.string),
      contact: reader.optional('contact', _contact),
      license: reader.optional('license', _license),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Contact _contact(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'url',
      'email',
    });
    return OpenApiV31Contact(
      name: reader.optional('name', context.string),
      url: reader.optional('url', context.string),
      email: reader.optional('email', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31License _license(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'url',
      'identifier',
    });
    exclusiveFields(reader, 'url', 'identifier');
    return OpenApiV31License(
      identifier: reader.optional('identifier', context.string),
      name: reader.required('name', context.string),
      url: reader.optional('url', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31ExternalDocumentation _externalDocumentation(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'url',
      'description',
    });
    return OpenApiV31ExternalDocumentation(
      url: reader.required('url', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Tag _tag(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'description',
      'externalDocs',
    });
    return OpenApiV31Tag(
      name: reader.required('name', context.string),
      description: reader.optional('description', context.string),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31Server _server(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'url',
      'description',
      'variables',
    });
    return OpenApiV31Server(
      url: reader.required('url', context.string),
      description: reader.optional('description', context.string),
      variables: reader.optional('variables', mapOf(_serverVariable)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV31ServerVariable _serverVariable(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'default',
      'enum',
      'description',
    });
    final String defaultValue = reader.required('default', context.string);
    final List<String>? options = reader.optional(
      'enum',
      listOf(context.string),
    );
    if (options != null && options.isEmpty) {
      failField(reader, 'enum', 'Expected at least one option.');
    }
    if (options != null && !options.contains(defaultValue)) {
      failField(reader, 'default', 'Expected a value from enum.');
    }
    return OpenApiV31ServerVariable(
      defaultValue: defaultValue,
      enumValues: options,
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }
}
