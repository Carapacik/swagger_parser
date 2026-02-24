import 'package:args/args.dart';
import 'package:swagger_parser/src/config/config_exception.dart';
import 'package:swagger_parser/src/generator/config/generator_config.dart';
import 'package:swagger_parser/src/generator/model/field_parser.dart';
import 'package:swagger_parser/src/generator/model/json_serializer.dart';
import 'package:swagger_parser/src/generator/model/programming_language.dart';
import 'package:swagger_parser/src/parser/swagger_parser_core.dart';
import 'package:yaml/yaml.dart';

/// Swagger Parser Config
class SWPConfig {
  /// Creates a [SWPConfig].
  const SWPConfig({
    required this.outputDirectory,
    this.schemaPath,
    this.schemaUrl,
    this.name = 'api',
    this.language = ProgrammingLanguage.dart,
    this.jsonSerializer = JsonSerializer.jsonSerializable,
    this.rootClient = true,
    this.rootClientName = 'RestClient',
    this.clientPostfix,
    this.exportFile = true,
    this.putClientsInFolder = false,
    this.enumsToJson = false,
    this.unknownEnumValue = true,
    this.markFilesAsGenerated = true,
    this.originalHttpResponse = false,
    this.replacementRules = const [],
    this.replacementRulesForRawSchema = const [],
    this.defaultContentType = 'application/json',
    this.extrasParameterByDefault = false,
    this.dioOptionsParameterByDefault = false,
    this.addOpenApiMetadata = false,
    this.pathMethodName = false,
    this.mergeClients = false,
    this.enumsParentPrefix = true,
    this.skippedParameters = const <String>[],
    this.generateValidator = false,
    this.useXNullable = false,
    this.useFreezed3 = false,
    this.useMultipartFile = false,
    this.fallbackUnion,
    this.dartMappableConvenientWhen = false,
    this.useDartMappableNaming = false,
    this.excludeTags = const <String>[],
    this.includeTags = const <String>[],
    this.includePaths,
    this.fallbackClient = 'fallback',
    this.mergeOutputs = false,
    this.includeIfNull = false,
    this.inferRequiredFromNullable = false,
    this.useFlutterCompute = false,
    this.generateUrlsConstants = false,
    this.fieldParsers = const [],
  });

  /// Internal constructor of [SWPConfig]
  const SWPConfig._({
    required this.outputDirectory,
    required this.schemaPath,
    required this.schemaUrl,
    required this.name,
    required this.language,
    required this.jsonSerializer,
    required this.rootClient,
    required this.rootClientName,
    required this.clientPostfix,
    required this.exportFile,
    required this.putClientsInFolder,
    required this.enumsToJson,
    required this.unknownEnumValue,
    required this.markFilesAsGenerated,
    required this.originalHttpResponse,
    required this.replacementRules,
    required this.replacementRulesForRawSchema,
    required this.defaultContentType,
    required this.extrasParameterByDefault,
    required this.dioOptionsParameterByDefault,
    required this.addOpenApiMetadata,
    required this.pathMethodName,
    required this.mergeClients,
    required this.enumsParentPrefix,
    required this.skippedParameters,
    required this.generateValidator,
    required this.useXNullable,
    required this.useFreezed3,
    required this.useMultipartFile,
    required this.excludeTags,
    required this.includeTags,
    required this.includePaths,
    required this.fallbackClient,
    required this.mergeOutputs,
    required this.dartMappableConvenientWhen,
    required this.useDartMappableNaming,
    required this.includeIfNull,
    required this.inferRequiredFromNullable,
    required this.useFlutterCompute,
    required this.generateUrlsConstants,
    required this.fieldParsers,
    this.fallbackUnion,
  });

