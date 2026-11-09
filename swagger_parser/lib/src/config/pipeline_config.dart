import 'package:swagger_parser/swagger_parser.dart';

/// In-memory settings shared by CLI and browser generation.
final class const PipelineConfig({
  /// Parser settings. Defaults match [ParseConfig].
  final ParseConfig parse = const ParseConfig(),

  /// Normalization settings. No rules are enabled by default.
  final NormalizeConfig normalize = const NormalizeConfig(),

  /// Dart output settings. Defaults match [GenerationConfig].
  final GenerationConfig generation = const GenerationConfig(),
}) {
  /// Creates generation settings without file or network access.
  this;

  /// Decodes parse, normalize, and generation sections from a config mapping.
  /// Source and output keys belong to the caller. Unknown section options and
  /// invalid values throw [FormatException]. [extensionOptions] allows renderer
  /// settings that the caller must validate and load.
  factory fromMap(
    Map<String, Object?> values, {
    Set<String> extensionOptions = const {},
  }) {
    final root = _Options(values, 'configuration');
    final _Options normalize = root.section('normalize').canonical()
      ..check({'explicit_parameter_serialization'});
    final _Options generation = root.section('generation').canonical()
      ..check({
        ...extensionOptions,
        'page_width',
        'file_suffix',
        'api_metadata',
        'type_mappings',
        'operation_filters',
        'exclude_parameters',
        'prune_unused_models',
        'keep_models',
        'root_api_class_name',
        'fallback_client_name',
        'naming',
        'generate_docs',
        'body_positional',
        'use_path_for_method_names',
        'original_http_response',
        'apply_parameter_defaults',
        'infer_missing_required',
        'use_presence_records',
        'generate_validators',
        'http_client',
        'serializer',
        'response_mode',
        'unknown_enum_values',
        'unknown_discriminator_values',
        'stream_binary_responses',
        'decode_responses_in_background',
      });
    const gen = GenerationConfig();
    final String fileSuffix =
        generation.get<String>('file_suffix') ?? gen.fileSuffix;
    if (!DartModelMapper.isValidFileSuffix(fileSuffix)) {
      throw FormatException('Invalid generation.file_suffix: $fileSuffix.');
    }
    final String rootApiClassName =
        generation.get<String>('root_api_class_name') ?? gen.rootApiClassName;
    if (!DartModelMapper.isValidRootApiClassName(rootApiClassName)) {
      throw FormatException(
        'Invalid generation.root_api_class_name: $rootApiClassName.',
      );
    }
    final String fallbackName =
        generation.get<String>('fallback_client_name') ??
        gen.fallbackClientName;
    if (!DartModelMapper.isValidRootApiClassName(fallbackName)) {
      throw FormatException(
        'Invalid generation.fallback_client_name: $fallbackName.',
      );
    }
    return PipelineConfig(
      parse: _parseConfig(root.section('parse')),
      normalize: NormalizeConfig(
        explicitParameterSerialization:
            normalize.get<bool>('explicit_parameter_serialization') ?? false,
      ),
      generation: GenerationConfig(
        rootApiClassName: rootApiClassName,
        fileSuffix: fileSuffix,
        apiMetadata: generation.choice(
          'api_metadata',
          ApiMetadataMode.values,
          gen.apiMetadata,
        ),
        fallbackClientName: fallbackName,
        typeMappings: _typeMappings(generation),
        excludeParameters: _parameterExclusions(generation),
        pruneUnusedModels: generation.get<bool>('prune_unused_models') ?? false,
        keepModels: _strings(generation, 'keep_models'),
        operationFilters: _operationFilters(
          generation.section('operation_filters'),
        ),
        naming: _namingConfig(generation.section('naming')),
        pageWidth: generation.positive('page_width', gen.pageWidth),
        generateDocs: generation.get<bool>('generate_docs') ?? gen.generateDocs,
        usePathForMethodNames:
            generation.get<bool>('use_path_for_method_names') ??
            gen.usePathForMethodNames,
        bodyPositional:
            generation.get<bool>('body_positional') ?? gen.bodyPositional,
        applyParameterDefaults:
            generation.get<bool>('apply_parameter_defaults') ??
            gen.applyParameterDefaults,
        inferMissingRequired:
            generation.get<bool>('infer_missing_required') ??
            gen.inferMissingRequired,
        generateValidators:
            generation.get<bool>('generate_validators') ??
            gen.generateValidators,
        usePresenceRecords:
            generation.get<bool>('use_presence_records') ??
            gen.usePresenceRecords,
        originalHttpResponse:
            generation.get<bool>('original_http_response') ??
            gen.originalHttpResponse,
        decodeResponsesInBackground:
            generation.get<bool>('decode_responses_in_background') ??
            gen.decodeResponsesInBackground,
        streamBinaryResponses:
            generation.get<bool>('stream_binary_responses') ??
            gen.streamBinaryResponses,
        serializer: generation.choice(
          'serializer',
          DtoSerializer.values,
          gen.serializer,
        ),
        httpClient: generation.choice(
          'http_client',
          HttpClientBackend.values,
          gen.httpClient,
        ),
        unknownEnumValues: generation.choice(
          'unknown_enum_values',
          UnknownValueMode.values,
          gen.unknownEnumValues,
        ),
        unknownDiscriminatorValues: generation.choice(
          'unknown_discriminator_values',
          UnknownValueMode.values,
          gen.unknownDiscriminatorValues,
        ),
        responseMode: generation.choice(
          'response_mode',
          ResponseMode.values,
          gen.responseMode,
        ),
      ),
    );
  }

  static List<String> _strings(_Options options, String key) {
    final List<Object?> values = options.get<List<Object?>>(key) ?? const [];
    if (values.any((value) => value is! String)) {
      throw FormatException('${options.location}.$key must contain strings.');
    }
    return List.unmodifiable(values.cast<String>());
  }

  static List<ParameterExclusion> _parameterExclusions(_Options options) {
    final List<Object?> values =
        options.get<List<Object?>>('exclude_parameters') ?? const [];
    return List.unmodifiable([
      for (final (i, value) in values.indexed)
        _parameterExclusion(
          value,
          '${options.location}.exclude_parameters[$i]',
        ),
    ]);
  }

  static ParameterExclusion _parameterExclusion(
    Object? value,
    String location,
  ) {
    final rule = _Options.map(value, location)
      ..check({'name', 'in', 'paths', 'methods'});
    final exclusion = ParameterExclusion(
      name: rule.get<String>('name') ?? '',
      location: rule.get<String>('in') ?? '',
      paths: _strings(rule, 'paths'),
      methods: _strings(rule, 'methods'),
    );
    if (exclusion.validationError case final error?) {
      throw FormatException('$location: $error');
    }
    return exclusion;
  }

  static OperationFilterConfig _operationFilters(_Options section) {
    final _Options options = section.canonical()
      ..check({
        'include_paths',
        'exclude_paths',
        'include_tags',
        'exclude_tags',
      });
    List<String>? strings(String key, {bool nullable = false}) {
      final List<Object?>? values = nullable
          ? options.get<List<Object?>?>(key)
          : options.get<List<Object?>>(key);
      if (values == null) {
        return null;
      }
      if (values.any((value) => value is! String)) {
        throw FormatException('${options.location}.$key must contain strings.');
      }
      final List<String> strings = values.cast<String>();
      if (key.endsWith('_paths')) {
        for (final pattern in strings) {
          if (!OperationFilterConfig.isValidPathPattern(pattern)) {
            throw FormatException(
              'Invalid ${options.location}.$key pattern: $pattern.',
            );
          }
        }
      }
      return List.unmodifiable(strings);
    }

    return OperationFilterConfig(
      includePaths: strings('include_paths', nullable: true),
      excludePaths: strings('exclude_paths') ?? const [],
      includeTags: strings('include_tags', nullable: true),
      excludeTags: strings('exclude_tags') ?? const [],
    );
  }

  static List<TypeMapping> _typeMappings(_Options options) {
    final List<Object?> rules =
        options.get<List<Object?>>('type_mappings') ?? const [];
    return List.unmodifiable([
      for (final (i, value) in rules.indexed)
        _typeMapping(value, '${options.location}.type_mappings[$i]'),
    ]);
  }

  static TypeMapping _typeMapping(Object? value, String location) {
    final rule = _Options.map(value, location)
      ..check({
        'schema',
        'type',
        'format',
        'dart_type',
        'import',
        'codec',
        'defaults',
        'direction',
      });
    final _Options codec = rule.section('codec')
      ..check({'import', 'from_json', 'to_json'});
    return TypeMapping(
      direction: rule.choice(
        'direction',
        TypeMappingDirection.values,
        TypeMappingDirection.both,
      ),
      defaults: [
        for (final (i, value)
            in (rule.get<List<Object?>>('defaults') ?? const []).indexed)
          _typeDefault(value, '$location.defaults[$i]'),
      ],
      schema: rule.get<String>('schema'),
      type: rule.get<String>('type'),
      format: rule.get<String>('format'),
      dartType: rule.path('dart_type'),
      importUrl: rule.path('import'),
      codec: TypeMappingCodec(
        importUrl: codec.path('import'),
        fromJson: codec.path('from_json'),
        toJson: codec.path('to_json'),
      ),
    );
  }

  static TypeMappingDefault _typeDefault(Object? value, String location) {
    final option = _Options.map(value, location)
      ..check({'value', 'import', 'constant'});
    if (!option.values.containsKey('value')) {
      throw FormatException('Missing $location.value.');
    }
    return TypeMappingDefault(
      value: _defaultJson(option.values['value'], '$location.value'),
      importUrl: option.path('import'),
      constant: option.path('constant'),
    );
  }

  static Object? _defaultJson(
    Object? value,
    String location,
  ) => switch (value) {
    null || String() || bool() || int() => value,
    double() when value.isFinite => value,
    List<Object?>() => [for (final item in value) _defaultJson(item, location)],
    Map() when value.keys.every((key) => key is String) => <String, Object?>{
      for (final entry in value.entries)
        entry.key as String: _defaultJson(entry.value, location),
    },
    _ => throw FormatException('Expected a finite JSON value at $location.'),
  };

  static NamingConfig _namingConfig(_Options section) {
    final _Options options = section.canonical()
      ..check({'preserve_schema_casing', 'replace_rules'});
    final rules = <NameReplacementRule>[];
    final List<Object?> values =
        options.get<List<Object?>>('replace_rules') ?? const [];
    for (var i = 0; i < values.length; i++) {
      final location = '${options.location}.replace_rules[$i]';
      final rule = _Options.map(values[i], location)
        ..check({'target', 'pattern', 'replacement'});
      for (final key in ['target', 'pattern', 'replacement']) {
        if (!rule.values.containsKey(key)) {
          throw FormatException('Missing $location.$key.');
        }
      }
      final String pattern = rule.get<String>('pattern')!;
      try {
        RegExp(pattern);
      } on FormatException catch (e) {
        throw FormatException('Invalid $location.pattern: ${e.message}');
      }
      rules.add(
        NameReplacementRule(
          target: rule.choice(
            'target',
            NamingTarget.values,
            NamingTarget.models,
          ),
          pattern: pattern,
          replacement: rule.get<String>('replacement')!,
        ),
      );
    }
    return NamingConfig(
      preserveSchemaCasing:
          options.get<bool>('preserve_schema_casing') ?? false,
      replaceRules: List.unmodifiable(rules),
    );
  }

  static ParseConfig _parseConfig(_Options section) {
    const defaults = ParseConfig();
    if (section.values.isEmpty) {
      return defaults;
    }
    final _Options options = section.canonical()
      ..check({'max_depth', 'capture_source_locations', 'unknown_fields'});
    return ParseConfig(
      maxDepth: options.positive('max_depth', defaults.maxDepth),
      captureSourceLocations:
          options.get<bool>('capture_source_locations') ??
          defaults.captureSourceLocations,
      unknownFields: options.choice(
        'unknown_fields',
        UnknownFieldPolicy.values,
        defaults.unknownFields,
      ),
    );
  }
}

