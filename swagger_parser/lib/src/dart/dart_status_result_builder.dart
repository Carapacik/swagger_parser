part of 'dart_code_builder.dart';

void _buildStatusResults(
  cb.LibraryBuilder library,
  DartLibraryModel model,
  _SerializerBuilder packages,
) {
  final List<DartClientOperation> operations = model.results;
  final Set<String> qualified = {
    for (final op in operations)
      for (final variant in op.variants.values)
        if (variant.type case final type?) ..._bodyModels(type),
  };
  final useFreezed = packages.serializer == DtoSerializer.freezed;
  library.directives.addAll(
    _modelImports(model, qualified, prefix: useFreezed ? null : 'models').map(
      // Freezed reads nested copyWith helpers without an import prefix.
      (directive) =>
          useFreezed ? directive.rebuild((d) => d.show.clear()) : directive,
    ),
  );
  for (final op in operations) {
    library.body.add(
      cb.Class(
        (c) => c
          ..name = op.response.symbol
          ..sealed = true,
      ),
    );
    for (final MapEntry<String, DartStatusVariant> entry
        in op.variants.entries) {
      final DartStatusVariant variant = entry.value;
      final dynamicStatus = int.tryParse(entry.key) == null;
      library.body.add(
        packages.freezedClass(
          cb.Class((c) {
            c
              ..name = variant.name
              ..modifier = cb.ClassModifier.final$
              ..implements.add(cb.refer(op.response.symbol));
            if (dynamicStatus) {
              c.fields.add(
                cb.Field(
                  (f) => f
                    ..name = 'statusCode'
                    ..type = cb.refer('int')
                    ..modifier = cb.FieldModifier.final$,
                ),
              );
            }
            if (variant.type case final type?) {
              c.fields.add(
                cb.Field(
                  (f) => f
                    ..name = 'value'
                    ..type = _buildType(
                      type,
                      qualified: useFreezed ? const {} : qualified,
                    )
                    ..modifier = cb.FieldModifier.final$,
                ),
              );
            }
            c.constructors.add(
              cb.Constructor((ctor) {
                ctor.constant = true;
                if (dynamicStatus) {
                  ctor.requiredParameters.add(
                    cb.Parameter(
                      (p) => p
                        ..name = 'statusCode'
                        ..toThis = true,
                    ),
                  );
                }
                if (variant.type != null) {
                  ctor.requiredParameters.add(
                    cb.Parameter(
                      (p) => p
                        ..name = 'value'
                        ..toThis = true,
                    ),
                  );
                }
              }),
            );
          }),
        ),
      );
    }
  }
}
