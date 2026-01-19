import 'dart:io';
import 'package:swagger_parser/swagger_parser.dart';

/// Regenerate expected files for xof tests
/// Usage: dart run test/e2e/tests/xof/regenerate_all.dart [test_name]
/// If test_name is provided, only regenerate that test
/// If no test_name, regenerate all tests in the list
void main(List<String> args) async {
  final tests = <String, TestConfig>{
    'discriminated_one_of.3.0_mappable': TestConfig(
      schemaFile: 'discriminated_one_of.3.0.json',
      serializer: JsonSerializer.dartMappable,
      enumsToJson: true,
    ),
    'discriminated_any_of_complete_mapping': TestConfig(
      schemaFile: 'discriminated_any_of_complete_mapping.3.1.yaml',
      serializer: JsonSerializer.freezed,
    ),
    'discriminated_any_of_complete_mapping_json_serializable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.jsonSerializable,
    ),
    'discriminated_any_of_complete_mapping_mappable': TestConfig(
      schemaFile: 'discriminated_any_of_complete_mapping.3.1.yaml',
      serializer: JsonSerializer.dartMappable,
    ),
    'non_discriminated_one_of_deferred': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.freezed,
    ),
    'non_discriminated_one_of_deferred_mappable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.dartMappable,
    ),
    'non_discriminated_one_of_json_serializable': TestConfig(
      schemaFile: 'non_discriminated_one_of.3.0.json',
      serializer: JsonSerializer.jsonSerializable,
    ),
    'non_discriminated_any_of_deferred': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.freezed,
    ),
    'non_discriminated_any_of_deferred_json_serializable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.jsonSerializable,
    ),
    'non_discriminated_any_of_deferred_mappable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.dartMappable,
    ),
    'union_inline_and_refs_one_of_deferred': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.freezed,
    ),
    'union_inline_and_refs_one_of_deferred_json_serializable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.jsonSerializable,
    ),
    'union_inline_and_refs_one_of_deferred_mappable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.dartMappable,
    ),
    'union_inline_and_refs_any_of_deferred': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.freezed,
    ),
    'union_inline_and_refs_any_of_deferred_json_serializable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.jsonSerializable,
    ),
    'union_inline_and_refs_any_of_deferred_mappable': TestConfig(
      schemaFile: 'openapi.yaml',
      serializer: JsonSerializer.dartMappable,
    ),
    'fallback_union': TestConfig(
      schemaFile: 'fallback_union.json',
      serializer: JsonSerializer.freezed,
      fallbackUnion: 'unknown',
    ),
    'fallback_union_json_serializable': TestConfig(
      schemaFile: 'fallback_union.json',
      serializer: JsonSerializer.jsonSerializable,
      fallbackUnion: 'unknown',
    ),
    'fallback_union_mappable': TestConfig(
      schemaFile: 'fallback_union.json',
      serializer: JsonSerializer.dartMappable,
      fallbackUnion: 'unknown',
    ),
  };

  final testFilter = args.isNotEmpty ? args[0] : null;

  for (final entry in tests.entries) {
    if (testFilter != null && entry.key != testFilter) continue;

    final testName = entry.key;
    final config = entry.value;
    final basePath = 'test/e2e/tests/xof/$testName';
    final expectedPath = '$basePath/expected_files';

    print('Regenerating $testName...');

    // Delete existing expected files
    final dir = Directory(expectedPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }

    // Generate new files
    await GenProcessor(SWPConfig(
      outputDirectory: expectedPath,
      schemaPath: '$basePath/${config.schemaFile}',
      jsonSerializer: config.serializer,
      enumsToJson: config.enumsToJson,
      putClientsInFolder: true,
      includeIfNull: config.includeIfNull,
      fallbackUnion: config.fallbackUnion,
    )).generateFiles();
  }

  print('Done!');
}

class TestConfig {
  final String schemaFile;
  final JsonSerializer serializer;
  final bool enumsToJson;
  final bool includeIfNull;
  final String? fallbackUnion;

  TestConfig({
    required this.schemaFile,
    required this.serializer,
    this.enumsToJson = false,
    this.includeIfNull = true,
    this.fallbackUnion,
  });
}
