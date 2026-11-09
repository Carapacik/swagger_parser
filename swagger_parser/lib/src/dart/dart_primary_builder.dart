part of 'dart_code_builder.dart';

// code_builder 4.13 has no primary class constructor node.
cb.Code _primaryDto(cb.Class model) {
  final emitter = cb.DartEmitter(useNullSafetySyntax: true);
  String emit(cb.Spec spec) => spec.accept(emitter).toString();
  final cb.Constructor primary = model.constructors.singleWhere(
    (c) => c.name == null,
  );
  final Map<String, cb.Field> fields = {
    for (final field in model.fields) field.name: field,
  };
  final result = StringBuffer()..writeln(model.docs.join('\n'));
  for (final cb.Expression annotation in model.annotations) {
    result.writeln('@${emit(annotation)}');
  }
  result.write(
    'class ${primary.constant ? 'const ' : ''}${model.name}(${primary.optionalParameters.isEmpty ? '' : '{'}',
  );
  for (final cb.Parameter parameter in primary.optionalParameters) {
    final cb.Field field = fields[parameter.name]!;
    result.writeln(field.docs.join('\n'));
    for (final cb.Expression annotation in field.annotations) {
      result.writeln('@${emit(annotation)}');
    }
    result.write(
      '${parameter.required ? 'required ' : ''}final ${emit(field.type!)} ${field.name}',
    );
    if (parameter.defaultTo case final value?) {
      result.write(' = ${emit(value)}');
    }
    result.writeln(',');
  }
  result.write('${primary.optionalParameters.isEmpty ? '' : '}'} )');
  if (model.mixins.isNotEmpty) {
    result.write(' with ${model.mixins.map(emit).join(',')}');
  }
  if (model.implements.isNotEmpty) {
    result.write(' implements ${model.implements.map(emit).join(',')}');
  }
  result.writeln('{');
  for (final cb.Field field in model.fields.where((f) => f.static)) {
    result.writeln(emit(field));
  }
  for (final cb.Constructor constructor in model.constructors.where(
    (c) => c != primary,
  )) {
    result.writeln(emitter.visitConstructor(constructor, model.name));
  }
  for (final cb.Method method in model.methods) {
    result.writeln(
      '${emit(method)}${method.lambda == true || method.body == null ? ';' : ''}',
    );
  }
  result.writeln('}');
  return cb.Code(result.toString());
}