  /// Creates a [SWPConfig] from [YamlMap].
  factory SWPConfig.fromYaml(
    YamlMap yamlMap, {
    bool isRootConfig = false,
    SWPConfig? rootConfig,
  }) {
    final schemaPath =
        yamlMap['schema_path']?.toString() ?? rootConfig?.schemaPath;

    final schemaUrl =
        yamlMap['schema_url']?.toString() ?? rootConfig?.schemaUrl;
    if (schemaUrl != null) {
      final uri = Uri.tryParse(schemaUrl);
      if (uri == null) {
        throw const ConfigException(
          "Config parameter 'schema_url' must be valid URL.",
        );
      }
    }

    if (!isRootConfig && schemaPath == null && schemaUrl == null) {
      throw const ConfigException(
        "Config parameters 'schema_path' or 'schema_url' are required.",
      );
    }

    var outputDirectory =
        yamlMap['output_directory']?.toString() ?? rootConfig?.outputDirectory;
    if (isRootConfig && outputDirectory == null) {
      outputDirectory = '';
    }
    if (outputDirectory == null) {
      if (rootConfig == null) {
        throw const ConfigException(
          "Config parameter 'output_directory' is required.",
        );
      } else if (rootConfig.outputDirectory == '') {
        throw ConfigException(
          "Config parameter 'output_directory' for $schemaPath was not found.\n"
          "Add the 'output_directory' parameter under 'swagger_parser:' or set it for each schema.",
        );
      }
      outputDirectory = rootConfig.outputDirectory;
    }

    final rawName = yamlMap['name']?.toString();
    final name = rawName == null || rawName.isEmpty
        ? (schemaPath ?? schemaUrl ?? '').split('/').last.split('.').first
        : rawName;

    final defaultContentType = yamlMap['default_content_type'] as String? ??
        rootConfig?.defaultContentType;
    final extrasParameterByDefault =
        yamlMap['extras_parameter_by_default'] as bool? ??
            rootConfig?.extrasParameterByDefault;
    final dioOptionsParameterByDefault =
        yamlMap['dio_options_parameter_by_default'] as bool? ??
            rootConfig?.dioOptionsParameterByDefault;
    final addOpenApiMetadata = yamlMap['add_openapi_metadata'] as bool? ??
        rootConfig?.addOpenApiMetadata;
    final pathMethodName =
        yamlMap['path_method_name'] as bool? ?? rootConfig?.pathMethodName;
    final mergeClients =
        yamlMap['merge_clients'] as bool? ?? rootConfig?.mergeClients;
    final enumsParentPrefix = yamlMap['enums_parent_prefix'] as bool? ??
        rootConfig?.enumsParentPrefix;

    final rawSkippedParameters = yamlMap['skipped_parameters'] as YamlList?;
    List<String>? skippedParameters;
    if (rawSkippedParameters != null) {
      skippedParameters = [];
      for (final p in rawSkippedParameters) {
        if (p is! String) {
          throw const ConfigException(
            "Config parameter 'skipped_parameters' values must be List of String.",
          );
        }
        skippedParameters.add(p);
      }
    } else if (rootConfig?.skippedParameters != null) {
      skippedParameters = List.from(rootConfig!.skippedParameters);
    }

    final rawLanguage = yamlMap['language']?.toString();
    final language = rawLanguage == null
        ? rootConfig?.language
        : ProgrammingLanguage.fromString(rawLanguage);

    JsonSerializer? jsonSerializer;
    final rawJsonSerializer = yamlMap['json_serializer']?.toString();
    if (rawJsonSerializer != null) {
      jsonSerializer = JsonSerializer.fromString(rawJsonSerializer);
    } else if (rootConfig?.jsonSerializer != null) {
      jsonSerializer = rootConfig!.jsonSerializer;
    }

    final rootClient =
        yamlMap['root_client'] as bool? ?? rootConfig?.rootClient;
    final rootClientName =
        yamlMap['root_client_name'] as String? ?? rootConfig?.rootClientName;
    final clientPostfix =
        yamlMap['client_postfix'] as String? ?? rootConfig?.clientPostfix;
    final exportFile =
        yamlMap['export_file'] as bool? ?? rootConfig?.exportFile;
    final putClientsInFolder = yamlMap['put_clients_in_folder'] as bool? ??
        rootConfig?.putClientsInFolder;
    final enumsToJson =
        yamlMap['enums_to_json'] as bool? ?? rootConfig?.enumsToJson;
    final unknownEnumValue =
        yamlMap['unknown_enum_value'] as bool? ?? rootConfig?.unknownEnumValue;
    final markFilesAsGenerated = yamlMap['mark_files_as_generated'] as bool? ??
        rootConfig?.markFilesAsGenerated;
    final originalHttpResponse = yamlMap['original_http_response'] as bool? ??
        rootConfig?.originalHttpResponse;

    final rawReplacementRules = yamlMap['replacement_rules'] as YamlList?;
    List<ReplacementRule>? replacementRules;
    if (rawReplacementRules != null) {
      replacementRules = [];
      for (final r in rawReplacementRules) {
        if (r is! YamlMap ||
            r['pattern'] is! String ||
            r['replacement'] is! String) {
          throw const ConfigException(
            "Config parameter 'replacement_rules' values must be maps of strings "
            "and contain 'pattern' and 'replacement'.",
          );
        }
        replacementRules.add(
          ReplacementRule(
            pattern: RegExp(r['pattern'].toString()),
            replacement: r['replacement'].toString(),
          ),
        );
      }
    } else if (rootConfig?.replacementRules != null) {
      replacementRules = List.from(rootConfig!.replacementRules);
    }

    final rawReplacementRulesForRawSchema =
        yamlMap['replacement_rules_for_raw_schema'] as YamlList?;
    List<ReplacementRule>? replacementRulesForRawSchema;
    if (rawReplacementRulesForRawSchema != null) {
      replacementRulesForRawSchema = [];
      for (final r in rawReplacementRulesForRawSchema) {
        if (r is! YamlMap ||
            r['pattern'] is! String ||
            r['replacement'] is! String) {
          throw const ConfigException(
            "Config parameter 'replacement_rules_for_raw_schema' values must be maps of strings "
            "and contain 'pattern' and 'replacement'.",
          );
        }
        replacementRulesForRawSchema.add(
          ReplacementRule(
            pattern: RegExp(r['pattern'].toString()),
            replacement: r['replacement'].toString(),
          ),
        );
      }
    } else if (rootConfig?.replacementRulesForRawSchema != null) {
      replacementRulesForRawSchema =
          List.from(rootConfig!.replacementRulesForRawSchema);
    }

    final generateValidator =
        yamlMap['generate_validator'] as bool? ?? rootConfig?.generateValidator;

    final useXNullable =
        yamlMap['use_x_nullable'] as bool? ?? rootConfig?.useXNullable;

    final useFreezed3 =
        yamlMap['use_freezed3'] as bool? ?? rootConfig?.useFreezed3;

    final useMultipartFile =
        yamlMap['use_multipart_file'] as bool? ?? rootConfig?.useMultipartFile;

    final fallbackUnion =
        yamlMap['fallback_union'] as String? ?? rootConfig?.fallbackUnion;

    final dartMappableConvenientWhen =
        yamlMap['dart_mappable_convenient_when'] as bool? ??
            rootConfig?.dartMappableConvenientWhen ??
            true;

    final useDartMappableNaming =
        yamlMap['use_dart_mappable_naming'] as bool? ??
            rootConfig?.useDartMappableNaming;

    final excludedTagsYaml = yamlMap['exclude_tags'] as YamlList?;
    List<String>? excludedTags;
    if (excludedTagsYaml != null) {
      excludedTags = [];
      for (final t in excludedTagsYaml) {
        if (t is! String) {
          throw const ConfigException(
            "Config parameter 'exclude_tags' values must be List of String.",
          );
        }
        excludedTags.add(t);
      }
    } else if (rootConfig?.excludeTags != null) {
      excludedTags = List.from(rootConfig!.excludeTags);
    }

    final includedTagsYaml = yamlMap['include_tags'] as YamlList?;
    List<String>? includedTags;
    if (includedTagsYaml != null) {
      includedTags = [];
      for (final t in includedTagsYaml) {
        if (t is! String) {
          throw const ConfigException(
            "Config parameter 'include_tags' values must be List of String.",
          );
        }
        includedTags.add(t);
      }
    } else if (rootConfig?.includeTags != null) {
      includedTags = List.from(rootConfig!.includeTags);
    }

    final includePaths = yamlMap['include_paths'] as YamlList?;
    List<String>? includePathsList;
    if (includePaths != null) {
      includePathsList = [];
      for (final p in includePaths) {
        if (p is! String) {
          throw const ConfigException(
            "Config parameter 'include_paths' values must be List of String.",
          );
        }
        includePathsList.add(p);
      }
    } else if (rootConfig?.includePaths case final paths?) {
      includePathsList = List.from(paths);
    }

    final fallbackClient =
        yamlMap['fallback_client'] as String? ?? rootConfig?.fallbackClient;

    final mergeOutputs =
        yamlMap['merge_outputs'] as bool? ?? rootConfig?.mergeOutputs;

    final includeIfNull =
        yamlMap['include_if_null'] as bool? ?? rootConfig?.includeIfNull;

    final inferRequiredFromNullable =
        yamlMap['infer_required_from_nullable'] as bool? ??
            rootConfig?.inferRequiredFromNullable;

    final useFlutterCompute = yamlMap['use_flutter_compute'] as bool? ??
        rootConfig?.useFlutterCompute;

    final generateUrlsConstants = yamlMap['generate_urls_constants'] as bool? ??
        rootConfig?.generateUrlsConstants;

    final rawFieldParsers = yamlMap['field_parsers'] as YamlList?;
    List<FieldParser>? fieldParsers;
    if (rawFieldParsers != null) {
      fieldParsers = [];
      for (final p in rawFieldParsers) {
        if (p is! YamlMap ||
            p['apply_to_type'] is! String ||
            p['parser_name'] is! String ||
            p['parser_absolute_path'] is! String) {
          throw const ConfigException(
            "Config parameter 'field_parsers' values must be List of maps with 'apply_to_type', 'parser_name', and 'parser_absolute_path'.",
          );
        }
        fieldParsers.add(
          FieldParser(
            applyToType: p['apply_to_type'].toString(),
            parserName: p['parser_name'].toString(),
            parserAbsolutePath: p['parser_absolute_path'].toString(),
          ),
        );
      }
    } else if (rootConfig?.fieldParsers != null) {
      fieldParsers = List.from(rootConfig!.fieldParsers);
    }

    // Default config
    final dc = SWPConfig(name: name, outputDirectory: outputDirectory);

    return SWPConfig._(
      schemaPath: schemaPath,
      schemaUrl: schemaUrl,
      fieldParsers: fieldParsers ?? dc.fieldParsers,
      outputDirectory: outputDirectory,
      name: name,
      pathMethodName: pathMethodName ?? dc.pathMethodName,
      defaultContentType: defaultContentType ?? dc.defaultContentType,
      extrasParameterByDefault:
          extrasParameterByDefault ?? dc.extrasParameterByDefault,
      dioOptionsParameterByDefault:
          dioOptionsParameterByDefault ?? dc.dioOptionsParameterByDefault,
      addOpenApiMetadata: addOpenApiMetadata ?? dc.addOpenApiMetadata,
      mergeClients: mergeClients ?? dc.mergeClients,
      enumsParentPrefix: enumsParentPrefix ?? dc.enumsParentPrefix,
      skippedParameters: skippedParameters ?? dc.skippedParameters,
      exportFile: exportFile ?? dc.exportFile,
      language: language ?? dc.language,
      jsonSerializer: jsonSerializer ?? dc.jsonSerializer,
      rootClient: rootClient ?? dc.rootClient,
      rootClientName: rootClientName ?? dc.rootClientName,
      clientPostfix: clientPostfix?.trim() ?? dc.clientPostfix,
      putClientsInFolder: putClientsInFolder ?? dc.putClientsInFolder,
      enumsToJson: enumsToJson ?? dc.enumsToJson,
      unknownEnumValue: unknownEnumValue ?? dc.unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated ?? dc.markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse ?? dc.originalHttpResponse,
      replacementRules: replacementRules ?? dc.replacementRules,
      replacementRulesForRawSchema:
          replacementRulesForRawSchema ?? dc.replacementRulesForRawSchema,
      generateValidator: generateValidator ?? dc.generateValidator,
      useXNullable: useXNullable ?? dc.useXNullable,
      useFreezed3: useFreezed3 ?? dc.useFreezed3,
      useMultipartFile: useMultipartFile ?? dc.useMultipartFile,
      fallbackUnion: fallbackUnion,
      excludeTags: excludedTags ?? dc.excludeTags,
      includeTags: includedTags ?? dc.includeTags,
      fallbackClient: fallbackClient ?? dc.fallbackClient,
      mergeOutputs: mergeOutputs ?? dc.mergeOutputs,
      dartMappableConvenientWhen: dartMappableConvenientWhen,
      useDartMappableNaming: useDartMappableNaming ?? dc.useDartMappableNaming,
      includeIfNull: includeIfNull ?? dc.includeIfNull,
      inferRequiredFromNullable:
          inferRequiredFromNullable ?? dc.inferRequiredFromNullable,
      useFlutterCompute: useFlutterCompute ?? dc.useFlutterCompute,
      includePaths: includePathsList ?? dc.includePaths,
      generateUrlsConstants: generateUrlsConstants ?? dc.generateUrlsConstants,
    );
  }

