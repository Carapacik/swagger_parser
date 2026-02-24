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
      // BUGFIX: Protect properties blocks and API path definitions by detecting their range and replacing with placeholders
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

        // Find the block end by detecting the next key with same or shallower indentation
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

      // Detect and protect API path definitions (e.g., "  /api/v1/app/user_point_balance:")
      for (final match in pathPattern.allMatches(fileContent)) {
        final indent = match[1]!;
        final matchStart = match.start;
        final matchEnd = match.end;

        // API path definitions are single lines, so we just protect the entire line
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

      // Reconstruct string from back to front
      var result = '';
      var lastEnd = fileContent.length;

      for (var i = validBlocks.length - 1; i >= 0; i--) {
        final block = validBlocks[i];

        // Add the part after the block
        result = fileContent.substring(block.end, lastEnd) + result;

        // Add placeholder
        result = block.placeholder + result;

        lastEnd = block.start;
      }

      // Add the first part
      result = fileContent.substring(0, lastEnd) + result;

      fileContent = result;

      // Apply replacement rules to all class names and format to PascalCase
      for (final type in models.keys) {
        var correctType = type;

        for (final rule in config.replacementRules) {
          correctType = rule.apply(correctType)!;
        }

        correctType = correctType.toPascal;

        if (correctType != type) {
          // Escape all special characters for regular expressions
          final escapedType = type.replaceAllMapped(
            RegExp(r'[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]'),
            (m) =>
                // Add a backslash before each special character
                '\\${m[0]}',
          );

          // Replace schema names (properties blocks are already replaced with placeholders)
          final replacementPattern = RegExp('[ "\'/]$escapedType[ "\':]');

          fileContent = fileContent.replaceAllMapped(
            replacementPattern,
            (match) => match[0]!.replaceAll(type, correctType),
          );
        }
      }

      // Restore blocks from placeholders
      // Convert $ref schema names within properties blocks while preserving property names
      // API path definitions are restored without any conversion
      for (final block in validBlocks) {
        final placeholder = block.placeholder;
        var restoredBlock = block.original;

        // Only convert $ref in properties blocks, not in API path definitions
        if (!placeholder.contains('___PATH_DEFINITION___')) {
          // Convert schema names in $ref within the block
          // Uses same pattern as original code (handles 'schemes' typo as well)
          for (final type in models.keys) {
            var correctType = type;

            for (final rule in config.replacementRules) {
              correctType = rule.apply(correctType)!;
            }

            correctType = correctType.toPascal;

            if (correctType != type) {
              // Escape all special characters for regular expressions
              final escapedType = type.replaceAllMapped(
                RegExp(r'[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]'),
                (m) => '\\${m[0]}',
              );

              // In properties blocks, convert $ref values and
              // discriminator mapping values (not property names)
              restoredBlock = restoredBlock.replaceAllMapped(
                RegExp(
                  '(?:\\\$ref:|\\w+):\\s*[\'"]#/[^\'"]*/$escapedType[\'"]',
                ),
                (match) => match[0]!.replaceAll(type, correctType),
              );
            }
          }
        }

        fileContent = fileContent.replaceAll(placeholder, restoredBlock);
      }
    }

    return config.isJson
        ? json.decode(fileContent) as Map<String, dynamic>
        : (loadYaml(fileContent) as YamlMap).toMap();
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
