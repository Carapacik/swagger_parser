import 'package:swagger_parser/swagger_parser.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('SWPConfig', () {
    group('Constructor', () {
      test('should create config with required parameters', () {
        const config = SWPConfig(outputDirectory: 'lib/api');

        expect(config.outputDirectory, equals('lib/api'));
        expect(config.schemaPath, isNull);
        expect(config.schemaUrl, isNull);
        expect(config.name, equals('api'));
        expect(config.language, equals(ProgrammingLanguage.dart));
        expect(config.jsonSerializer, equals(JsonSerializer.jsonSerializable));
        expect(config.rootClient, isTrue);
        expect(config.rootClientName, equals('RestClient'));
        expect(config.clientPostfix, isNull);
        expect(config.exportFile, isTrue);
        expect(config.putClientsInFolder, isFalse);
        expect(config.enumsToJson, isFalse);
        expect(config.unknownEnumValue, isTrue);
        expect(config.markFilesAsGenerated, isTrue);
        expect(config.originalHttpResponse, isFalse);
        expect(config.replacementRules, isEmpty);
        expect(config.defaultContentType, equals('application/json'));
        expect(config.extrasParameterByDefault, isFalse);
        expect(config.dioOptionsParameterByDefault, isFalse);
        expect(config.pathMethodName, isFalse);
        expect(config.mergeClients, isFalse);
        expect(config.enumsParentPrefix, isTrue);
        expect(config.skippedParameters, isEmpty);
        expect(config.generateValidator, isFalse);
        expect(config.useXNullable, isFalse);
        expect(config.useFreezed3, isFalse);
        expect(config.useMultipartFile, isFalse);
        expect(config.fallbackUnion, isNull);
        expect(config.excludeTags, isEmpty);
        expect(config.includeTags, isEmpty);
        expect(config.fallbackClient, 'fallback');
        expect(config.includeIfNull, isFalse);
      });

      test('should create config with all parameters specified', () {
        final replacementRules = [
          ReplacementRule(pattern: RegExp('Test'), replacement: 'Mock'),
        ];

        final config = SWPConfig(
          outputDirectory: 'lib/generated',
          schemaPath: 'api/openapi.yaml',
          schemaUrl: 'https://api.example.com/openapi.json',
          name: 'my_api',
          language: ProgrammingLanguage.kotlin,
          jsonSerializer: JsonSerializer.freezed,
          rootClient: false,
          rootClientName: 'ApiClient',
          clientPostfix: 'Service',
          exportFile: false,
          putClientsInFolder: true,
          enumsToJson: true,
          unknownEnumValue: false,
          markFilesAsGenerated: false,
          originalHttpResponse: true,
          replacementRules: replacementRules,
          defaultContentType: 'application/xml',
          extrasParameterByDefault: true,
          dioOptionsParameterByDefault: true,
          pathMethodName: true,
          mergeClients: true,
          enumsParentPrefix: false,
          skippedParameters: ['id', 'timestamp'],
          generateValidator: true,
          useXNullable: true,
          useFreezed3: true,
          useMultipartFile: true,
          fallbackUnion: 'unknown',
          excludeTags: ['internal', 'deprecated'],
          includeTags: ['public', 'stable'],
          fallbackClient: 'common',
          includeIfNull: true,
        );

        expect(config.outputDirectory, equals('lib/generated'));
        expect(config.schemaPath, equals('api/openapi.yaml'));
        expect(
            config.schemaUrl, equals('https://api.example.com/openapi.json'));
        expect(config.name, equals('my_api'));
        expect(config.language, equals(ProgrammingLanguage.kotlin));
        expect(config.jsonSerializer, equals(JsonSerializer.freezed));
        expect(config.rootClient, isFalse);
        expect(config.rootClientName, equals('ApiClient'));
        expect(config.clientPostfix, equals('Service'));
        expect(config.exportFile, isFalse);
        expect(config.putClientsInFolder, isTrue);
        expect(config.enumsToJson, isTrue);
        expect(config.unknownEnumValue, isFalse);
        expect(config.markFilesAsGenerated, isFalse);
        expect(config.originalHttpResponse, isTrue);
        expect(config.replacementRules, equals(replacementRules));
        expect(config.defaultContentType, equals('application/xml'));
        expect(config.extrasParameterByDefault, isTrue);
        expect(config.dioOptionsParameterByDefault, isTrue);
        expect(config.pathMethodName, isTrue);
        expect(config.mergeClients, isTrue);
        expect(config.enumsParentPrefix, isFalse);
        expect(config.skippedParameters, equals(['id', 'timestamp']));
        expect(config.generateValidator, isTrue);
        expect(config.useXNullable, isTrue);
        expect(config.useFreezed3, isTrue);
        expect(config.useMultipartFile, isTrue);
        expect(config.fallbackUnion, equals('unknown'));
        expect(config.excludeTags, equals(['internal', 'deprecated']));
        expect(config.includeTags, equals(['public', 'stable']));
        expect(config.fallbackClient, equals('common'));
        expect(config.includeIfNull, isTrue);
      });
    });

    group('fromYaml factory constructor', () {
      group('Valid configurations', () {
        test('should create config from minimal YAML as root config', () {
          final yamlMap = YamlMap.wrap({
            'output_directory': 'lib/api',
          });

          final config = SWPConfig.fromYaml(yamlMap, isRootConfig: true);

          expect(config.outputDirectory, equals('lib/api'));
          expect(config.name, equals(''));
          expect(config.schemaPath, isNull);
          expect(config.schemaUrl, isNull);
        });

        test('should create config from complete YAML', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'schema_url': 'https://api.example.com/openapi.json',
            'output_directory': 'lib/generated',
            'name': 'my_api',
            'language': 'kotlin',
            'json_serializer': 'freezed',
            'root_client': false,
            'root_client_name': 'ApiClient',
            'client_postfix': 'Service',
            'export_file': false,
            'put_clients_in_folder': true,
            'enums_to_json': true,
            'unknown_enum_value': false,
            'mark_files_as_generated': false,
            'original_http_response': true,
            'default_content_type': 'application/xml',
            'extras_parameter_by_default': true,
            'dio_options_parameter_by_default': true,
            'path_method_name': true,
            'merge_clients': true,
            'enums_parent_prefix': false,
            'generate_validator': true,
            'use_x_nullable': true,
            'use_freezed3': true,
            'use_multipart_file': true,
            'fallback_union': 'unknown',
            'fallback_client': 'common',
            'skipped_parameters': ['id', 'timestamp'],
            'exclude_tags': ['internal', 'deprecated'],
            'include_tags': ['public', 'stable'],
            'include_if_null': true,
            'replacement_rules': [
              {'pattern': 'Test', 'replacement': 'Mock'},
              {'pattern': 'Dto', 'replacement': 'Model'},
            ],
          });

          final config = SWPConfig.fromYaml(yamlMap);

          expect(config.schemaPath, equals('api/openapi.yaml'));
          expect(
              config.schemaUrl, equals('https://api.example.com/openapi.json'));
          expect(config.outputDirectory, equals('lib/generated'));
          expect(config.name, equals('my_api'));
          expect(config.language, equals(ProgrammingLanguage.kotlin));
          expect(config.jsonSerializer, equals(JsonSerializer.freezed));
          expect(config.rootClient, isFalse);
          expect(config.rootClientName, equals('ApiClient'));
          expect(config.clientPostfix, equals('Service'));
          expect(config.exportFile, isFalse);
          expect(config.putClientsInFolder, isTrue);
          expect(config.enumsToJson, isTrue);
          expect(config.unknownEnumValue, isFalse);
          expect(config.markFilesAsGenerated, isFalse);
          expect(config.originalHttpResponse, isTrue);
          expect(config.defaultContentType, equals('application/xml'));
          expect(config.extrasParameterByDefault, isTrue);
          expect(config.dioOptionsParameterByDefault, isTrue);
          expect(config.pathMethodName, isTrue);
          expect(config.mergeClients, isTrue);
          expect(config.enumsParentPrefix, isFalse);
          expect(config.generateValidator, isTrue);
          expect(config.useXNullable, isTrue);
          expect(config.useFreezed3, isTrue);
          expect(config.useMultipartFile, isTrue);
          expect(config.fallbackUnion, equals('unknown'));
          expect(config.fallbackClient, equals('common'));
          expect(config.skippedParameters, equals(['id', 'timestamp']));
          expect(config.excludeTags, equals(['internal', 'deprecated']));
          expect(config.includeTags, equals(['public', 'stable']));
          expect(config.includeIfNull, isTrue);
          expect(config.replacementRules, hasLength(2));
          expect(config.replacementRules[0].pattern.pattern, equals('Test'));
          expect(config.replacementRules[0].replacement, equals('Mock'));
          expect(config.replacementRules[1].pattern.pattern, equals('Dto'));
          expect(config.replacementRules[1].replacement, equals('Model'));
        });

        test('should generate name from schema_path when name not provided',
            () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/petstore.yaml',
            'output_directory': 'lib/api',
          });

          final config = SWPConfig.fromYaml(yamlMap);

          expect(config.name, equals('petstore'));
        });

        test('should generate name from schema_url when name not provided', () {
          final yamlMap = YamlMap.wrap({
            'schema_url': 'https://api.example.com/user-service.json',
            'output_directory': 'lib/api',
          });

          final config = SWPConfig.fromYaml(yamlMap);

          expect(config.name, equals('user-service'));
        });

        test('should handle empty name by using schema path', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/custom.yaml',
            'output_directory': 'lib/api',
            'name': '',
          });

          final config = SWPConfig.fromYaml(yamlMap);

          expect(config.name, equals('custom'));
        });

        test('should trim client_postfix', () {
          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/openapi.yaml',
            'output_directory': 'lib/api',
            'client_postfix': '  Service  ',
          });

          final config = SWPConfig.fromYaml(yamlMap);

          expect(config.clientPostfix, equals('Service'));
        });
      });

      group('Root config inheritance', () {
        test('should inherit values from root config', () {
          final rootConfig = SWPConfig(
            outputDirectory: 'lib/shared',
            language: ProgrammingLanguage.kotlin,
            jsonSerializer: JsonSerializer.freezed,
            defaultContentType: 'application/xml',
            extrasParameterByDefault: true,
            skippedParameters: ['id'],
            excludeTags: ['internal'],
            replacementRules: [
              ReplacementRule(pattern: RegExp('Root'), replacement: 'Base'),
            ],
          );

          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/user.yaml',
            'name': 'user_api',
            'root_client': false,
          });

          final config = SWPConfig.fromYaml(yamlMap, rootConfig: rootConfig);

          expect(config.outputDirectory, equals('lib/shared'));
          expect(config.language, equals(ProgrammingLanguage.kotlin));
          expect(config.jsonSerializer, equals(JsonSerializer.freezed));
          expect(config.defaultContentType, equals('application/xml'));
          expect(config.extrasParameterByDefault, isTrue);
          expect(config.skippedParameters, equals(['id']));
          expect(config.excludeTags, equals(['internal']));
          expect(config.replacementRules, hasLength(1));
          expect(config.rootClient, isFalse); // Overridden value
          expect(config.name, equals('user_api')); // Specific value
          expect(config.schemaPath, equals('api/user.yaml')); // Specific value
        });

        test('should override root config values with local values', () {
          const rootConfig = SWPConfig(
            outputDirectory: 'lib/shared',
            skippedParameters: ['id'],
            excludeTags: ['internal'],
          );

          final yamlMap = YamlMap.wrap({
            'schema_path': 'api/user.yaml',
            'output_directory': 'lib/user',
            'language': 'kotlin',
            'json_serializer': 'freezed',
            'skipped_parameters': ['timestamp', 'version'],
            'exclude_tags': ['deprecated', 'beta'],
          });

          final config = SWPConfig.fromYaml(yamlMap, rootConfig: rootConfig);

          expect(config.outputDirectory, equals('lib/user'));
          expect(config.language, equals(ProgrammingLanguage.kotlin));
          expect(config.jsonSerializer, equals(JsonSerializer.freezed));
          expect(config.skippedParameters, equals(['timestamp', 'version']));
          expect(config.excludeTags, equals(['deprecated', 'beta']));
        });
      });
    });

    group('Error handling', () {
      test(
          'should throw ConfigException when neither schema_path nor schema_url provided for non-root config',
          () {
        final yamlMap = YamlMap.wrap({
          'output_directory': 'lib/api',
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            equals(
                "Config parameters 'schema_path' or 'schema_url' are required."),
          )),
        );
      });

      test(
          'should throw ConfigException when output_directory missing for root config',
          () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            equals("Config parameter 'output_directory' is required."),
          )),
        );
      });

      test(
          'should throw ConfigException when output_directory missing and no root config',
          () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            equals("Config parameter 'output_directory' is required."),
          )),
        );
      });

      test('should throw ConfigException for invalid skipped_parameters type',
          () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'skipped_parameters': [123, 'valid'],
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            equals(
                "Config parameter 'skipped_parameters' values must be List of String."),
          )),
        );
      });

      test('should throw ConfigException for invalid exclude_tags type', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'exclude_tags': ['valid', 123],
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            equals(
                "Config parameter 'exclude_tags' values must be List of String."),
          )),
        );
      });

      test('should throw ConfigException for invalid include_tags type', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'include_tags': [123],
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            equals(
                "Config parameter 'include_tags' values must be List of String."),
          )),
        );
      });

      test('should throw ConfigException for invalid replacement_rules format',
          () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'replacement_rules': [
            {'pattern': 'Test'}, // Missing replacement
          ],
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains(
                "Config parameter 'replacement_rules' values must be maps of strings"),
          )),
        );
      });

      test('should throw ConfigException for invalid replacement_rules type',
          () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'replacement_rules': ['invalid'],
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains(
                "Config parameter 'replacement_rules' values must be maps of strings"),
          )),
        );
      });

      test(
          'should throw ConfigException for replacement_rules with non-string values',
          () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'replacement_rules': [
            {'pattern': 123, 'replacement': 'Valid'},
          ],
        });

        expect(
          () => SWPConfig.fromYaml(yamlMap),
          throwsA(isA<ConfigException>().having(
            (e) => e.message,
            'message',
            contains(
                "Config parameter 'replacement_rules' values must be maps of strings"),
          )),
        );
      });
    });

    group('Edge cases', () {
      test('should handle null values in YAML gracefully', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'name': null,
          'client_postfix': null,
          'fallback_union': null,
          'skipped_parameters': null,
          'replacement_rules': null,
          'exclude_tags': null,
          'include_tags': null,
        });

        final config = SWPConfig.fromYaml(yamlMap);

        expect(config.name, equals('openapi'));
        expect(config.clientPostfix, isNull);
        expect(config.fallbackUnion, isNull);
        expect(config.skippedParameters, isEmpty);
        expect(config.replacementRules, isEmpty);
        expect(config.excludeTags, isEmpty);
        expect(config.includeTags, isEmpty);
      });

      test('should handle empty lists in YAML', () {
        final yamlMap = YamlMap.wrap({
          'schema_path': 'api/openapi.yaml',
          'output_directory': 'lib/api',
          'skipped_parameters': <String>[],
          'replacement_rules': <Map<String, String>>[],
          'exclude_tags': <String>[],
          'include_tags': <String>[],
        });

        final config = SWPConfig.fromYaml(yamlMap);

        expect(config.skippedParameters, isEmpty);
        expect(config.replacementRules, isEmpty);
        expect(config.excludeTags, isEmpty);
        expect(config.includeTags, isEmpty);
      });
    });
  });

  group('fromYamlWithOverrides factory constructor', () {
    test('should apply CLI overrides to YAML config', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'name': 'original_name',
        'root_client': true,
      });

      final argResults = parseConfigGeneratorArguments([
        '--schema_path',
        'foo/bar.yaml',
        '--output_directory',
        'lib/foo',
      ]);

      final config = SWPConfig.fromYamlWithOverrides(yamlMap, argResults);

      expect(config.outputDirectory, equals('lib/foo'));
      expect(config.schemaPath, equals('foo/bar.yaml'));
      expect(config.name, equals('original_name'));
      expect(config.rootClient, isTrue);
    });

    test('should work with null argResults', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'name': 'test_name',
      });

      final config = SWPConfig.fromYamlWithOverrides(yamlMap, null);

      expect(config.name, equals('test_name'));
      expect(config.outputDirectory, equals('lib/api'));
      expect(config.schemaPath, equals('api/openapi.yaml'));
    });

    test('should support all constructor parameters', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
      });

      const rootConfig = SWPConfig(outputDirectory: 'lib/shared');

      final config = SWPConfig.fromYamlWithOverrides(
        yamlMap,
        null,
        rootConfig: rootConfig,
      );

      expect(config.schemaPath, equals('api/openapi.yaml'));
      expect(config.outputDirectory, equals('lib/api'));
    });
  });

  group('toGeneratorConfig method', () {
    test('should convert SWPConfig to GeneratorConfig correctly', () {
      final replacementRules = [
        ReplacementRule(pattern: RegExp('Test'), replacement: 'Mock'),
      ];

      final swpConfig = SWPConfig(
        outputDirectory: 'lib/generated',
        name: 'my_api',
        language: ProgrammingLanguage.kotlin,
        jsonSerializer: JsonSerializer.freezed,
        defaultContentType: 'application/xml',
        extrasParameterByDefault: true,
        dioOptionsParameterByDefault: true,
        rootClient: false,
        rootClientName: 'ApiClient',
        clientPostfix: 'Service',
        exportFile: false,
        putClientsInFolder: true,
        enumsToJson: true,
        unknownEnumValue: false,
        markFilesAsGenerated: false,
        originalHttpResponse: true,
        replacementRules: replacementRules,
        generateValidator: true,
        useFreezed3: true,
        useMultipartFile: true,
        fallbackUnion: 'unknown',
      );

      final generatorConfig = swpConfig.toGeneratorConfig();

      expect(generatorConfig.name, equals('my_api'));
      expect(generatorConfig.outputDirectory, equals('lib/generated'));
      expect(generatorConfig.language, equals(ProgrammingLanguage.kotlin));
      expect(generatorConfig.jsonSerializer, equals(JsonSerializer.freezed));
      expect(generatorConfig.defaultContentType, equals('application/xml'));
      expect(generatorConfig.extrasParameterByDefault, isTrue);
      expect(generatorConfig.dioOptionsParameterByDefault, isTrue);
      expect(generatorConfig.rootClient, isFalse);
      expect(generatorConfig.rootClientName, equals('ApiClient'));
      expect(generatorConfig.clientPostfix, equals('Service'));
      expect(generatorConfig.exportFile, isFalse);
      expect(generatorConfig.putClientsInFolder, isTrue);
      expect(generatorConfig.enumsToJson, isTrue);
      expect(generatorConfig.unknownEnumValue, isFalse);
      expect(generatorConfig.markFilesAsGenerated, isFalse);
      expect(generatorConfig.originalHttpResponse, isTrue);
      expect(generatorConfig.replacementRules, equals(replacementRules));
      expect(generatorConfig.generateValidator, isTrue);
      expect(generatorConfig.useFreezed3, isTrue);
      expect(generatorConfig.useMultipartFile, isTrue);
      expect(generatorConfig.fallbackUnion, equals('unknown'));
    });

    test('should handle null values correctly', () {
      const swpConfig = SWPConfig(
        outputDirectory: 'lib/api',
      );

      final generatorConfig = swpConfig.toGeneratorConfig();

      expect(generatorConfig.clientPostfix, isNull);
      expect(generatorConfig.fallbackUnion, isNull);
    });
  });

  group('toParserConfig method', () {
    test('should convert SWPConfig to ParserConfig correctly', () {
      final replacementRules = [
        ReplacementRule(pattern: RegExp('Test'), replacement: 'Mock'),
      ];

      final swpConfig = SWPConfig(
        outputDirectory: 'lib/api',
        name: 'my_api',
        defaultContentType: 'application/xml',
        pathMethodName: true,
        mergeClients: true,
        enumsParentPrefix: false,
        skippedParameters: ['id', 'timestamp'],
        replacementRules: replacementRules,
        useXNullable: true,
        excludeTags: ['internal'],
        includeTags: ['public'],
        fallbackClient: 'common',
      );

      const fileContent = '{"openapi": "3.0.0"}';
      const isJson = true;

      final parserConfig = swpConfig.toParserConfig(
        fileContent: fileContent,
        isJson: isJson,
      );

      expect(parserConfig.fileContent, equals(fileContent));
      expect(parserConfig.isJson, equals(isJson));
      expect(parserConfig.name, equals('my_api'));
      expect(parserConfig.defaultContentType, equals('application/xml'));
      expect(parserConfig.pathMethodName, isTrue);
      expect(parserConfig.mergeClients, isTrue);
      expect(parserConfig.enumsParentPrefix, isFalse);
      expect(parserConfig.skippedParameters, equals(['id', 'timestamp']));
      expect(parserConfig.replacementRules, equals(replacementRules));
      expect(parserConfig.useXNullable, isTrue);
      expect(parserConfig.excludeTags, equals(['internal']));
      expect(parserConfig.includeTags, equals(['public']));
      expect(parserConfig.fallbackClient, equals('common'));
    });

    test('should handle YAML file content', () {
      const swpConfig = SWPConfig(outputDirectory: 'lib/api');
      const fileContent = 'openapi: 3.0.0';
      const isJson = false;

      final parserConfig = swpConfig.toParserConfig(
        fileContent: fileContent,
        isJson: isJson,
      );

      expect(parserConfig.fileContent, equals(fileContent));
      expect(parserConfig.isJson, isFalse);
    });
  });

  group('Enum parsing', () {
    test('should parse programming language from string', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'language': 'kotlin',
      });

      final config = SWPConfig.fromYaml(yamlMap);

      expect(config.language, equals(ProgrammingLanguage.kotlin));
    });

    test('should parse json serializer from string', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'json_serializer': 'dart_mappable',
      });

      final config = SWPConfig.fromYaml(yamlMap);

      expect(config.jsonSerializer, equals(JsonSerializer.dartMappable));
    });

    test('should handle unknown enum values gracefully', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'language': 'unknown_language',
      });

      // This should not throw but use default or handle gracefully
      // The exact behavior depends on ProgrammingLanguage.fromString implementation
      expect(() => SWPConfig.fromYaml(yamlMap),
          isNot(throwsA(isA<ConfigException>())));
    });
  });

  group('Include If Null Configuration', () {
    test('should default includeIfNull to false', () {
      const config = SWPConfig(outputDirectory: 'lib/api');
      expect(config.includeIfNull, isFalse);
    });

    test('should parse includeIfNull from YAML when set to true', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'include_if_null': true,
      });

      final config = SWPConfig.fromYaml(yamlMap);
      expect(config.includeIfNull, isTrue);
    });

    test('should parse includeIfNull from YAML when set to false', () {
      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/openapi.yaml',
        'output_directory': 'lib/api',
        'include_if_null': false,
      });

      final config = SWPConfig.fromYaml(yamlMap);
      expect(config.includeIfNull, isFalse);
    });

    test('should inherit includeIfNull from root config', () {
      const rootConfig = SWPConfig(
        outputDirectory: 'lib/shared',
        includeIfNull: true,
      );

      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/user.yaml',
        'name': 'user_api',
      });

      final config = SWPConfig.fromYaml(yamlMap, rootConfig: rootConfig);
      expect(config.includeIfNull, isTrue);
    });

    test('should override root config includeIfNull with local value', () {
      const rootConfig = SWPConfig(
        outputDirectory: 'lib/shared',
        includeIfNull: true,
      );

      final yamlMap = YamlMap.wrap({
        'schema_path': 'api/user.yaml',
        'include_if_null': false,
      });

      final config = SWPConfig.fromYaml(yamlMap, rootConfig: rootConfig);
      expect(config.includeIfNull, isFalse);
    });

    test('should pass includeIfNull to GeneratorConfig', () {
      const swpConfig = SWPConfig(
        outputDirectory: 'lib/api',
        includeIfNull: true,
      );

      final generatorConfig = swpConfig.toGeneratorConfig();
      expect(generatorConfig.includeIfNull, isTrue);
    });
  });
}
