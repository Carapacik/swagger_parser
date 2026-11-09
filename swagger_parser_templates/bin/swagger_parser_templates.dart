import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:swagger_parser/cli.dart';
import 'package:swagger_parser/swagger_parser.dart';
import 'package:swagger_parser_templates/swagger_parser_templates.dart';

/// Runs the generator with file-based Mustache templates.
Future<void> main(List<String> arguments) => runSwaggerParserCli(
  arguments,
  executable: 'swagger_parser_templates',
  extension: _Templates(),
);

final class _Templates() implements CliRendererExtension {
  @override
  String get option => 'templates';

  @override
  Future<DartSourceRenderer> load(Object? value, String directory) async {
    if (value is! Map) {
      throw const FormatException('generation.templates must be a mapping.');
    }
    final sources = <String, String>{};
    final files = <TemplateFile>[];
    for (final MapEntry<Object?, Object?> entry in value.entries) {
      final Object? key = entry.key;
      if (key == 'files') {
        if (entry.value is! List) {
          throw const FormatException(
            'generation.templates.files must be a list.',
          );
        }
        for (final Object? file in entry.value! as List) {
          if (file is! Map ||
              file.keys.any(
                (key) => !{'template', 'output', 'export'}.contains(key),
              ) ||
              file['template'] is! String ||
              (file['template'] as String).trim().isEmpty ||
              file['output'] is! String ||
              (file.containsKey('export') && file['export'] is! bool)) {
            throw const FormatException(
              'Specify template, output, and an optional boolean export for each helper.',
            );
          }
          files.add(
            TemplateFile(
              relativePath: file['output'] as String,
              source: await File(p.join(directory, file['template'] as String))
                  .readAsString(),
              export: file['export'] as bool? ?? true,
            ),
          );
        }
        continue;
      }
      final Object? path = entry.value;
      if (key is! String || path is! String || path.trim().isEmpty) {
        throw const FormatException('Specify a selector and template path.');
      }
      sources[key] = await File(p.join(directory, path)).readAsString();
    }
    return MustacheSourceRenderer(sources, files: files);
  }
}
