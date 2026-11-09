part of 'dart_code_builder.dart';

bool _hasScalarCodec(DartTypeReference type) =>
    type.scalarCodec != null || type.typeArguments.any(_hasScalarCodec);

String _bodyWire(DartTypeReference type, String value) =>
    _hasScalarCodec(type) ? '(${_encode(type, value)})' : value;

String _parameterWire(DartTypeReference type, String value) =>
    _needsParameterCodec(type) ? '(${_encode(type, value)})' : value;

bool _needsParameterCodec(DartTypeReference type) =>
    type.scalarCodec != null ||
    !const {
      'String',
      'int',
      'num',
      'bool',
      'Object',
      'Null',
      'List',
      'Map',
    }.contains(type.symbol) ||
    type.typeArguments.any(_needsParameterCodec);

Iterable<DartTypeReference> _libraryTypes(DartLibraryModel model) sync* {
  for (final DartDtoModel dto in model.dtos) {
    yield* dto.fields.map((f) => f.type);
    if (dto.extraValueType case final type?) {
      yield type;
    }
  }
  yield* model.values.map((v) => v.type);
  for (final DartTupleModel tuple in model.tuples) {
    yield* tuple.positions;
    if (tuple.restType case final type?) {
      yield type;
    }
  }
  for (final DartStructuralUnion union in model.structuralUnions) {
    yield* union.branches.map((b) => b.type);
  }
  for (final DartClientOperation op in model.operations) {
    yield op.response;
    yield* op.parameters.map((p) => p.type);
    for (final DartStatusVariant variant in op.variants.values) {
      if (variant.type case final type?) {
        yield type;
      }
    }
    if (op.body case final body?) {
      yield body.type;
      yield* body.fields.map((f) => f.type);
    }
  }
  for (final DartClientOperation op in model.results) {
    for (final DartStatusVariant variant in op.variants.values) {
      if (variant.type case final type?) {
        yield type;
      }
    }
  }
}

List<DartSchemaMatcher> _addScalarCodecs(
  cb.LibraryBuilder library,
  DartLibraryModel model,
) {
  final codecs = <String, DartScalarCodec>{};
  void collect(DartTypeReference type) {
    if (type.scalarCodec case final codec?) {
      codecs[codec.adapter] = codec;
    }
    type.typeArguments.forEach(collect);
  }

  _libraryTypes(model).forEach(collect);
  final reads = <String>{};
  final writes = <String>{};
  void use(DartTypeReference type, Set<String> used) {
    if (type.scalarCodec case final codec?) {
      used.add(codec.adapter);
    }
    for (final DartTypeReference child in type.typeArguments) {
      use(child, used);
    }
  }

  for (final DartDtoModel dto in model.dtos) {
    for (final DartFieldModel field in dto.fields) {
      use(field.type, reads);
      if (field.fixedValue == null) {
        use(field.type, writes);
      }
    }
    if (dto.extraValueType case final type?) {
      use(type, reads);
      use(type, writes);
    }
  }
  for (final DartValueModel value in model.values) {
    use(value.type, reads);
    use(value.type, writes);
  }
  for (final DartTupleModel tuple in model.tuples) {
    for (final DartTypeReference type in [
      ...tuple.positions,
      ?tuple.restType,
    ]) {
      use(type, reads);
    }
  }
  for (final DartStructuralUnion union in model.structuralUnions) {
    for (final DartMatchBranch branch in union.branches) {
      use(branch.type, reads);
      if (union.exclusive && branch.implementation != branch.type.symbol) {
        use(branch.type, writes);
      }
    }
  }
  for (final DartClientOperation op in model.operations) {
    use(op.response, reads);
    for (final DartStatusVariant variant in op.variants.values) {
      if (variant.type case final type?) {
        use(type, reads);
      }
    }
    for (final DartClientParameter parameter in op.parameters) {
      use(parameter.type, writes);
    }
    if (op.body case final body?) {
      use(body.type, writes);
      for (final DartFormField field in body.fields) {
        use(field.type, writes);
      }
    }
  }
  final imports = <String, String>{...model.constantImports};
  final predicates = <DartSchemaMatcher>[];
  final bool declarationsOnly =
      model.results.isNotEmpty && model.operations.isEmpty;
  for (final DartScalarCodec codec in codecs.values) {
    imports[codec.typeImport] = codec.typePrefix;
    if (declarationsOnly) {
      continue;
    }
    imports[codec.codecImport] = codec.codecPrefix;
    predicates.addAll(codec.matchers);
    final type = '${codec.typePrefix}.${codec.dartType}';
    final read = codec.wireType == 'int'
        ? '(value as num).toInt()'
        : 'value as ${codec.wireType}';
    library.body.add(
      cb.Code('''
abstract final class ${codec.adapter} {
  ${reads.contains(codec.adapter) ? '''
static $type read(Object? value) {
    if (!${codec.matcher}(value) || value == null) {
      throw ArgumentError(${_literal('Invalid ${codec.dartType} wire value.')});
    }
    return ${codec.codecPrefix}.${codec.fromJson}($read);
  }''' : ''}
  ${writes.contains(codec.adapter) ? '''
static ${codec.wireType} write($type value) {
    final ${codec.wireType} wire = ${codec.codecPrefix}.${codec.toJson}(value);
    if (!${codec.matcher}(wire)) {
      throw ArgumentError(${_literal('Invalid ${codec.dartType} wire value.')});
    }
    return wire;
  }''' : ''}
}
'''),
    );
  }
  library.directives.addAll([
    // A prefixed core import disables Dart's implicit unprefixed import.
    if (imports.containsKey('dart:core')) cb.Directive.import('dart:core'),
    for (final entry in imports.entries)
      cb.Directive.import(entry.key, as: entry.value),
  ]);
  return predicates;
}
