import 'dart:convert' show jsonDecode;

import 'package:yaml/yaml.dart';

import '../../../swagger_parser.dart';
import '../utils/case_utils.dart';

/// Class used to correct data class, method and field names in OpenAPI
class OpenApiCorrector {
  OpenApiCorrector(this.config);

  /// [ParserConfig] that [OpenApiParser] use
  final ParserConfig config;

  Map<String, dynamic> correct() {
    var fileContent = config.fileContent;

    final definitionFileContent = config.isJson
        ? jsonDecode(fileContent) as Map<String, dynamic>
        : (loadYaml(fileContent) as YamlMap).toMap();

    final components =
        definitionFileContent['components'] as Map<String, dynamic>?;
    final schemes = components?['schemas'] as Map<String, dynamic>?;

    if (schemes != null) {
      // Format all class names to PascalCase
      for (final type in schemes.keys) {
        final correctType = type.toPascal;
        if (correctType != type) {
          fileContent = fileContent.replaceAll(type, correctType);
        }
      }
    }

    return config.isJson
        ? jsonDecode(fileContent) as Map<String, dynamic>
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