final class const _Options(
  final Map<String, Object?> values,
  final String location,
) {
  factory map(Object? data, String location) {
    if (data is! Map || data.keys.any((key) => key is! String)) {
      throw FormatException('$location must be a mapping with string keys.');
    }
    return _Options(data.cast<String, Object?>(), location);
  }

  _Options canonical() {
    final options = <String, Object?>{};
    for (final MapEntry<String, Object?> entry in values.entries) {
      final String key = _snake(entry.key);
      if (options.containsKey(key)) {
        throw FormatException('Duplicate option $location.$key.');
      }
      options[key] = entry.value;
    }
    return _Options(options, location);
  }

  static String _snake(String name) =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  void check(Set<String> keys) {
    for (final String key in values.keys) {
      if (!keys.contains(key)) {
        throw FormatException('Unknown option $location.$key.');
      }
    }
  }

  _Options section(String key) => _Options.map(
    values.containsKey(key) ? values[key] : const {},
    '$location.$key',
  );

  String? oneOf(List<String> keys) {
    final List<String> found = keys.where(values.containsKey).toList();
    if (found.length > 1) {
      throw FormatException('Choose one of ${found.join(', ')} in $location.');
    }
    return found.firstOrNull;
  }

  String path(String key) {
    final String? value = get<String>(key);
    if (value == null || value.trim().isEmpty) {
      throw FormatException('Specify a non-empty $location.$key.');
    }
    return value;
  }

  T? get<T>(String key) {
    if (!values.containsKey(key)) {
      return null;
    }
    final Object? value = values[key];
    if (value is T) {
      return value;
    }
    throw FormatException('$location.$key must be a $T.');
  }

  int positive(String key, int fallback) {
    final int value = get<int>(key) ?? fallback;
    if (value < 1) {
      throw FormatException('$location.$key must be positive.');
    }
    return value;
  }

  T choice<T extends Enum>(String key, List<T> options, T fallback) {
    final String? value = get<String>(key);
    if (value == null) {
      return fallback;
    }
    for (final option in options) {
      if (option.name == value || _snake(option.name) == value) {
        return option;
      }
    }
    throw FormatException(
      '$location.$key must be one of ${options.map((o) => _snake(o.name)).join(', ')}.',
    );
  }
}