  /// Creates a [SWPConfig] from [YamlMap] with CLI [argResults] overrides.
  factory SWPConfig.fromYamlWithOverrides(
    YamlMap yamlMap,
    ArgResults? argResults, {
    bool isRootConfig = false,
    SWPConfig? rootConfig,
  }) {
    // Apply CLI overrides to YAML map
    final mergedConfig = Map<String, dynamic>.from(yamlMap);

    if (argResults != null) {
      for (final option in argResults.options) {
        mergedConfig[option] = argResults[option];
      }
    }

    // Create YAML map from merged config
    final mergedYamlMap = YamlMap.wrap(mergedConfig);

    // Use existing fromYaml method with merged configuration
    return SWPConfig.fromYaml(
      mergedYamlMap,
      isRootConfig: isRootConfig,
      rootConfig: rootConfig,
    );
  }

  /// Sets the path directory of the OpenApi schema.
  final String? schemaPath;

  /// Sets the url of the OpenApi schema.
  final String? schemaUrl;

  /// Optional. Set API name for folder and export file
  /// If not specified, the file name is used.
  final String name;

  /// Required. Sets output directory for generated files (Clients and DTOs).
  final String outputDirectory;

  /// Optional. Sets the programming language.
  /// Current available languages are: dart, kotlin.
  final ProgrammingLanguage language;

