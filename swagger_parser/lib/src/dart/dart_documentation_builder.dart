part of 'dart_code_builder.dart';

Iterable<String> _dartdoc(DartDocumentation? documentation) sync* {
  if (documentation == null) {
    return;
  }
  final Iterable<String> paragraphs = [
    documentation.summary,
    documentation.description,
  ].nonNulls.where((s) => s.trim().isNotEmpty);
  for (final String line in const LineSplitter().convert(
    paragraphs.join('\n\n'),
  )) {
    yield line.isEmpty ? '///' : '/// $line';
  }
}

Iterable<cb.Expression> _deprecation(DartDocumentation? documentation) sync* {
  if (documentation?.deprecated ?? false) {
    yield cb.refer('Deprecated').call([
      cb.literalString('Deprecated in the API specification.'),
    ]);
  }
}

cb.Parameter _documentParameter(
  cb.Parameter parameter,
  DartDocumentation? doc,
) => parameter.rebuild(
  (p) => p
    ..docs.addAll(_dartdoc(doc))
    ..annotations.addAll(_deprecation(doc)),
);

cb.Spec _documentDeclaration(cb.Spec declaration, DartLibraryModel model) {
  if (declaration is cb.Class) {
    return _documentClass(declaration, model);
  }
  if (declaration is cb.Enum) {
    final DartDocumentation? doc = model.documentation[declaration.name];
    return declaration.rebuild(
      (e) => e
        ..docs.addAll(_dartdoc(doc))
        ..annotations.addAll(_deprecation(doc)),
    );
  }
  return declaration;
}

cb.Class _documentClass(cb.Class declaration, DartLibraryModel model) {
  final DartDocumentation? doc = model.documentation[declaration.name];
  final Map<String, DartDocumentation> members =
      model.fieldDocumentation[declaration.name] ?? const {};
  return declaration.rebuild((c) {
    c.docs.addAll(_dartdoc(doc));
    c.annotations.addAll(_deprecation(doc));
    c.fields.replace(
      declaration.fields.map(
        (field) => field.rebuild(
          (f) => f
            ..docs.addAll(_dartdoc(members[field.name]))
            ..annotations.addAll(_deprecation(members[field.name])),
        ),
      ),
    );
    c.methods.replace(
      declaration.methods.map(
        (method) => method.rebuild(
          (m) => m
            ..docs.addAll(_dartdoc(members[method.name]))
            ..annotations.addAll(_deprecation(members[method.name])),
        ),
      ),
    );
    c.constructors.replace(
      declaration.constructors.map((ctor) {
        final String? variant = ctor.name?.startsWith('as') == true
            ? ctor.name!.substring(2)
            : null;
        final Map<String, DartDocumentation> fields =
            model.fieldDocumentation[variant] ?? members;
        return ctor.rebuild((b) {
          b.docs.addAll(_dartdoc(model.documentation[variant]));
          b.annotations.addAll(_deprecation(model.documentation[variant]));
          b.optionalParameters.replace(
            ctor.optionalParameters.map(
              (p) => _documentParameter(p, fields[p.name]),
            ),
          );
          b.requiredParameters.replace(
            ctor.requiredParameters.map(
              (p) => _documentParameter(p, fields[p.name]),
            ),
          );
        });
      }),
    );
  });
}
