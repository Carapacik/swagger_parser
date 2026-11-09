import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/src/cli/output_paths.dart';
import 'package:swagger_parser/src/cli/renderer_extension.dart';
import 'package:swagger_parser/src/cli/schema_download_config.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:yaml/yaml.dart';

/// Settings for one local generation run.
final class const CliConfig._(
  /// Batch input ID. Null for the single-input format.
  final String? inputId,

  /// Entry file or HTTP URL.
  final Uri input,

  /// Active config file, if present.
  final String? configFile,

  /// Absolute output directory.
  final String output,

  /// Origin-bound headers for HTTP schema retrieval.
  final SchemaDownloadConfig schemaDownload,

  /// Settings for the entry file and external references.
  final ParseConfig parse,

  /// Entry document normalization settings.
  final NormalizeConfig normalize,

  /// Renderer for this run.
  final DartSourceRenderer renderer,

  /// Dart generation settings.
  final GenerationConfig generation,
) {
  /// Loads one config file. Command-line paths override config paths.
  static Future<CliConfig> load({
    CliRendererExtension? extension,
    String? configPath,
    String? input,
    String? schemaUrl,
    String? schemaPath,
    String? output,
  }) async {
    final List<CliConfig> configs = await loadAll(
      extension: extension,
      configPath: configPath,
      input: input,
      schemaUrl: schemaUrl,
      schemaPath: schemaPath,
      output: output,
    );
    if (configs.length != 1) {
      throw const FormatException('Use CliConfig.loadAll for multiple inputs.');
    }
    return configs.single;
  }

  /// Loads single-input or batch config. Child fields override shared settings.
  /// Lists replace inherited lists. Rejects overlapping output directories.
  static Future<List<CliConfig>> loadAll({
    CliRendererExtension? extension,
    String? configPath,
    String? input,
    String? schemaUrl,
    String? schemaPath,
    String? output,
  }) async {
    final String? file =
        configPath ??
        [
          'swagger_parser.yaml',
          'pubspec.yaml',
        ].where((name) => File(name).existsSync()).firstOrNull;
    var root = const _Options({}, 'configuration');
    if (file != null) {
      final source = File(file);
      try {
        final String text = await source.readAsString();
        final Object? value = p.extension(file).toLowerCase() == '.json'
            ? jsonDecode(text)
            : loadYaml(text, sourceUrl: source.absolute.uri);
        final section = _Options.map(value, file);
        if (p.basename(file) == 'pubspec.yaml' ||
            section.values.containsKey('swagger_parser')) {
          if (p.basename(file) != 'pubspec.yaml') {
            section.check({'swagger_parser'});
          }
          root = section.section('swagger_parser');
        } else {
          root = section;
        }
      } on YamlException catch (e) {
        throw FormatException(e.message);
      } on FormatException catch (e) {
        throw FormatException('$file: ${e.message}');
      }
    }
    if (!root.values.containsKey('inputs')) {
      return [
        await _fromOptions(
          root,
          file,
          extension: extension,
          input: input,
          schemaUrl: schemaUrl,
          schemaPath: schemaPath,
          output: output,
        ),
      ];
    }
    root.check({
      'inputs',
      'output',
      'output_directory',
      'parse',
      'normalize',
      'generation',
      'schema_download',
    });
    final _Options inputs = root.section('inputs');
    if (inputs.values.isEmpty) {
      throw const FormatException('inputs must contain at least one input.');
    }
    if (inputs.values.length > 1 &&
        [input, schemaUrl, schemaPath, output].any((value) => value != null)) {
      throw const FormatException(
        'Source and output overrides require one input.',
      );
    }
    final String? outputKey = root.oneOf(['output', 'output_directory']);
    final String baseOutput = outputKey == null
        ? 'lib/generated'
        : root.path(outputKey);
    final configs = <CliConfig>[];
    for (final MapEntry<String, Object?> entry in inputs.values.entries) {
      final String id = entry.key;
      if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(id)) {
        throw FormatException(
          'Invalid input ID: $id. Use lowercase letters, digits, and underscores.',
        );
      }
      try {
        final child = _Options.map(entry.value, '${inputs.location}.$id');
        final String? childOutput = child.oneOf(['output', 'output_directory']);
        final effective = _Options({
          ...child.values,
          if (childOutput == null) 'output_directory': p.join(baseOutput, id),
          for (final section in [
            'parse',
            'normalize',
            'generation',
            'schema_download',
          ])
            section: _mergeOptions(
              root.section(section),
              child.section(section),
            ),
        }, child.location);
        configs.add(
          await _fromOptions(
            effective,
            file,
            inputId: id,
            extension: extension,
            input: input,
            schemaUrl: schemaUrl,
            schemaPath: schemaPath,
            output: output,
          ),
        );
      } on FormatException catch (error) {
        throw FormatException('[$id] ${error.message}');
      }
    }
    validateOutputPaths({
      for (final config in configs) config.inputId!: config.output,
    });
    return List.unmodifiable(configs);
  }

  static Map<String, Object?> _mergeOptions(_Options shared, _Options child) {
    final Map<String, Object?> base = shared.canonical().values;
    final Map<String, Object?> overrides = child.canonical().values;
    return {
      ...base,
      ...overrides,
      for (final key in ['naming', 'operation_filters'])
        if (base.containsKey(key) && overrides.containsKey(key))
          key: _mergeOptions(
            shared.canonical().section(key),
            child.canonical().section(key),
          ),
      if (base['templates'] is Map && overrides['templates'] is Map)
        'templates': {
          ...base['templates']! as Map,
          ...overrides['templates']! as Map,
        },
    };
  }

  static Future<CliConfig> _fromOptions(
    _Options root,
    String? file, {
    String? inputId,
    CliRendererExtension? extension,
    String? input,
    String? schemaUrl,
    String? schemaPath,
    String? output,
  }) async {
    root.check({
      'input',
      'schema_url',
      'schema_path',
      'output',
      'output_directory',
      'parse',
      'normalize',
      'generation',
      'schema_download',
    });
    final pipeline = PipelineConfig.fromMap(
      root.values,
      extensionOptions: {?extension?.option},
    );
    final _Options generation = root.section('generation').canonical();
    final String base = file == null ? p.current : p.dirname(p.absolute(file));
    final command = _Options({
      'input': ?input,
      'schema_url': ?schemaUrl,
      'schema_path': ?schemaPath,
    }, 'command line');
    const sources = ['input', 'schema_url', 'schema_path'];
    final String? configured = root.oneOf(sources);
    final String? argument = command.oneOf(sources);
    final String? key = argument ?? configured;
    if (key == null) {
      throw const FormatException('Specify a schema path or URL.');
    }
    final String value = (argument == null ? root : command).path(key);
    final Uri source;
    if (key == 'schema_url' ||
        key == 'input' &&
            RegExp(
              '^[a-z][a-z0-9+.-]*://',
              caseSensitive: false,
            ).hasMatch(value)) {
      source = Uri.parse(value);
      if (!{'http', 'https'}.contains(source.scheme) ||
          source.host.isEmpty ||
          source.hasFragment ||
          source.userInfo.isNotEmpty) {
        throw const FormatException(
          'Expected an HTTP or HTTPS schema URL without userinfo or a fragment.',
        );
      }
    } else {
      source = File(p.join(argument == null ? base : p.current, value))
          .absolute
          .uri;
    }
    final String? outputKey = root.oneOf(['output', 'output_directory']);
    final String directory =
        output ?? (outputKey == null ? 'lib/generated' : root.path(outputKey));
    if (directory.trim().isEmpty) {
      throw const FormatException('Specify a non-empty output path.');
    }
    return CliConfig._(
      inputId,
      source,
      file == null ? null : p.absolute(file),
      p.normalize(p.join(output == null ? base : p.current, directory)),
      _schemaDownload(root.section('schema_download')),
      pipeline.parse,
      pipeline.normalize,
      extension != null && generation.values.containsKey(extension.option)
          ? await extension.load(generation.values[extension.option], base)
          : const DartSourceRenderer(),
      pipeline.generation,
    );
  }

  static SchemaDownloadConfig _schemaDownload(_Options section) {
    final _Options options = section.canonical()..check({'credentials'});
    final List<Object?> values =
        options.get<List<Object?>>('credentials') ?? const [];
    final origins = <String>{};
    final records = <SchemaDownloadCredential>[];
    for (final (i, value) in values.indexed) {
      final location = '${options.location}.credentials[$i]';
      final rule = _Options.map(value, location)..check({'origin', 'headers'});
      final String? text = rule.get<String>('origin');
      final Uri? uri = text == null ? null : Uri.tryParse(text);
      if (uri == null ||
          !{'http', 'https'}.contains(uri.scheme) ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          uri.host.contains('*') ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          (uri.path.isNotEmpty && uri.path != '/') ||
          uri.port < 1 ||
          uri.port > 65535) {
        throw FormatException(
          'Expected an HTTP(S) origin at $location.origin.',
        );
      }
      final origin = Uri(scheme: uri.scheme, host: uri.host, port: uri.port);
      if (!origins.add(origin.origin)) {
        throw FormatException('Duplicate origin at $location.origin.');
      }
      if (!rule.values.containsKey('headers')) {
        throw FormatException('Missing $location.headers.');
      }
      final _Options headers = rule.section('headers');
      final resolved = <String, SchemaDownloadHeader>{};
      for (final MapEntry<String, Object?> entry in headers.values.entries) {
        final String name = entry.key.toLowerCase();
        if (!RegExp(r"^[!#$%&'*+.^_`|~0-9a-z-]+$").hasMatch(name) ||
            const {
              'host',
              'content-length',
              'connection',
              'transfer-encoding',
              'proxy-authorization',
              'proxy-authenticate',
              'te',
              'trailer',
              'upgrade',
            }.contains(name)) {
          throw FormatException('Invalid header name at $location.headers.');
        }
        if (resolved.containsKey(name)) {
          throw FormatException('Duplicate header at $location.headers.');
        }
        final Object? header = entry.value;
        if (header is String) {
          if (!SchemaDownloadHeader.isValidValue(header)) {
            throw FormatException('Invalid header value at $location.headers.');
          }
          resolved[name] = SchemaDownloadHeader(value: header);
        } else {
          final env = _Options.map(header, '$location.headers.$name')
            ..check({'env'});
          final String? variable = env.get<String>('env');
          if (variable == null ||
              !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(variable)) {
            throw FormatException(
              'Expected an environment variable name at ${env.location}.env.',
            );
          }
          resolved[name] = SchemaDownloadHeader(env: variable);
        }
      }
      records.add(SchemaDownloadCredential(origin, Map.unmodifiable(resolved)));
    }
    return SchemaDownloadConfig(credentials: List.unmodifiable(records));
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