  /// DART ONLY
  /// Optional. Current available serializers are: json_serializable, freezed, dart_mappable.
  final JsonSerializer jsonSerializer;

  /// DART ONLY
  /// Optional, defaults to false. Set to true to use the standard `toMap` and `fromMap` serialization from
  /// dart_mappable. This is a new feature introduced in Retrofit 4.9.2. Prior to this
  /// it was required to rename these methods in the build.yaml to `fromJson` and `toJson`
  /// to make dart_mappable compatible with retrofit. To avoid breaking changes for existing
  /// dart_mappable implementations, this flag must be explicitely set to true
  ///
  /// This flag exists to avoid making dart_mappable serialization the default behavior.
  // TODO(carapacik): This flag can be removed in the next major version to make the standard
  // dart_mappable serialization the default behavior.
  final bool useDartMappableNaming;

  /// Optional. Set postfix for client classes and files.
  final String? clientPostfix;

  /// DART ONLY
  /// Optional. Set 'true' to generate root client
  /// with interface and all clients instances.
  final bool rootClient;

  /// DART ONLY
  /// Optional. Set root client name.
  final String rootClientName;

  /// DART ONLY
  /// Optional. Set `true` to generate export file.
  final bool exportFile;

  /// Optional. Set `true` to put all clients in clients folder.
  final bool putClientsInFolder;

