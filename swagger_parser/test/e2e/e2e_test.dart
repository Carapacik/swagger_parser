import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';

import 'e2e_util.dart';

void main() {
  group('E2E', () {
    test('enum_member_names', () async {
      await e2eTest(
        'enum_member_names',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          enumsParentPrefix: false,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('enum_types_list', () async {
      await e2eTest(
        'enum_types_list',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          enumsParentPrefix: false,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });
    test('multipart_request_properties', () async {
      await e2eTest(
        'multipart_request_properties',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.json',
      );
    });

    test('multipart_request_with_ref', () async {
      await e2eTest(
        'multipart_request_with_ref',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    // https://github.com/Carapacik/swagger_parser/issues/223
    test('corrector', () async {
      await e2eTest(
        'corrector',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          replacementRules: [
            ReplacementRule(pattern: RegExp('V1'), replacement: ''),
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'DTO'),
          ],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    // https://github.com/Carapacik/swagger_parser/issues/224
    // https://github.com/Carapacik/swagger_parser/issues/214
    test('request_unnamed_types', () async {
      await e2eTest(
        'request_unnamed_types',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.json',
      );
    });

    test('nullable_types', () async {
      await e2eTest(
        'nullable_types',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          generateValidator: true,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    }, skip: true);

    test('nullable_types.2.0', () async {
      await e2eTest(
        'nullable_types.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'swagger.yaml',
      );
    });

    test('no_required_params', () async {
      await e2eTest(
        'no_required_params',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });
  });

  group('basic', () {
    test('additional_properties_class.2.0', () async {
      await e2eTest(
        'basic/additional_properties_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'additional_properties_class.2.0.json',
      );
    });

    test('additional_properties_class.3.0', () async {
      await e2eTest(
        'basic/additional_properties_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'additional_properties_class.3.0.json',
      );
    });

    test('all_of.3.0', () async {
      await e2eTest(
        'basic/all_of.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'all_of.3.0.json',
      );
    });

    test('basic_requests.2.0', () async {
      await e2eTest(
        'basic/basic_requests.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'basic_requests.2.0.json',
      );
    });

    test('basic_requests.3.0', () async {
      await e2eTest(
        'basic/basic_requests.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'basic_requests.3.0.json',
      );
    });

    test('basic_types_class.2.0', () async {
      await e2eTest(
        'basic/basic_types_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'basic_types_class.2.0.json',
      );
    });

    test('basic_types_class.3.0', () async {
      await e2eTest(
        'basic/basic_types_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'basic_types_class.3.0.json',
      );
    });

    test('discriminated_one_of.3.0', () async {
      await e2eTest(
        'basic/discriminated_one_of.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'discriminated_one_of.3.0.json',
      );
    });

    test('fallback_union', () async {
      await e2eTest(
        'basic/fallback_union',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          fallbackUnion: 'unknown',
        ),
        schemaFileName: 'fallback_union.json',
      );
    });

    test('discriminated_one_of.3.0_mappable', () async {
      await e2eTest(
        'basic/discriminated_one_of.3.0_mappable',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.dartMappable,
          enumsToJson: true,
          putClientsInFolder: true,
        ),
        schemaFileName: 'discriminated_one_of.3.0.json',
      );
    });

    test('empty_class.2.0', () async {
      await e2eTest(
        'basic/empty_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'empty_class.2.0.json',
      );
    });

    test('empty_class.3.0', () async {
      await e2eTest(
        'basic/empty_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'empty_class.3.0.json',
      );
    });

    test('query_parameters', () async {
      await e2eTest(
        'basic/query_parameters',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('enum_class', () async {
      await e2eTest(
        'basic/enum_class',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'enum_class.json',
      );
    });

    test('of_like_class.3.1', () async {
      await e2eTest(
        'basic/of_like_class.3.1',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'of_like_class.3.1.json',
      );
    });

    test('file_download', () async {
      await e2eTest(
        'basic/file_download',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('reference_types_class.2.0', () async {
      await e2eTest(
        'basic/reference_types_class.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'reference_types_class.2.0.json',
      );
    });

    test('reference_types_class.3.0', () async {
      await e2eTest(
        'basic/reference_types_class.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'reference_types_class.3.0.json',
      );
    });

    test('replacement_rules.2.0', () async {
      await e2eTest(
        'basic/replacement_rules.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          putClientsInFolder: true,
          useXNullable: true,
          replacementRules: [
            ReplacementRule(pattern: RegExp('List'), replacement: 'Lizt'),
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'DTO'),
          ],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('replacement_rules.3.1', () async {
      await e2eTest(
        'basic/replacement_rules.3.1',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          replacementRules: [
            ReplacementRule(pattern: RegExp('V1'), replacement: ''),
            ReplacementRule(pattern: RegExp(r'$'), replacement: 'DTO'),
          ],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('tags', () async {
      await e2eTest(
        'basic/tags',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('empty_tags', () async {
      await e2eTest(
        'basic/empty_tags',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          fallbackClient: 'test',
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('excluded_tags', () async {
      await e2eTest(
        'basic/excluded_tags',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          excludeTags: ['exclude'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('included_tags', () async {
      await e2eTest(
        'basic/included_tags',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          includeTags: ['include'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('included_and_excluded_tags', () async {
      await e2eTest(
        'basic/included_and_excluded_tags',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          includeTags: ['include'],
          excludeTags: ['exclude'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('included_tags_with_schemas', () async {
      await e2eTest(
        'basic/included_tags_with_schemas',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          includeTags: ['include'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('excluded_tags_with_schemas', () async {
      await e2eTest(
        'basic/excluded_tags_with_schemas',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          excludeTags: ['exclude'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('circular_deps_with_tags', () async {
      await e2eTest(
        'basic/circular_deps_with_tags',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          includeTags: ['include'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('include_exclude_tags_with_schemas', () async {
      await e2eTest(
        'basic/include_exclude_tags_with_schemas',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          includeTags: ['include'],
          excludeTags: ['exclude'],
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('use_freezed3.3.0', () async {
      await e2eTest(
        'basic/use_freezed3.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useFreezed3: true,
        ),
        schemaFileName: 'use_freezed3.3.0.json',
      );
    });

    test('deprecated', () async {
      await e2eTest(
        'basic/deprecated',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useFreezed3: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('wrapping_collections.2.0', () async {
      await e2eTest(
        'basic/wrapping_collections.2.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
          useXNullable: true,
        ),
        schemaFileName: 'wrapping_collections.2.0.json',
      );
    });

    test('wrapping_collections.3.0', () async {
      await e2eTest(
        'basic/wrapping_collections.3.0',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'wrapping_collections.3.0.json',
      );
    });

    // https://github.com/Carapacik/swagger_parser/issues/353
    test('tag_with_alphanumeric', () async {
      await e2eTest(
        'tag_with_alphanumeric',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.json',
      );
    });

    test('tag_edge_cases', () async {
      await e2eTest(
        'tag_edge_cases',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });
  });

  group('casing', () {
    test('camelCase', () async {
      await e2eTest(
        'casing/camelCase',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('kebab-case', () async {
      await e2eTest(
        'casing/kebab-case',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('PascalCase', () async {
      await e2eTest(
        'casing/PascalCase',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('SCREAMING_SNAKE_CASE', () async {
      await e2eTest(
        'casing/SCREAMING_SNAKE_CASE',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('SCREAMING-KEBAB-CASE', () async {
      await e2eTest(
        'casing/SCREAMING-KEBAB-CASE',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('snake_case', () async {
      await e2eTest(
        'casing/snake_case',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('Train-Case', () async {
      await e2eTest(
        'casing/Train-Case',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });
  });

  group('xof', () {
    test('discriminated_any_of_complete_mapping', () async {
      await e2eTest(
        'xof/discriminated_any_of_complete_mapping',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('non_discriminated_one_of_deferred', () async {
      await e2eTest(
        'xof/non_discriminated_one_of_deferred',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('non_discriminated_any_of_deferred', () async {
      await e2eTest(
        'xof/non_discriminated_any_of_deferred',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('union_inline_and_refs_any_of_deferred', () async {
      await e2eTest(
        'xof/union_inline_and_refs_any_of_deferred',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('union_inline_and_refs_one_of_deferred', () async {
      await e2eTest(
        'xof/union_inline_and_refs_one_of_deferred',
        (outputDirectory, schemaPath) => SWPConfig(
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          putClientsInFolder: true,
        ),
        schemaFileName: 'openapi.yaml',
      );
    });

    test('merged_outputs', () async {
      await e2eTest(
        'basic/merged_outputs',
        (outputDirectory, schemaPath) => SWPConfig(
          name: 'merged_outputs',
          outputDirectory: outputDirectory,
          schemaPath: schemaPath,
          jsonSerializer: JsonSerializer.freezed,
          useXNullable: true,
          mergeOutputs: true,
        ),
        schemaFileName: 'merged_outputs.json',
      );
    });
  });
}
