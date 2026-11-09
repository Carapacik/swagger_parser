import 'dart:convert';

import 'package:swagger_parser_core/src/exceptions/open_api_exception.dart';

/// The decoding mode for source text.
enum SchemaFormat() {
  /// Try JSON syntax first, then YAML.
  auto,

  /// Require JSON syntax.
  json,

  /// Use the YAML decoder.
  yaml,
}

/// In-memory JSON or YAML input for the parser.
final class const SchemaSource(
  /// JSON or YAML source text.
  final String content, {

  /// Decoder selection for the source text.
  final SchemaFormat format = SchemaFormat.auto,

  /// Retrieval URI, used for diagnostics and resolving relative references.
  final Uri? uri,
}) {
  /// Uses format detection unless the caller selects a format.
  this;

  /// Selects the strict JSON decoder for [content].
  const new json(String content, {Uri? uri})
    : this(content, format: SchemaFormat.json, uri: uri);

  /// Selects the YAML decoder for [content].
  const new yaml(String content, {Uri? uri})
    : this(content, format: SchemaFormat.yaml, uri: uri);

  /// Decodes UTF-8 bytes. Throws [SchemaParseException] for invalid UTF-8.
  factory fromBytes(
    List<int> bytes, {
    SchemaFormat format = SchemaFormat.auto,
    Uri? uri,
  }) {
    try {
      return SchemaSource(utf8.decode(bytes), format: format, uri: uri);
    } on FormatException catch (error) {
      throw SchemaParseException(
        'Invalid UTF-8 input.',
        sourceUri: uri,
        cause: error,
      );
    }
  }
}

/// Loads external sources by retrieval URI.
abstract interface class DocumentLoader() {
  /// Initializes a concrete subtype.
  this;

  /// Loads the source identified by the retrieval URI.
  Future<SchemaSource> load(Uri uri);
}