  /// DART ONLY
  /// Optional. Set `true` to include toJson() in enums.
  /// If set to `false`, serialization will use .name instead.
  final bool enumsToJson;

  /// DART ONLY
  /// Optional. Set `true` to maintain backwards compatibility when adding new values on the backend.
  final bool unknownEnumValue;

  /// Optional. Set `false` to not put a comment at the beginning of the generated files.
  final bool markFilesAsGenerated;

  /// DART ONLY
  /// Optional. Set `true` to wrap all request return types with HttpResponse.
  final bool originalHttpResponse;

  /// Optional. Set regex replacement rules for the names of the generated classes/enums.
  /// All rules are applied in order.
  final List<ReplacementRule> replacementRules;

  /// {@template replacement_rules_for_raw_schema}
  /// Optional. Set raw regex replacement rules for the names of the raw schema objects.
  ///
  /// Applies to the raw schema objects before the generator will try to parse them into a Dart class.
  ///
  /// Useful when raw schema objects have names are not valid Dart class names (e.g. "filters[name]")
  /// {@endtemplate}
  final List<ReplacementRule> replacementRulesForRawSchema;

  /// DART ONLY
  /// Default content type for all requests and responses.
  ///
  /// If the content type does not match the default, generates:
  /// `@Headers(<String, String>{'Content-Type': 'PARSED CONTENT TYPE'})`
  final String defaultContentType;

