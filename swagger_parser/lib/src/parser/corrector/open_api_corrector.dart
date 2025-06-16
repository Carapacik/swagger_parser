import 'dart:convert' show json;

import 'package:yaml/yaml.dart';

import '../../../swagger_parser.dart';
import '../utils/case_utils.dart';

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
    final correctModelMap = <String, String>{};

    if (models != null) {
      // Apply replacement rules to all class names and format to PascalCase
      for (final type in models.keys) {
        var correctType = type;

        for (final rule in config.replacementRules) {
          correctType = rule.apply(correctType)!;
        }

        correctType = correctType.toPascal;

        if (correctType != type) {
          String escape(String input) => input.replaceAllMapped(
                RegExp(r'[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]'),
                (m) =>
                    // Add a backslash before each special character
                    '\\${m[0]}',
              );

          // Escape all special characters for regular expressions
          final urlEncodedType = escape(Uri.encodeComponent(type));
          final escapedType = escape(type);

          fileContent = fileContent.replaceAllMapped(
            RegExp(
                '["\']#/(definitions|components/schemas)/($escapedType|$urlEncodedType)["\']'),
            (match) => match[0]!
                .replaceFirst(match[2]!, correctType, match[1]!.length + 4),
          );

          correctModelMap[type] = correctType;
        }
      }
    }

    final updatedSchemaMap = config.isJson
        ? json.decode(fileContent) as Map<String, dynamic>
        : (loadYaml(fileContent) as YamlMap).toMap();

    if (correctModelMap.isNotEmpty) {
      // OpenAPI 3.0 and 3.1
      final components =
          updatedSchemaMap['components'] as Map<String, dynamic>?;
      final schemes = components?['schemas'] as Map<String, dynamic>?;
      // OpenAPI 2.0
      final definitions =
          updatedSchemaMap['definitions'] as Map<String, dynamic>?;
      final models = schemes ?? definitions;

      final updatedModels = models?.map((key, value) {
        final updatedKey = correctModelMap[key] ?? key;
        return MapEntry(updatedKey, value);
      });

      if (updatedModels != null) {
        if (components != null) {
          components['schemas'] = updatedModels;
        } else {
          updatedSchemaMap['definitions'] = updatedModels;
        }
      }
    }

    return updatedSchemaMap;
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
