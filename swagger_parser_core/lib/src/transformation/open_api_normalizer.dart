import 'package:swagger_parser_core/src/config/normalize_config.dart';
import 'package:swagger_parser_core/src/config/parse_config.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/model/parameter_serialization.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/read_document.dart';
import 'package:swagger_parser_core/src/traversal/document_node.dart';

/// Normalizes a parsed document in its declared OpenAPI version.
interface class const OpenApiNormalizer({
  final NormalizeConfig _config = const NormalizeConfig(),
}) {
  /// Applies the configured rules to the entry document.
  this;

  /// Returns a new immutable document of the same type and patch version.
  T normalize<T extends OpenApiDocument>(T document) {
    final Map<String, Object?> root = document.toJson();
    if (_config.explicitParameterSerialization) {
      _writeParameterSerialization(
        DocumentNode(NodeKind.document, root, ''),
        document.version.family,
      );
    }
    final decoded = DecodedDocument(root, const {}, null);
    return readDocument(decoded, const ParseConfig()) as T;
  }

  static void _writeParameterSerialization(
    DocumentNode node,
    OpenApiFamily family,
  ) {
    for (final DocumentNode child in node.children(family)) {
      if (child.kind == NodeKind.parameter) {
        final Map<String, Object?> fields = child.fields;
        fields.addAll(
          ParameterSerialization.effective(family, fields).toJson(),
        );
      } else if (child.kind
          case NodeKind.pathItem || NodeKind.operation || NodeKind.callback) {
        _writeParameterSerialization(child, family);
      }
    }
  }
}
