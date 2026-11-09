import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/model/v3_2/open_api_v3_2_objects.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/object_reader.dart';
import 'package:swagger_parser_core/src/parser/open_api_3_reader.dart';
import 'package:swagger_parser_core/src/parser/schema_dialect.dart';
import 'package:swagger_parser_core/src/parser/uri_reference.dart';

part 'read_metadata.dart';
part 'read_paths.dart';
part 'read_payloads.dart';
part 'read_schema.dart';
part 'read_security.dart';

/// Reads the fixed fields and maps of an OpenAPI 3.2 document.
final class const OpenApiV32DocumentParser._(
  @override final ReadContext context,

  /// Dialect inherited by schema resource roots.
  final String defaultDialect,
) with OpenApi3Reader {
  /// Reads a typed document from decoded source fields.
  static OpenApiV32Document parse(
    ReadContext context,
    Map<String, Object?> value,
  ) {
    const path = '';
    final reader = ObjectReader(context, value, path, const {
      'openapi',
      r'$self',
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
    return OpenApiV32DocumentParser._(
      context,
      dialect ?? OpenApiV32Schema.oasDialect,
    )._document(reader, dialect);
  }

  OpenApiV32Document _document(ObjectReader reader, String? dialect) {
    return OpenApiV32Document(
      self: reader.optional(r'$self', _uriReference),
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

  String _uriReference(Object? value, String path) {
    final String text = context.string(value, path);
    if (parseUriReference(text) == null) {
      context.fail('Expected a URI reference.', path);
    }
    return text;
  }

  ValueParser<OpenApiV32RefOr<T>> _refOr<T extends OpenApiV32JsonSerializable>(
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
      return OpenApiV32Reference(
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
    return OpenApiV32Inline(parse(fields, path));
  };
}
