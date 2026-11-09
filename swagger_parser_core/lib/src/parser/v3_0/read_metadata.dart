part of 'open_api_v3_0_document_parser.dart';

extension _MetadataReader on OpenApiV30DocumentParser {
  OpenApiV30Info _info(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'title',
      'version',
      'description',
      'termsOfService',
      'contact',
      'license',
    });
    return OpenApiV30Info(
      title: reader.required('title', context.string),
      version: reader.required('version', context.string),
      description: reader.optional('description', context.string),
      termsOfService: reader.optional('termsOfService', context.string),
      contact: reader.optional('contact', _contact),
      license: reader.optional('license', _license),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Contact _contact(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'url',
      'email',
    });
    return OpenApiV30Contact(
      name: reader.optional('name', context.string),
      url: reader.optional('url', context.string),
      email: reader.optional('email', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30License _license(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {'name', 'url'});
    return OpenApiV30License(
      name: reader.required('name', context.string),
      url: reader.optional('url', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30ExternalDocumentation _externalDocumentation(
    Object? value,
    String path,
  ) {
    final reader = ObjectReader(context, value, path, const {
      'url',
      'description',
    });
    return OpenApiV30ExternalDocumentation(
      url: reader.required('url', context.string),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Tag _tag(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'name',
      'description',
      'externalDocs',
    });
    return OpenApiV30Tag(
      name: reader.required('name', context.string),
      description: reader.optional('description', context.string),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30Server _server(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'url',
      'description',
      'variables',
    });
    return OpenApiV30Server(
      url: reader.required('url', context.string),
      description: reader.optional('description', context.string),
      variables: reader.optional('variables', mapOf(_serverVariable)),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  OpenApiV30ServerVariable _serverVariable(Object? value, String path) {
    final reader = ObjectReader(context, value, path, const {
      'default',
      'enum',
      'description',
    });
    return OpenApiV30ServerVariable(
      defaultValue: reader.required('default', context.string),
      enumValues: reader.optional('enum', listOf(context.string)),
      description: reader.optional('description', context.string),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }
}
