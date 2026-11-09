import 'package:swagger_parser/src/config/operation_filter_config.dart';
import 'package:swagger_parser/src/config/parameter_exclusion.dart';
import 'package:swagger_parser/src/extraction/api_definition.dart';
import 'package:swagger_parser/src/generation/generation_exception.dart';
import 'package:swagger_parser_core/swagger_parser_core.dart';

/// Selects operations in source order. Rejects invalid path patterns.
List<ApiOperation> selectOperations(
  List<ApiOperation> operations,
  OperationFilterConfig config,
) {
  List<_PathPattern> compile(List<String> patterns) => [
    for (final pattern in patterns) _PathPattern(pattern),
  ];
  final List<_PathPattern>? includes = config.includePaths == null
      ? null
      : compile(config.includePaths!);
  final List<_PathPattern> excludes = compile(config.excludePaths);
  return [
    for (final op in operations)
      if ((includes == null || includes.any((p) => p.matches(op.path))) &&
          (config.includeTags == null ||
              op.tags.any(config.includeTags!.contains)) &&
          !excludes.any((p) => p.matches(op.path)) &&
          !op.tags.any(config.excludeTags.contains))
        op,
  ];
}

final class _PathPattern(String pattern) {
  this {
    if (!OperationFilterConfig.isValidPathPattern(pattern)) {
      throw GenerationException('Invalid operation path pattern: $pattern.');
    }
  }

  final List<String> segments = _segments(pattern);

  static List<String> _segments(String path) =>
      path == '/' ? const [] : path.split('/').skip(1).toList();

  bool matches(String path) {
    final List<String> parts = _segments(path);
    final memo = <(int, int), bool>{};
    bool match(int patternIndex, int pathIndex) =>
        memo.putIfAbsent((patternIndex, pathIndex), () {
          if (patternIndex == segments.length) {
            return pathIndex == parts.length;
          }
          final String segment = segments[patternIndex];
          if (segment == '**') {
            return match(patternIndex + 1, pathIndex) ||
                pathIndex < parts.length &&
                    parts[pathIndex].isNotEmpty &&
                    match(patternIndex, pathIndex + 1);
          }
          return pathIndex < parts.length &&
              (segment == '*'
                  ? parts[pathIndex].isNotEmpty
                  : segment == parts[pathIndex]) &&
              match(patternIndex + 1, pathIndex + 1);
        });
    return match(0, 0);
  }
}

/// Excludes selected operation parameters without changing the source API.
/// Rejects invalid rules and reports excluded required parameters.
List<ApiOperation> excludeOperationParameters(
  List<ApiOperation> operations,
  List<ParameterExclusion> rules,
  List<Diagnostic> diagnostics,
) {
  for (final rule in rules) {
    if (rule.validationError case final error?) {
      throw GenerationException(error);
    }
  }
  if (rules.isEmpty) {
    return operations;
  }
  final Map<ParameterExclusion, List<_PathPattern>> patterns = {
    for (final rule in rules) rule: rule.paths.map(_PathPattern.new).toList(),
  };
  return [
    for (final op in operations)
      ApiOperation(
        method: op.method,
        path: op.path,
        source: op.source,
        parameters: op.parameters.where((parameter) {
          final bool excluded = rules.any(
            (rule) =>
                rule.location == parameter.location &&
                (rule.location == 'header'
                    ? rule.name.toLowerCase() == parameter.name.toLowerCase()
                    : rule.name == parameter.name) &&
                (rule.methods.isEmpty || rule.methods.contains(op.method)) &&
                (rule.paths.isEmpty ||
                    patterns[rule]!.any((p) => p.matches(op.path))),
          );
          if (excluded && parameter.isRequired) {
            diagnostics.add(
              Diagnostic(
                code: 'excludedRequiredParameter',
                severity: DiagnosticSeverity.warning,
                message:
                    '${op.method} ${op.path}: external code must supply '
                    '${parameter.location} parameter ${parameter.name}.',
                sourceUri: parameter.source.documentUri,
                documentPath: parameter.source.pointer,
              ),
            );
          }
          return !excluded;
        }),
        responses: op.responses,
        requestBody: op.requestBody,
        callbacks: op.callbacks,
        servers: op.servers,
        security: op.security,
        operationId: op.operationId,
        externalDocsUrl: op.externalDocsUrl,
        summary: op.summary,
        description: op.description,
        tags: op.tags,
        deprecated: op.deprecated,
      ),
  ];
}
