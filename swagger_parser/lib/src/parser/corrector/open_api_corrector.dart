import 'dart:convert' show json;

import 'package:swagger_parser/src/parser/model/normalized_identifier.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:yaml/yaml.dart';

/// Class used to correct data class, method and field names in OpenAPI
class OpenApiCorrector {
  /// Creates a [OpenApiCorrector].
  const OpenApiCorrector(this.config);

  /// [ParserConfig] that [OpenApiParser] use
  final ParserConfig config;

  /// Corrects the OpenAPI definition file content
  Map<String, dynamic> correct() {
    var fileContent = config.fileContent;

    final definitionFileContent = config.isJson
        ? json.decode(fileContent) as Map<String, dynamic>
        : (loadYaml(fileContent) as YamlMap).toMap();

    // OpenAPI 3.0 and 3.1
    final components =
        definitionFileContent['components'] as Map<String, dynamic>?;
    final schemes = components?['schemas'] as Map<String, dynamic>?;
    // OpenAPI 2.0
    final definitions =
        definitionFileContent['definitions'] as Map<String, dynamic>?;

    final models = schemes ?? definitions;

    if (models != null) {
      // Pre-compute type corrections map once
      final typeCorrections = <String, String>{};
      for (final type in models.keys) {
        var correctType = type;
        for (final rule in config.replacementRules) {
          correctType = rule.apply(correctType)!;
        }
        correctType = correctType.toPascal;
        if (correctType != type) {
          typeCorrections[type] = correctType;
        }
      }

      // If no corrections needed, skip the expensive block processing
      if (typeCorrections.isNotEmpty) {
        fileContent = _applyCorrections(fileContent, models, typeCorrections);
      }
    }

    return config.isJson
        ? json.decode(fileContent) as Map<String, dynamic>
        : (loadYaml(fileContent) as YamlMap).toMap();
  }

