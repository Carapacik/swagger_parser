import 'dart:convert';

import 'package:dart_style/dart_style.dart' show FormatterException;
import 'package:mustache_template/mustache.dart';
import 'package:swagger_parser/swagger_parser.dart';

import 'package:swagger_parser_templates/src/template_file.dart';

part 'template_context.dart';

/// Renders Mustache source for selected output files.
final class MustacheSourceRenderer(
  Map<String, String> templates, {
  Iterable<TemplateFile> files = const [],
}) extends DartSourceRenderer {
  /// Copies overrides and extra files. Helper paths do not use file_suffix.
  this;

  final Map<String, String> _templates = Map.unmodifiable(templates);
  final List<TemplateFile> _files = List.unmodifiable(files);

  @override
  void validatePlan(GenerationPlan plan) {
    final paths = <String>{
      for (final file in plan.files) file.relativePath.toLowerCase(),
    };
    for (final TemplateFile file in _files) {
      final String path = file.relativePath;
      try {
        validateOutputPath(path);
        // Convert path API errors to CLI diagnostics.
        // ignore: avoid_catching_errors
      } on ArgumentError {
        throw GenerationException('Invalid template output path "$path".');
      }
      if (!path.endsWith('.dart') ||
          ['.g.dart', '.freezed.dart', '.mapper.dart'].any(path.endsWith)) {
        throw GenerationException(
          'Expected a Dart source path, not a build output: "$path".',
        );
      }
      final String key = path.toLowerCase();
      if (paths.any(
        (other) =>
            other == key ||
            other.startsWith('$key/') ||
            key.startsWith('$other/'),
      )) {
        throw GenerationException('Conflicting template output path "$path".');
      }
      paths.add(key);
    }
    final Set<String> selectors = {
      'api',
      'exports',
      'models',
      'client',
      'results',
      'support',
      for (final file in plan.files) file.relativePath,
    };
    for (final String key in _templates.keys) {
      if (!selectors.contains(key)) {
        throw GenerationException('Unknown template selector "$key".');
      }
    }
  }

  @override
  GeneratedFile render(PlannedDartFile file, GenerationConfig config) {
    final GeneratedFile built = super.render(file, config);
    final String source = file.relativePath == 'exports.dart'
        ? '${_helperExports()}${built.content}'
        : built.content;
    final String kind = _kind(file.model);
    final String selector = _templates.containsKey(file.relativePath)
        ? file.relativePath
        : kind;
    final String? template = _templates[selector];
    if (template == null) {
      return source == built.content
          ? built
          : GeneratedFile(
              relativePath: file.relativePath,
              content: formatSource(source, config),
            );
    }
    return _renderTemplate(
      template,
      selector,
      file.relativePath,
      _context(file.model, kind, config, source),
      config,
    );
  }

  String _helperExports() {
    final source = StringBuffer();
    for (final TemplateFile file in _files.where((file) => file.export)) {
      final String uri = jsonEncode(Uri(path: file.relativePath).toString())
          .replaceAll(r'$', r'\$');
      source.writeln('export $uri;');
    }
    return source.toString();
  }

  @override
  Iterable<GeneratedFile> renderAdditionalFiles(
    GenerationPlan plan,
    GenerationConfig config,
  ) sync* {
    if (_files.isEmpty) {
      return;
    }
    final List<Map<String, Object?>> contexts = [
      for (final planned in plan.files)
        _context(planned.model, _kind(planned.model), config, ''),
    ];
    for (final TemplateFile file in _files) {
      final Map<String, Object?> context = _context(
        DartLibraryModel(relativePath: file.relativePath, dtos: const []),
        'helper',
        config,
        '',
      );
      context['files'] = contexts;
      yield _renderTemplate(
        file.source,
        file.relativePath,
        file.relativePath,
        context,
        config,
      );
    }
  }

  GeneratedFile _renderTemplate(
    String template,
    String selector,
    String path,
    Map<String, Object?> context,
    GenerationConfig config,
  ) {
    try {
      final String source = Template(
        template,
        name: selector,
        htmlEscapeValues: false,
      ).renderString(context);
      return GeneratedFile(
        relativePath: path,
        content: formatSource(source, config),
      );
    } on TemplateException catch (e) {
      throw GenerationException(
        'Template "$selector" for $path at ${e.line}:${e.column}: ${e.message}',
      );
    } on FormatterException catch (e) {
      throw GenerationException(
        'Template "$selector" for $path: ${e.message()}',
      );
    }
  }
}
