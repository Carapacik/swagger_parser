import 'package:swagger_parser/swagger_parser.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// One schema's editor settings. Unrepresented YAML keys stay unchanged.
final class EditorConfig._(
  /// Source YAML, including comments and settings absent from the form.
  final String yaml,
  final YamlMap _root,
  final bool _wrapped,
) {
  /// Loads wrapped or bare YAML. Rejects invalid form values and batch inputs.
  factory parse(String source) {
    final Object? decoded = loadYaml(source);
    if (decoded is! YamlMap) {
      throw const FormatException('Config must be a YAML mapping.');
    }
    final bool wrapped = decoded.containsKey('swagger_parser');
    if (wrapped && decoded.length != 1) {
      throw const FormatException('Keep settings inside swagger_parser.');
    }
    final Object? root = wrapped ? decoded['swagger_parser'] : decoded;
    if (root is! YamlMap) {
      throw const FormatException('swagger_parser must be a mapping.');
    }
    if (root.containsKey('inputs')) {
      throw const FormatException(
        'This editor accepts one schema. Remove inputs.',
      );
    }
    final config = EditorConfig._(source, root, wrapped).._validate();
    return config;
  }

  /// Starts with the approved generator defaults.
  factory defaults() {
    final editor = YamlEditor('')
      ..update([], {
        'swagger_parser': {'generation': defaultValues},
      });
    return EditorConfig.parse(editor.toString());
  }

  /// Editable generator values, derived from the library defaults.
  static final Map<String, Object> defaultValues = Map.unmodifiable({
    'root_api_class_name': _defaults.rootApiClassName,
    'http_client': _wire(_defaults.httpClient),
    'serializer': _wire(_defaults.serializer),
    'response_mode': _wire(_defaults.responseMode),
    'unmatched_union_values': _wire(_defaults.unmatchedUnionValues),
    'page_width': _defaults.pageWidth,
    'generate_docs': _defaults.generateDocs,
    'infer_missing_required': _defaults.inferMissingRequired,
    'use_presence_records': _defaults.usePresenceRecords,
    'generate_validators': _defaults.generateValidators,
    'prune_unused_models': _defaults.pruneUnusedModels,
    'body_positional': _defaults.bodyPositional,
    'apply_parameter_defaults': _defaults.applyParameterDefaults,
    'original_http_response': _defaults.originalHttpResponse,
  });

  static const _defaults = GenerationConfig();

  /// Returns a form value or its library default.
  Object value(String key) =>
      (_section('generation')[key] as Object?) ?? defaultValues[key]!;

  /// Changes one form setting. Invalid changes leave this instance unchanged.
  EditorConfig withValue(String key, Object value) {
    if (!defaultValues.containsKey(key)) {
      throw ArgumentError.value(key, 'key', 'Unknown form setting.');
    }
    final editor = YamlEditor(yaml);
    final path = <String>[if (_wrapped) 'swagger_parser', 'generation'];
    if (!_root.containsKey('generation')) {
      editor.update(path, <String, Object?>{});
    }
    editor.update([...path, key], value);
    return EditorConfig.parse(editor.toString());
  }

  /// Validates all pipeline options before generation.
  /// Local template paths, batch inputs, and schema downloads are unsupported.
  PipelineConfig get pipelineConfig {
    const allowed = {
      'input',
      'schema_path',
      'schema_url',
      'output',
      'output_directory',
      'parse',
      'normalize',
      'generation',
    };
    for (final Object? key in _root.keys) {
      if (!allowed.contains(key)) {
        throw FormatException('Unsupported browser option: $key.');
      }
    }
    if (_section('generation').containsKey('templates')) {
      throw const FormatException(
        'Template file paths cannot be read in the browser. Remove generation.templates.',
      );
    }
    return PipelineConfig.fromMap(_root.cast<String, Object?>());
  }

  /// Parser settings used by the schema check.
  ParseConfig get parseConfig {
    final Map<dynamic, dynamic> values = _section('parse');
    return ParseConfig(
      unknownFields: values['unknown_fields'] == 'reject'
          ? UnknownFieldPolicy.reject
          : UnknownFieldPolicy.preserve,
      captureSourceLocations:
          values['capture_source_locations'] as bool? ?? true,
      maxDepth: values['max_depth'] as int? ?? 128,
    );
  }

  Map<dynamic, dynamic> _section(String name) {
    final Object? section = _root[name];
    if (section == null && !_root.containsKey(name)) {
      return const {};
    }
    if (section is! YamlMap) {
      throw FormatException('$name must be a mapping.');
    }
    return section;
  }

  void _validate() {
    final Map<dynamic, dynamic> values = _section('generation');
    for (final MapEntry<String, Object> entry in defaultValues.entries) {
      if (!values.containsKey(entry.key)) {
        continue;
      }
      final Object? actual = values[entry.key];
      if (switch (entry.value) {
        bool() => actual is! bool,
        int() => actual is! int,
        _ => actual is! String,
      }) {
        throw FormatException('Invalid value for ${entry.key}.');
      }
    }
    for (final MapEntry<String, List<Enum>> entry in {
      'http_client': HttpClientBackend.values,
      'serializer': DtoSerializer.values,
      'response_mode': ResponseMode.values,
      'unmatched_union_values': UnknownValueMode.values,
    }.entries) {
      if (!entry.value.map(_wire).contains(value(entry.key))) {
        throw FormatException('Unknown ${entry.key}: ${value(entry.key)}.');
      }
    }
    final name = value('root_api_class_name') as String;
    if (!DartModelMapper.isValidRootApiClassName(name)) {
      throw const FormatException('Use a Dart class name, such as TransitApi.');
    }
    if ((value('page_width') as int) <= 0) {
      throw const FormatException('page_width must be positive.');
    }
    final Map<dynamic, dynamic> parse = _section('parse');
    if (parse.containsKey('max_depth') &&
        (parse['max_depth'] is! int || (parse['max_depth'] as int) <= 0)) {
      throw const FormatException('max_depth must be a positive integer.');
    }
    if (parse.containsKey('capture_source_locations') &&
        parse['capture_source_locations'] is! bool) {
      throw const FormatException(
        'capture_source_locations must be a boolean.',
      );
    }
    if (parse.containsKey('unknown_fields') &&
        !['preserve', 'reject'].contains(parse['unknown_fields'])) {
      throw const FormatException('unknown_fields must be preserve or reject.');
    }
  }
}

String _wire(Enum value) => value.name.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match[0]!.toLowerCase()}',
);
