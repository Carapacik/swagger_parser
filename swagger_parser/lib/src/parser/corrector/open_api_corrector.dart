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

    final components =
        definitionFileContent['components'] as Map<String, dynamic>?;
    final schemes = components?['schemas'] as Map<String, dynamic>?;

    if (schemes != null) {
      // Apply replacement rules to all class names and format to PascalCase
      for (final type in schemes.keys) {
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

          fileContent = fileContent.replaceAllMapped(
            RegExp('[ "\'/]$escapedType[ "\':]'),
            (match) => match[0]!.replaceAll(type, correctType),
          );
        }
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
