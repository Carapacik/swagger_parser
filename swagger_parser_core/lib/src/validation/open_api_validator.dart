import 'package:swagger_parser_core/src/diagnostics/diagnostic.dart';
import 'package:swagger_parser_core/src/model/open_api_document.dart';
import 'package:swagger_parser_core/src/model/open_api_version.dart';
import 'package:swagger_parser_core/src/parser/decoder/source_decoder.dart';
import 'package:swagger_parser_core/src/parser/uri_reference.dart';
import 'package:swagger_parser_core/src/references/open_api_reference_resolver.dart';
import 'package:swagger_parser_core/src/traversal/document_node.dart';
import 'package:swagger_parser_core/src/traversal/located_node.dart';

part 'operation_checks.dart';

/// The diagnostics from one validation pass.
final class ValidationReport(Iterable<Diagnostic> diagnostics) {
  /// Copies the diagnostics from one validation pass.
  this;

  /// Diagnostics collected during processing.
  final List<Diagnostic> diagnostics = List.unmodifiable(diagnostics);

  /// Whether the report includes an error diagnostic.
  bool get hasErrors => diagnostics.any(
    (diagnostic) => diagnostic.severity == DiagnosticSeverity.error,
  );
}

/// Checks a document and reports validation diagnostics.
class const OpenApiValidator() {
  /// Creates a validator for all supported document families.
  this;

  /// Checks operation IDs, path templates, parameter lists, and tag declarations.
  ValidationReport validate(OpenApiDocument document) =>
      _Validation(document.version.family).check(document.toJson());
}

/// Checks operations reachable from paths, webhooks, and callbacks.
class const ResolvedOperationValidator() {
  /// Creates a validator for operations in a resolved description.
  this;

  /// Checks effective parameters and operation IDs.
  /// Supply the graph resolved from [document].
  ValidationReport validate(
    OpenApiDocument document,
    ReferenceGraph references,
  ) => ValidationReport(
    _OperationChecks(
      document.toJson(),
      document.version.family,
      references,
    ).check(),
  );
}

final class _Validation(final OpenApiFamily family) {
  final diagnostics = <Diagnostic>[];

  ValidationReport check(Map<String, Object?> root) {
    _tags(root['tags']);
    if (root['paths'] case final Map<String, Object?> entries) {
      final patterns = <String>{};
      for (final String path in entries.keys.where(
        (key) => key.startsWith('/'),
      )) {
        final String pointer = appendPointer('/paths', path);
        if (!patterns.add(path.replaceAll(_pathExpression, '{}'))) {
          _error(
            'duplicatePathTemplate',
            'Equivalent path template: $path.',
            pointer,
          );
        }
      }
    }
    diagnostics.addAll(_OperationChecks(root, family, null).check());
    return ValidationReport(diagnostics);
  }

  void _tags(Object? data) {
    if (data is! List<Object?>) {
      return;
    }
    final indices = <String, int>{};
    final parents = <String, String>{};
    for (var i = 0; i < data.length; i++) {
      if (data[i] case {'name': final String name}) {
        if (indices.containsKey(name)) {
          _error('duplicateTag', 'Duplicate tag: $name.', '/tags/$i/name');
          continue;
        }
        indices[name] = i;
        if ((family, data[i]) case (
          OpenApiFamily.v32,
          {'parent': final String parent},
        )) {
          parents[name] = parent;
        }
      }
    }
    final checked = <String>{};
    for (final String name in parents.keys) {
      final chain = <String>{};
      var tag = name;
      while (!checked.contains(tag)) {
        final String? parent = parents[tag];
        if (parent == null) {
          break;
        }
        chain.add(tag);
        final pointer = '/tags/${indices[tag]}/parent';
        if (!indices.containsKey(parent)) {
          _error('unknownTagParent', 'Unknown parent tag: $parent.', pointer);
          break;
        }
        if (chain.contains(parent)) {
          _error('cyclicTagParent', 'Parent tag cycle at $parent.', pointer);
          break;
        }
        tag = parent;
      }
      checked.addAll(chain);
    }
  }

  void _error(String code, String message, String path) {
    diagnostics.add(
      Diagnostic(
        code: code,
        message: message,
        severity: DiagnosticSeverity.error,
        documentPath: path,
      ),
    );
  }
}
