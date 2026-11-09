part of 'dart_code_builder.dart';

String _attachMetadata(String? reference) => reference == null
    ? ''
    : "extra = {...extra, 'openapi.operation': $reference};";

void _buildMetadata(cb.LibraryBuilder library, DartLibraryModel model) {
  if (model.apiMetadata) {
    final String name = model.metadataTypeName;
    library.body.add(
      cb.Code('''
/// Source metadata for a generated HTTP operation.
final class $name {
  /// Records the source values and final Dart method name.
  const $name({
    required this.methodName,
    required this.method,
    required this.path,
    this.operationId,
    this.tags = const [],
    this.externalDocsUrl,
    this.deprecated = false,
  });

  /// Final Dart method name.
  final String methodName;

  /// Source operationId, or null when absent.
  final String? operationId;

  /// HTTP method in wire case.
  final String method;

  /// Mounted path template with parameter placeholders.
  final String path;

  /// Original tags in source order.
  final List<String> tags;

  /// Operation documentation URL, or null when absent.
  final String? externalDocsUrl;

  /// Whether the source operation is deprecated.
  final bool deprecated;
}
'''),
    );
  }
  if (model.metadataOperations.isEmpty) {
    return;
  }
  library.directives.add(
    cb.Directive.import(
      p.posix.relative(
        model.metadataTypePath,
        from: p.posix.dirname(model.relativePath),
      ),
      as: '_metadata',
    ),
  );
  library.body.add(
    cb.Code('''
/// Source metadata for the generated client operations.
abstract final class ${model.clientMetadataName} {
${model.metadataOperations.map((op) => '''
  /// Source metadata for ${op.name}.
  static const ${op.name} = _metadata.${model.metadataTypeName}(
    methodName: ${_literal(op.name)},
    operationId: ${_literal(op.operationId)},
    method: ${_literal(op.method)},
    path: ${_literal(op.path)},
    tags: ${_literal(op.tags)},
    externalDocsUrl: ${_literal(op.externalDocsUrl)},
    deprecated: ${op.deprecated},
  );
''').join()}
}
'''),
  );
}
