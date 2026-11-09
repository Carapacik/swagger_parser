part of 'dart_model_mapper.dart';

extension on _Mapping {
  DartDocumentation _schemaDocumentation(
    _SchemaUse schema, [
    Set<_SchemaUse> active = const {},
  ]) {
    if (active.contains(schema)) {
      return const DartDocumentation();
    }
    final next = {...active, schema};
    final List<DartDocumentation> inherited = [
      if (schema.reference case final target?)
        _schemaDocumentation(target, next),
      for (final child in schema.allOf) _schemaDocumentation(child, next),
    ];
    final bool legacyReference =
        schema.reference != null &&
        (schema.family == OpenApiFamily.swaggerV2 ||
            schema.family == OpenApiFamily.v30);
    final Map<String, Object?> fields = legacyReference
        ? const {}
        : schema.fields;
    String? text(String key) =>
        fields[key] is String ? fields[key]! as String : null;
    return DartDocumentation(
      summary: config.generateDocs
          ? text('summary') ??
                inherited.map((d) => d.summary).nonNulls.firstOrNull
          : null,
      description: config.generateDocs
          ? text('description') ??
                inherited.map((d) => d.description).nonNulls.firstOrNull
          : null,
      deprecated:
          fields['deprecated'] == true || inherited.any((d) => d.deprecated),
    );
  }

  DartDocumentation _parameterDocumentation(ApiParameter parameter) =>
      DartDocumentation(
        description: config.generateDocs ? parameter.description : null,
        deprecated: parameter.deprecated,
      );
}