  String _applyCorrections(
    String fileContent,
    Map<String, dynamic> models,
    Map<String, String> typeCorrections,
  ) {
    // BUGFIX: Protect properties blocks and API path definitions by detecting
    // their range and replacing with placeholders
    final blocks =
        <({int start, int end, String placeholder, String original})>[];

    // Detect lines starting with 'properties:' and their indentation level
    final propertiesPattern = RegExp(
      r'^([ \t]*)(properties:)\s*$',
      multiLine: true,
    );

    // Detect API path definition lines (e.g., "  /api/v1/app/user_point_balance:")
    final pathPattern = RegExp(
      r'^([ \t]*)(/[^\s:]+:)\s*$',
      multiLine: true,
    );

    for (final match in propertiesPattern.allMatches(fileContent)) {
      final indent = match[1]!;
      final indentLength = indent.length;
      final matchStart = match.start;
      final matchEnd = match.end;

      // Find the block end by detecting the next key with same or shallower
      // indentation
      var blockEnd = matchEnd;
      final lines = fileContent.substring(matchEnd).split('\n');

      for (var i = 1; i < lines.length; i++) {
        final line = lines[i];

        // Skip empty lines
        if (line.trim().isEmpty) {
          blockEnd += line.length + 1; // +1 for \n
          continue;
        }

        // Check indentation level
        final lineIndent = line.length - line.trimLeft().length;

        // Block ends when a key with same or shallower indentation is found
        if (lineIndent <= indentLength && line.trimLeft().isNotEmpty) {
          break;
        }

        blockEnd += line.length + 1; // +1 for \n
      }

      // Get the entire properties block
      final originalBlock = fileContent.substring(matchStart, blockEnd);

      // Generate placeholder
      final placeholder = '${indent}___PROPERTIES_BLOCK_${blocks.length}___';

      blocks.add((
        start: matchStart,
        end: blockEnd,
        placeholder: placeholder,
        original: originalBlock,
      ));
    }

    // Detect and protect API path definitions
    for (final match in pathPattern.allMatches(fileContent)) {
      final indent = match[1]!;
      final matchStart = match.start;
      final matchEnd = match.end;

      // API path definitions are single lines
      final originalPath = fileContent.substring(matchStart, matchEnd);

      // Generate placeholder
      final placeholder = '${indent}___PATH_DEFINITION_${blocks.length}___';

      blocks.add((
        start: matchStart,
        end: matchEnd,
        placeholder: placeholder,
        original: originalPath,
      ));
    }

    // Sort blocks by start position
    blocks.sort((a, b) => a.start.compareTo(b.start));

    // Check for duplicate blocks and exclude them
    final validBlocks =
        <({int start, int end, String placeholder, String original})>[];
    for (var i = 0; i < blocks.length; i++) {
      final block = blocks[i];
      var isValid = true;

      // Check if this block is completely contained within another block
      for (var j = 0; j < blocks.length; j++) {
        if (i != j) {
          final other = blocks[j];
          // Skip if block is completely contained within other
          if (block.start >= other.start && block.end <= other.end) {
            isValid = false;
            break;
          }
        }
      }

      if (isValid) {
        validBlocks.add(block);
      }
    }

    // Reconstruct string with placeholders using StringBuffer
    final placeholderBuf = StringBuffer();
    var lastEnd = 0;
    // Build a map from placeholder to block for fast lookup during restore
    final placeholderToBlock =
        <String, ({int start, int end, String placeholder, String original})>{};

    for (final block in validBlocks) {
      placeholderBuf.write(fileContent.substring(lastEnd, block.start));
      placeholderBuf.write(block.placeholder);
      placeholderToBlock[block.placeholder] = block;
      lastEnd = block.end;
    }
    placeholderBuf.write(fileContent.substring(lastEnd));
    fileContent = placeholderBuf.toString();

    // Apply replacement rules to all class names and format to PascalCase
    // (properties blocks are already replaced with placeholders)
    for (final entry in typeCorrections.entries) {
      final type = entry.key;
      final correctType = entry.value;

      // Escape all special characters for regular expressions
      final escapedType = type.replaceAllMapped(
        RegExp(r'[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]'),
        (m) =>
            // Add a backslash before each special character
            '\\${m[0]}',
      );

      // Replace schema names (properties blocks are already replaced with
      // placeholders)
      final replacementPattern = RegExp('[ "\'/]$escapedType[ "\':]');

      fileContent = fileContent.replaceAllMapped(
        replacementPattern,
        (match) => match[0]!.replaceAll(type, correctType),
      );
    }

    // Build a single combined regex for all type corrections to use in
    // properties blocks. This replaces the O(blocks * models) nested loop
    // with O(blocks) single-regex passes.
    final refReplacementPattern = _buildCombinedRefPattern(typeCorrections);

    // Restore blocks from placeholders in a single pass
    // Convert $ref schema names within properties blocks while preserving
    // property names. API path definitions are restored without conversion.
    final resultBuf = StringBuffer();
    var searchStart = 0;

    for (final block in validBlocks) {
      final placeholder = block.placeholder;
      final idx = fileContent.indexOf(placeholder, searchStart);
      if (idx == -1) continue;

      // Write everything before the placeholder
      resultBuf.write(fileContent.substring(searchStart, idx));

      var restoredBlock = block.original;

      // Only convert $ref in properties blocks, not in API path definitions
      if (!placeholder.contains('___PATH_DEFINITION_') &&
          refReplacementPattern != null) {
        restoredBlock = restoredBlock.replaceAllMapped(
          refReplacementPattern,
          (match) {
            final fullMatch = match[0]!;
            // Extract the schema name from the $ref path
            // The captured group is the schema name
            final schemaName = match[1]!;
            final correctType = typeCorrections[schemaName];
            if (correctType != null) {
              return fullMatch.replaceAll(schemaName, correctType);
            }
            return fullMatch;
          },
        );
      }

      resultBuf.write(restoredBlock);
      searchStart = idx + placeholder.length;
    }

    // Write remaining content after the last placeholder
    resultBuf.write(fileContent.substring(searchStart));

    return resultBuf.toString();
  }

  /// Build a single regex that matches any $ref or discriminator mapping value
  /// containing any of the types that need correction.
  RegExp? _buildCombinedRefPattern(Map<String, String> typeCorrections) {
    if (typeCorrections.isEmpty) return null;

    // Escape each type for use in regex, sort by length descending so longer
    // names match first (prevents partial matches)
    final escapedTypes = typeCorrections.keys.map((type) {
      return type.replaceAllMapped(
        RegExp(r'[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]'),
        (m) => '\\${m[0]}',
      );
    }).toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final alternation = escapedTypes.join('|');

    // Match $ref or discriminator mapping values that reference any of the
    // types. Captures the schema name in group 1.
    return RegExp(
      '(?:\\\$ref:|\\w+):\\s*[\'"]#/[^\'"]*/(${alternation})[\'"]',
    );
  }
}

/// Extension used for [YamlMap]
extension YamlMapX on YamlMap {
  /// Convert [YamlMap] to Dart map
  Map<String, Object?> toMap() {
    final map = <String, Object?>{};
    for (final entry in entries) {
      if (entry.value is YamlMap || entry.value is Map) {
        map[entry.key.toString()] = (entry.value as YamlMap).toMap();
      } else if (entry.value is YamlList) {
        map[entry.key.toString()] = (entry.value as YamlList)
            .map<Object?>((e) => e is YamlMap ? e.toMap() : e)
            .toList(growable: false);
      } else {
        map[entry.key.toString()] = entry.value.toString();
      }
    }
    return map;
  }
}
