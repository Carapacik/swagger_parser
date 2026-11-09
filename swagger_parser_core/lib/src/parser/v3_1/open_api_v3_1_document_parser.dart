import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/model/v3_1/open_api_v3_1_objects.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/object_reader.dart';
import 'package:swagger_parser_core/src/parser/open_api_3_reader.dart';
import 'package:swagger_parser_core/src/parser/schema_dialect.dart';

part 'read_metadata.dart';
part 'read_paths.dart';
part 'read_payloads.dart';
part 'read_schema.dart';
part 'read_security.dart';

/// Reads the fixed fields and maps of an OpenAPI 3.1 document.
final class const OpenApiV31DocumentParser._(
  @override final ReadContext context,

  /// Dialect inherited by schema resource roots.
  final String defaultDialect,
) with OpenApi3Reader {
  /// Reads a typed document from decoded source fields.
  static OpenApiV31Document parse(
    ReadContext context,
    Map<String, Object?> value,
  ) {
    const path = '';
    final reader = ObjectReader(context, value, path, const {
      'openapi',
      'jsonSchemaDialect',
      'webhooks',
      'info',
      'paths',
      'servers',
      'components',
      'security',
      'tags',
      'externalDocs',
    });
    if (!const ['paths', 'components', 'webhooks'].any(value.containsKey)) {
      context.fail('Expected paths, components, or webhooks.', path);
    }
    final String? dialect = reader.optional(
      'jsonSchemaDialect',
      context.absoluteUri,
    );
    return OpenApiV31DocumentParser._(
      context,
      dialect ?? OpenApiV31Schema.oasDialect,
    )._document(reader, dialect);
  }

  OpenApiV31Document _document(ObjectReader reader, String? dialect) {
    return OpenApiV31Document(
      jsonSchemaDialect: dialect,
      webhooks: reader.optional('webhooks', mapOf(_pathItem)),
      openapi: reader.required('openapi', context.string),
      info: reader.required('info', _info),
      paths: reader.optional('paths', _paths),
      servers: reader.optional('servers', listOf(_server)),
      components: reader.optional('components', _components),
      security: reader.optional('security', listOf(_securityRequirement)),
      tags: reader.optional('tags', listOf(_tag)),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  ValueParser<OpenApiV31RefOr<T>> _refOr<T extends OpenApiV31JsonSerializable>(
    ValueParser<T> parse,
  ) => (value, path) {
    final Map<String, Object?> fields = objectFields(value, path);
    if (fields.containsKey(r'$ref')) {
      final String ref = context.string(
        fields[r'$ref'],
        appendPointer(path, r'$ref'),
      );
      final reference = ObjectReader(
        context,
        fields,
        path,
        fields.keys.toSet(),
      );
      return OpenApiV31Reference(
        ref,
        summary: reference.optional('summary', context.string),
        description: reference.optional('description', context.string),
        ignoredFields: {
          for (final entry in fields.entries)
            if (!const {r'$ref', 'summary', 'description'}.contains(entry.key))
              entry.key: JsonValue(entry.value),
        },
      );
    }
    return OpenApiV31Inline(parse(fields, path));
  };
}
