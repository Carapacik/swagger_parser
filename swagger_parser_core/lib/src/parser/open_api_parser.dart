import 'package:swagger_parser_core/src/config/parse_config.dart';
import 'package:swagger_parser_core/src/exceptions/open_api_exception.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/read_document.dart';
import 'package:swagger_parser_core/src/source/schema_source.dart';

/// Parses Swagger 2.0, OpenAPI 3.0, 3.1, and 3.2 documents.
class const OpenApiParser({
  /// Options used when the caller supplies none.
  final ParseConfig config = const ParseConfig(),
}) {
  /// Uses [config] as the default for each parse call.
  this;

  /// Parses [source] into a document of its declared version.
  ///
  /// [config] replaces the parser defaults for this call.
  /// Throws [SchemaParseException] for malformed input.
  /// Throws [UnsupportedOpenApiVersionException] for an unsupported version.
  OpenApiDocument parse(SchemaSource source, {ParseConfig? config}) =>
      parseDocument(source, config: config ?? this.config);

  /// Decodes [source] with the selected [config] and reads its version.
  OpenApiDocument parseDocument(
    SchemaSource source, {
    required ParseConfig config,
  }) {
    final DecodedDocument decoded = const SourceDecoder().decode(
      source,
      config,
    );
    return readDocument(decoded, config);
  }
}