  /// DART ONLY
  /// Add extra parameter to all requests. Supported after retrofit 4.1.0.
  ///
  /// If  value is 'true', then the annotation will be added to all requests.
  /// ```dart
  /// @POST('/path/')
  /// Future<String> myMethod({@Extras() Map<String, dynamic>? extras});
  /// ```
  final bool extrasParameterByDefault;

  /// DART ONLY
  /// Add dio options parameter to all requests.
  ///
  /// If  value is 'true', then the annotation will be added to all requests.
  /// ```dart
  /// @POST('/path/')
  /// Future<String> myMethod({@DioOptions() RequestOptions? options});
  /// ```
  final bool dioOptionsParameterByDefault;

  /// DART ONLY
  /// Add static OpenAPI metadata into extras by default when extras are enabled.
  final bool addOpenApiMetadata;

  /// If `true`, use the endpoint path for the method name.
  /// if `false`, use `operationId`.
  final bool pathMethodName;

  /// Set `true` to merge all clients in single client.
  final bool mergeClients;

  /// Set 'true' to set enum prefix from parent component.
  final bool enumsParentPrefix;

  /// List of parameter names that should skip during parsing
  final List<String> skippedParameters;

  /// Set `true` to generate validator for freezed.
  final bool generateValidator;

  /// Set `true` if Schema uses x-nullable to indicate nullable fields
  final bool useXNullable;

  /// Set `true` to use Freezed 3.x code generation syntax.
  /// Set `false` to maintain compatibility with Freezed 2.x
  final bool useFreezed3;

  /// DART ONLY
  /// Optional. Set `true` to use MultipartFile instead of File as argument type
  /// for file parameters.
  final bool useMultipartFile;

  /// DART ONLY
  /// Optional. Set fallback consctructor name to use fallbackUnion parameter when using Freezed annotation.
  final String? fallbackUnion;

  /// DART ONLY
  /// Optional. Set 'true' to generate when/maybeWhen convenience methods for dart_mappable unions.
  /// Set 'false' to use only native Dart pattern matching.
  final bool dartMappableConvenientWhen;

  /// DART ONLY
  /// Optional. Set excluded tags.
  ///
  /// Endpoints with these tags will not be included in the generated clients.
  final List<String> excludeTags;

  /// {@template include_paths}
  /// Optional. Set included paths.
  ///
  /// Also supports wildcard paths (e.g. `/path/*/update` or `/path/**`)
  ///
  /// If set, only endpoints with these paths will be included in the generated clients.
  /// {@endtemplate}
  final List<String>? includePaths;

