import 'package:swagger_parser_core/src/model/json_value.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/v3_0/open_api_v3_0_objects.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/object_reader.dart';
import 'package:swagger_parser_core/src/parser/open_api_3_reader.dart';

part 'read_metadata.dart';
part 'read_paths.dart';
part 'read_payloads.dart';
part 'read_schema.dart';
part 'read_security.dart';

/// Reads the fixed fields and maps of an OpenAPI 3.0 document.
final class const OpenApiV30DocumentParser(@override final ReadContext context)
    with OpenApi3Reader {
  /// Uses the source positions and options in [context].
  this;

  /// Reads a typed document from decoded source fields.
  OpenApiV30Document parse(Map<String, Object?> value) {
    const path = '';
    final reader = ObjectReader(context, value, path, const {
      'openapi',
      'info',
      'paths',
      'servers',
      'components',
      'security',
      'tags',
      'externalDocs',
    });
    return OpenApiV30Document(
      openapi: reader.required('openapi', context.string),
      info: reader.required('info', _info),
      paths: reader.required('paths', _paths),
      servers: reader.optional('servers', listOf(_server)),
      components: reader.optional('components', _components),
      security: reader.optional('security', listOf(_securityRequirement)),
      tags: reader.optional('tags', listOf(_tag)),
      externalDocs: reader.optional('externalDocs', _externalDocumentation),
      extensions: reader.extensions,
      extraFields: reader.extras,
    );
  }

  ValueParser<OpenApiV30RefOr<T>> _refOr<T extends OpenApiV30JsonSerializable>(
    ValueParser<T> parse,
  ) => (value, path) {
    final Map<String, Object?> fields = objectFields(value, path);
    if (fields.containsKey(r'$ref')) {
      final String ref = context.string(
        fields[r'$ref'],
        appendPointer(path, r'$ref'),
      );
      return OpenApiV30Reference(
        ref,
        ignoredFields: {
          for (final entry in fields.entries)
            if (entry.key != r'$ref') entry.key: JsonValue(entry.value),
        },
      );
    }
    return OpenApiV30Inline(parse(fields, path));
  };
}
