part of 'dart_model_mapper.dart';

typedef _ConstantExpression = String Function(
  DartTypeReference type,
  Object? value,
  String path,
  Set<String> dependencies,
);

extension on _Mapping {
  DartArgumentDefault? _argumentDefault(
    _SchemaUse schema, {
    required bool required,
  }) {
    if (!config.applyParameterDefaults || required) {
      return null;
    }
    final JsonValue? value = _schemaDefault(schema);
    return value == null
        ? null
        : DartArgumentDefault(
            value: value,
            sourceUri: schema.location.documentUri,
            documentPath: schema.pointer,
          );
  }

  List<DartLibraryModel> _resolveArgumentDefaults(
    List<DartLibraryModel> clients,
    _ConstantExpression expression,
  ) {
    if (!config.applyParameterDefaults) {
      return clients;
    }
    DartArgumentDefault? resolve(
      DartArgumentDefault? value,
      DartTypeReference type,
      String path,
    ) {
      if (value == null) {
        return null;
      }
      final dependencies = <String>{};
      try {
        final String code = expression(
          type,
          value.value.value,
          path,
          dependencies,
        );
        return DartArgumentDefault(
          value: value.value,
          sourceUri: value.sourceUri,
          documentPath: value.documentPath,
          expression: code,
          dependencies: Set.unmodifiable(dependencies),
        );
      } on GenerationException catch (error) {
        throw GenerationException(
          error.message,
          diagnostics: [
            Diagnostic(
              code: 'invalidParameterDefault',
              severity: DiagnosticSeverity.error,
              message: error.message,
              sourceUri: value.sourceUri,
              documentPath: value.documentPath,
            ),
          ],
        );
      }
    }

    DartClientOperation operation(DartClientOperation op) =>
        DartClientOperation(
          name: op.name,
          operationId: op.operationId,
          tags: op.tags,
          externalDocsUrl: op.externalDocsUrl,
          method: op.method,
          path: op.path,
          status: op.status,
          response: op.response,
          objectResponse: op.objectResponse,
          summary: op.summary,
          description: op.description,
          deprecated: op.deprecated,
          mediaType: op.mediaType,
          extra: op.extra,
          objectTypes: op.objectTypes,
          variants: op.variants,
          emptySuccessStatuses: op.emptySuccessStatuses,
          parameters: [
            for (final p in op.parameters)
              DartClientParameter.at(
                name: p.name,
                documentation: p.documentation,
                wireName: p.wireName,
                type: p.type,
                location: p.location,
                isRequired: p.isRequired,
                pathStyle: p.pathStyle,
                explode: p.explode,
                listSeparator: p.listSeparator,
                queryListFormat: p.queryListFormat,
                rawCookie: p.rawCookie,
                allowReserved: p.allowReserved,
                contentType: p.contentType,
                scalarCodec: p.scalarCodec,
                isFormQueryObject: p.isFormQueryObject,
                objectShape: p.objectShape,
                defaultValue: resolve(
                  p.defaultValue,
                  p.type,
                  '${op.name}/${p.wireName}',
                ),
              ),
          ],
          body: switch (op.body) {
            null => null,
            final DartClientBody b => DartClientBody(
              type: b.type,
              documentation: b.documentation,
              isRequired: b.isRequired,
              isObjectDto: b.isObjectDto,
              mediaType: b.mediaType,
              fields: [
                for (final f in b.fields)
                  (
                    name: f.name,
                    documentation: f.documentation,
                    key: f.key,
                    type: f.type,
                    required: f.required,
                    contentType: f.contentType,
                    separator: f.separator,
                    file: f.file,
                    defaultValue: resolve(
                      f.defaultValue,
                      f.type,
                      '${op.name}/${f.key}',
                    ),
                  ),
              ],
            ),
          },
        );
    return [
      for (final client in clients)
        DartLibraryModel(
          relativePath: client.relativePath,
          dtos: const [],
          clientName: client.clientName,
          resultFile: client.resultFile,
          operations: client.operations.map(operation),
          results: client.results.map(operation),
        ),
    ];
  }
}
