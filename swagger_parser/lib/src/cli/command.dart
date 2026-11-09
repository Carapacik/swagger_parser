import 'dart:io';

import 'package:args/args.dart';
import 'package:swagger_parser/src/cli/cli_config.dart';
import 'package:swagger_parser/src/cli/output_paths.dart';
import 'package:swagger_parser/src/cli/output_writer.dart';
import 'package:swagger_parser/src/cli/remote_schema_loader.dart';
import 'package:swagger_parser/src/cli/renderer_extension.dart';
import 'package:swagger_parser/swagger_parser.dart';

/// Generates Dart libraries from an OpenAPI file or URL.
Future<void> runSwaggerParserCli(
  List<String> arguments, {
  CliRendererExtension? extension,
  String executable = 'swagger_parser',
}) async {
  final parser = ArgParser()
    ..addOption('file', abbr: 'f', help: 'Read this configuration file.')
    ..addOption('schema_url', help: 'Download an HTTP or HTTPS schema.')
    ..addOption('schema_path', help: 'Read a local schema.')
    ..addOption(
      'output',
      aliases: ['output_directory'],
      abbr: 'o',
      help: 'Write Dart files to this directory.',
    )
    ..addFlag(
      'check',
      negatable: false,
      help: 'Check generated files for changes.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show command usage.');
  final usage =
      'Usage: dart run $executable [--check] [options] [schema-path-or-url]\n'
      '       dart run $executable validate [options] [schema-path-or-url]';
  final bool validate;
  final bool check;
  final List<CliConfig> configs;
  try {
    final ArgResults args = parser.parse(arguments);
    if (args.flag('help')) {
      stdout.writeln('$usage\n\n${parser.usage}');
      return;
    }
    validate = args.rest.firstOrNull == 'validate';
    check = args.flag('check');
    if (validate && check) {
      throw const FormatException('Choose validate or --check.');
    }
    final Iterable<String> inputs = validate ? args.rest.skip(1) : args.rest;
    if (inputs.length > 1) {
      throw const FormatException('Expected one schema path.');
    }
    configs = await CliConfig.loadAll(
      extension: extension,
      configPath: args.option('file'),
      input: inputs.firstOrNull,
      schemaUrl: args.option('schema_url'),
      schemaPath: args.option('schema_path'),
      output: args.option('output'),
    );
  } on FormatException catch (error) {
    stderr.writeln('${error.message}\n$usage');
    exitCode = 64;
    return;
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
    return;
  }

  final pending = <(CliConfig, GenerationResult)>[];
  var failed = false;
  for (final config in configs) {
    final prefix = config.inputId == null ? '' : '[${config.inputId}] ';
    final loader = RemoteSchemaLoader(
      config: config.schemaDownload,
      allowFiles: config.input.scheme == 'file',
    );
    try {
      final runner = SwaggerParserRunner(
        generator: DartGenerator(renderer: config.renderer),
        normalizer: config.normalize.explicitParameterSerialization
            ? OpenApiNormalizer(config: config.normalize)
            : null,
      );
      final SchemaSource source =
          config.input.scheme != 'file' && !check && !validate
          ? await loader.download(
              config.input,
              configFile: config.configFile,
              inputId: config.inputId,
              protectedPaths: configs
                  .where((c) => c.input.scheme == 'file')
                  .map((c) => c.input.toFilePath()),
            )
          : await loader.load(config.input);
      if (validate) {
        _diagnostics(
          await runner.validate(
            source,
            loader: loader,
            parseConfig: config.parse,
          ),
          prefix,
          loader.redact,
        );
        stdout.writeln('${prefix}Valid OpenAPI document.');
        continue;
      }
      final GenerationResult result = await runner.generate(
        source,
        loader: loader,
        config: config.generation,
        parseConfig: config.parse,
      );
      _diagnostics(result.diagnostics, prefix, loader.redact);
      if (result.diagnostics.any(
        (d) => d.severity == DiagnosticSeverity.error,
      )) {
        failed = true;
      } else {
        pending.add((config, result));
      }
    } on GenerationException catch (error) {
      stderr.writeln(loader.redact('$prefix${error.message}'));
      _diagnostics(error.diagnostics, prefix, loader.redact);
      failed = true;
    } on OpenApiException catch (error) {
      final code = error is ReferenceResolutionException
          ? ' [${error.code}]'
          : '';
      stderr.writeln(
        loader.redact(
          '$prefix${_errorLocation(error, config.input)} error$code: ${error.message}',
        ),
      );
      if (error.cause case final OpenApiException cause) {
        stderr.writeln(
          loader.redact(
            '$prefix${_errorLocation(cause, config.input)}: ${cause.message}',
          ),
        );
      }
      failed = true;
    } on FileSystemException catch (error) {
      stderr.writeln(config.schemaDownload.redact('$prefix$error'));
      failed = true;
    } finally {
      loader.close();
    }
  }
  if (failed || validate) {
    if (failed) {
      exitCode = 1;
    }
    return;
  }

  // Check every destination before replacing any generated file.
  for (final (config, result) in pending) {
    final prefix = config.inputId == null ? '' : '[${config.inputId}] ';
    try {
      resolveOutputPath(config.output);
      final List<String> differences = await checkOutput(
        Directory(config.output),
        result.files,
      );
      if (check) {
        if (differences.isEmpty) {
          stdout.writeln('${prefix}Generated files are up to date.');
        } else {
          stderr.writeln(differences.map((line) => '$prefix$line').join('\n'));
          failed = true;
        }
      } else {
        final String? conflict = differences
            .where((line) => line.startsWith('Conflict: '))
            .firstOrNull;
        if (conflict != null) {
          throw FileSystemException(
            'Output path already exists',
            Directory(config.output).uri
                .resolve(conflict.substring('Conflict: '.length))
                .toFilePath(),
          );
        }
      }
    } on FileSystemException catch (error) {
      stderr.writeln(config.schemaDownload.redact('$prefix$error'));
      failed = true;
    }
  }
  if (failed || check) {
    if (failed) {
      exitCode = 1;
    }
    return;
  }
  for (final (config, result) in pending) {
    final prefix = config.inputId == null ? '' : '[${config.inputId}] ';
    try {
      await writeOutput(Directory(config.output), result.files);
      stdout.writeln(
        '${prefix}Generated ${result.files.length} files in ${config.output}.',
      );
    } on FileSystemException catch (error) {
      stderr.writeln(config.schemaDownload.redact('$prefix$error'));
      exitCode = 1;
      return;
    }
  }
}

String _errorLocation(OpenApiException error, Uri input) {
  final SourceLocation? location = error.location;
  final point = location == null ? '' : ':${location.line}:${location.column}';
  final String pointer = error.documentPath ?? '';
  return '${error.sourceUri ?? input}$point${pointer.isEmpty ? '' : '#$pointer'}';
}

void _diagnostics(
  List<Diagnostic> diagnostics, [
  String prefix = '',
  String Function(String)? redact,
]) {
  for (final d in diagnostics) {
    final message =
        '$prefix${d.sourceUri ?? ''}${d.documentPath == null ? '' : '#${d.documentPath}'} ${d.severity.name} [${d.code}] ${d.message}';
    stderr.writeln(redact == null ? message : redact(message));
  }
}