  /// DART ONLY
  /// Optional. Set included tags.
  ///
  /// If set, only endpoints with these tags will be included in the generated clients.
  /// **NOTE: This will override the [excludeTags] if set.**
  final List<String> includeTags;

  /// DART ONLY
  /// Optional. Fallback client name for endpoints without tags.
  ///
  /// defaults to 'fallback' which results in a client named `FallbackClient`.
  final String fallbackClient;

  /// Optional. Set to true to merge all generated code into a single file.
  ///
  /// This is useful when using swagger_parser together with build_runner, which needs to map
  /// input files to output files 1-to-1.
  final bool mergeOutputs;

  /// DART ONLY
  /// Optional. Set `true` to generate includeIfNull annotations for nullable fields.
  /// If set to `false`, includeIfNull annotations will not be generated.
  final bool includeIfNull;

  /// DART ONLY
  /// Optional. When true, infer required properties from nullability.
  /// Properties without nullable: true in schema are marked as required.
  /// Only applies when schema has no explicit required array.
  final bool inferRequiredFromNullable;

  /// DART/FLUTTER ONLY
  /// Optional. Set `true` to generate Retrofit clients with `Parser.FlutterCompute`
  /// and serialize/deserialize top-level functions for isolate-based multithreading.
  final bool useFlutterCompute;

  /// DART/FLUTTER ONLY
  /// Optional. Set `true` to generate URL constants for all endpoints.
  final bool generateUrlsConstants;

  /// {@template field_parsers}
  /// DART ONLY
  /// Optional. Set field parsers.
  ///
  /// Field parsers are used to parse specific fields of a DTO.
  ///
  /// {@endtemplate}
  final List<FieldParser> fieldParsers;

  /// Convert [SWPConfig] to [GeneratorConfig]
  GeneratorConfig toGeneratorConfig() {
    return GeneratorConfig(
      name: name,
      outputDirectory: outputDirectory,
      language: language,
      jsonSerializer: jsonSerializer,
      defaultContentType: defaultContentType,
      extrasParameterByDefault: extrasParameterByDefault,
      dioOptionsParameterByDefault: dioOptionsParameterByDefault,
      addOpenApiMetadata: addOpenApiMetadata,
      rootClient: rootClient,
      rootClientName: rootClientName,
      clientPostfix: clientPostfix,
      exportFile: exportFile,
      putClientsInFolder: putClientsInFolder,
      enumsToJson: enumsToJson,
      unknownEnumValue: unknownEnumValue,
      markFilesAsGenerated: markFilesAsGenerated,
      originalHttpResponse: originalHttpResponse,
      replacementRules: replacementRules,
      generateValidator: generateValidator,
      useFreezed3: useFreezed3,
      useMultipartFile: useMultipartFile,
      fallbackUnion: fallbackUnion,
      dartMappableConvenientWhen: dartMappableConvenientWhen,
      useDartMappableNaming: useDartMappableNaming,
      mergeOutputs: mergeOutputs,
      includeIfNull: includeIfNull,
      useFlutterCompute: useFlutterCompute,
      generateUrlsConstants: generateUrlsConstants,
      fieldParsers: fieldParsers,
    );
  }

  /// Convert [SWPConfig] to [ParserConfig]
  ParserConfig toParserConfig({
    required String fileContent,
    required bool isJson,
  }) {
    return ParserConfig(
      fileContent,
      isJson: isJson,
      name: name,
      defaultContentType: defaultContentType,
      pathMethodName: pathMethodName,
      mergeClients: mergeClients,
      enumsParentPrefix: enumsParentPrefix,
      skippedParameters: skippedParameters,
      replacementRules: replacementRules,
      useXNullable: useXNullable,
      excludeTags: excludeTags,
      replacementRulesForRawSchema: replacementRulesForRawSchema,
      includeTags: includeTags,
      includePaths: includePaths,
      fallbackClient: fallbackClient,
      inferRequiredFromNullable: inferRequiredFromNullable,
    );
  }
}
