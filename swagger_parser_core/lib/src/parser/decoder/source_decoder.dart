import 'dart:convert';

import 'package:source_span/source_span.dart' as spans;
import 'package:swagger_parser_core/src/config/parse_config.dart';
import 'package:swagger_parser_core/src/exceptions/open_api_exception.dart';
import 'package:swagger_parser_core/src/source/schema_source.dart';
import 'package:swagger_parser_core/src/source/source_location.dart';
import 'package:yaml/yaml.dart';

part 'json_source_index.dart';

/// Appends a key to a JSON Pointer and escapes `~` and `/`.
String appendPointer(String path, String key) =>
    '$path/${key.replaceAll('~', '~0').replaceAll('/', '~1')}';

/// The decoded JSON value and its source positions.
final class const DecodedDocument(
  /// The root value after JSON or YAML decoding.
  final Object? value,

  /// Source positions indexed by JSON Pointer.
  final Map<String, SourceLocation> locations,

  /// URI of the source document, when available.
  final Uri? sourceUri,
) {
  /// Associates a decoded value with its source positions.
  this;
}

/// Decodes JSON or YAML and records positions by JSON Pointer.
final class const SourceDecoder() {
  /// Creates a decoder for in-memory JSON and YAML.
  this;

  /// Decodes the text and records positions when requested.
  DecodedDocument decode(SchemaSource source, ParseConfig config) {
    if (config.maxDepth < 1) {
      throw ArgumentError.value(
        config.maxDepth,
        'maxDepth',
        'Must be positive',
      );
    }
    final String text = source.content;
    try {
      if (source.format == SchemaFormat.json) {
        return _JsonSourceIndex(source, config).index(jsonDecode(text));
      } else if (source.format == SchemaFormat.auto) {
        try {
          return _JsonSourceIndex(source, config).index(jsonDecode(text));
        } on FormatException {
          // YAML also permits flow mappings and sequences.
        }
      }
      final YamlNode root = loadYamlNode(text, sourceUrl: source.uri);
      final locations = <String, SourceLocation>{};
      final active = Set<YamlNode>.identity();
      Object? visit(YamlNode node, String path, int depth) {
        final spans.SourceLocation position = node.span.start;
        final location = SourceLocation(
          line: position.line + 1,
          column: position.column + 1,
          offset: position.offset,
        );
        Never fail(String message) => throw SchemaParseException(
          message,
          sourceUri: source.uri,
          documentPath: path,
          location: config.captureSourceLocations ? location : null,
        );
        if (depth > config.maxDepth) {
          fail('Maximum nesting depth exceeded.');
        }
        if (!active.add(node)) {
          fail('Cyclic YAML aliases are not supported.');
        }
        if (config.captureSourceLocations) {
          locations[path] = location;
        }
        try {
          if (node is YamlMap) {
            final result = <String, Object?>{};
            for (final MapEntry<dynamic, YamlNode> entry
                in node.nodes.entries) {
              final keyNode = entry.key as YamlNode;
              final Object? key = keyNode.value;
              if (key is! String) {
                fail('Object keys must be strings.');
              }
              if (result.containsKey(key)) {
                fail('Duplicate object key: $key.');
              }
              result[key] = visit(
                entry.value,
                appendPointer(path, key),
                depth + 1,
              );
            }
            return result;
          }
          if (node is YamlList) {
            return [
              for (var i = 0; i < node.nodes.length; i++)
                visit(node.nodes[i], '$path/$i', depth + 1),
            ];
          }
          final Object? value = node.value;
          if (value == null ||
              value is String ||
              value is bool ||
              (value is num && value.isFinite)) {
            return value;
          }
          fail('Expected a finite JSON value.');
        } finally {
          active.remove(node);
        }
      }

      final Object? value = visit(root, '', 0);
      return DecodedDocument(value, locations, source.uri);
    } on YamlException catch (error) {
      final spans.SourceLocation? position = error.span?.start;
      throw SchemaParseException(
        error.message,
        sourceUri: source.uri,
        documentPath: '',
        location: config.captureSourceLocations && position != null
            ? SourceLocation(
                line: position.line + 1,
                column: position.column + 1,
                offset: position.offset,
              )
            : null,
        cause: error,
      );
    } on FormatException catch (error) {
      throw SchemaParseException(
        error.message,
        sourceUri: source.uri,
        documentPath: '',
        location: config.captureSourceLocations && error.offset != null
            ? _locationAt(text, error.offset!)
            : null,
        cause: error,
      );
    }
  }

  SourceLocation _locationAt(String text, int offset) {
    var line = 1;
    var column = 1;
    for (var i = 0; i < offset; i++) {
      final int unit = text.codeUnitAt(i);
      if (unit == 13 ||
          (unit == 10 && (i == 0 || text.codeUnitAt(i - 1) != 13))) {
        line++;
        column = 1;
      } else if (unit != 10) {
        column++;
      }
    }
    return SourceLocation(line: line, column: column, offset: offset);
  }
}
