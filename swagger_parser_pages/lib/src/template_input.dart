import 'package:swagger_parser_templates/swagger_parser_templates.dart';
import 'package:yaml/yaml.dart';

/// Template text and helper files supplied by the browser editor.
final class const TemplateInput(
  /// File-kind or path overrides.
  final Map<String, String> overrides,

  /// Additional Dart files.
  final List<TemplateFile> files,
) {
  /// Stores parsed in-memory templates.
  this;

  /// Reads inline YAML or JSON. Invalid shapes throw [FormatException].
  factory parse(String source) {
    final Object? value = loadYaml(source);
    final Map<Object?, Object?> root = _map(value, 'templates', {
      'overrides',
      'files',
    });
    final overrides = <String, String>{};
    if (root.containsKey('overrides')) {
      final Object? raw = root['overrides'];
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw const FormatException(
          'overrides must be a mapping with string keys.',
        );
      }
      for (final MapEntry<dynamic, dynamic> entry in raw.entries) {
        overrides[entry.key as String] = _text(entry.value, 'Override source');
      }
    }
    final Object entries = root['files'] ?? const [];
    if (entries is! List) {
      throw const FormatException('files must be a list.');
    }
    final files = <TemplateFile>[];
    for (final Object? entry in entries) {
      final Map<Object?, Object?> file = _map(entry, 'file', {
        'output',
        'source',
        'export',
      });
      if (file.containsKey('export') && file['export'] is! bool) {
        throw const FormatException('export must be a boolean.');
      }
      files.add(
        TemplateFile(
          relativePath: _text(file['output'], 'Output path'),
          source: _text(file['source'], 'Helper source'),
          export: file['export'] as bool? ?? true,
        ),
      );
    }
    return TemplateInput(Map.unmodifiable(overrides), List.unmodifiable(files));
  }
}

Map<Object?, Object?> _map(Object? value, String name, Set<String> keys) {
  if (value is! Map || value.keys.any((key) => !keys.contains(key))) {
    throw FormatException('$name must be a mapping with ${keys.join(', ')}.');
  }
  return value.cast<Object?, Object?>();
}

String _text(Object? value, String name) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$name must be non-empty text.');
  }
  return value;
}

/// Example override and exported helper for the template workspace.
const String exampleTemplates = '''
overrides:
  client: |
    {{defaultSource}}
    abstract final class {{library.clientName}}Routes {
    {{#library.operations}}
      static const {{name}} = {{pathLiteral}};
    {{/library.operations}}
    }
files:
  - output: helpers/page.dart
    export: true
    source: |
      class Page<T> {
        const Page({required this.items});
        final List<T> items;
      }
''';
