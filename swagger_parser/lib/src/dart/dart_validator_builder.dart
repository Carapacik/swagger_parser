part of 'dart_code_builder.dart';

void _addValidators(cb.LibraryBuilder library, DartLibraryModel model) {
  final String error = model.validationErrorName;
  if (model.validationErrors) {
    library.body.add(
      cb.Class((c) {
        c
          ..name = error
          ..docs.add(
            '/// A failed constraint in the current JSON representation.',
          )
          ..constructors.add(
            cb.Constructor(
              (ctor) => ctor
                ..constant = true
                ..docs.add(
                  '/// Records a field path, schema keyword, and message.',
                )
                ..requiredParameters.addAll([
                  for (final name in ['path', 'keyword', 'message'])
                    cb.Parameter(
                      (p) => p
                        ..name = name
                        ..toThis = true,
                    ),
                ]),
            ),
          )
          ..fields.addAll([
            for (final (name, doc) in [
              (
                'path',
                'JSON Pointer. An empty string identifies the root value.',
              ),
              ('keyword', 'Failed schema keyword.'),
              ('message', 'Constraint failure without the input value.'),
            ])
              cb.Field(
                (f) => f
                  ..name = name
                  ..type = cb.refer('String')
                  ..modifier = cb.FieldModifier.final$
                  ..docs.add('/// $doc'),
              ),
          ]);
      }),
    );
  }
  if (model.validators.isEmpty) {
    return;
  }
  library.directives.add(cb.Directive.import(model.validationErrorImport!));
  for (final MapEntry<String, String> entry in model.validators.entries) {
    library.body.add(
      cb.Extension(
        (e) => e
          ..name = model.validatorExtensions[entry.key]
          ..on = cb.refer(entry.key)
          ..docs.add(
            '/// Validates the current JSON representation of [${entry.key}].',
          )
          ..methods.add(
            cb.Method(
              (m) => m
                ..name = 'validate'
                ..returns = cb.refer('List<$error>')
                ..docs.addAll([
                  '/// Returns constraint errors. An empty list means valid.',
                  '/// Encoding errors propagate. Does not validate discarded input fields.',
                ])
                ..body = cb.Code('''
final errors = <$error>[];
_validate${entry.value}(toJson(), '', errors);
final seen = <(String, String, String)>{};
return List.unmodifiable(errors.where((e) => seen.add((e.path, e.keyword, e.message))));
'''),
            ),
          ),
      ),
    );
  }
  final Map<String, DartSchemaMatcher> rules = {
    for (final rule in model.matchers) rule.name: rule,
  };
  final seen = <String>{};
  void visit(String name) {
    if (!seen.add(name)) {
      return;
    }
    final DartSchemaMatcher rule = rules[name]!;
    for (final String child in [
      ...rule.properties.values,
      ?rule.items,
      ...rule.prefixItems,
      ?rule.additional,
      ...rule.allOf,
      ...rule.oneOf,
      ...rule.anyOf,
    ]) {
      visit(child);
    }
  }

  model.validators.values.forEach(visit);
  library.body.addAll(seen.map((name) => _buildValidator(rules[name]!, error)));
}

cb.Method _buildValidator(DartSchemaMatcher rule, String error) {
  final body = StringBuffer()..writeln('if (${rule.name}(value)) return;');
  String pointer(String key) =>
      "path + ${_literal('/${key.replaceAll('~', '~0').replaceAll('/', '~1')}')}";
  void failure(String keyword, String message, {String path = 'path'}) {
    body.writeln(
      'errors.add($error($path, ${_literal(keyword)}, ${_literal(message)}));',
    );
  }

  if (rule.ignoredWireKeys.isNotEmpty) {
    body.writeln(
      'if (value is Map<String, Object?>) { value = {for (final entry in value.entries) if (!const <String>{${rule.ignoredWireKeys.map(_literal).join(',')}}.contains(entry.key)) entry.key: entry.value}; }',
    );
  }
  for (final _ConstraintCheck check in _localChecks(
    rule,
  ).where((check) => check.keyword != 'type')) {
    body.writeln('if (!(${check.test})) {');
    failure(check.keyword, check.message);
    if (check.keyword == 'type' || check.keyword == 'falseSchema') {
      body.writeln('return;');
    }
    body.writeln('}');
  }
  final List<Object?> required =
      rule.constraints['required'] as List<Object?>? ?? const [];
  if (rule.properties.isNotEmpty ||
      required.isNotEmpty ||
      rule.additional != null ||
      rule.constraints['additionalProperties'] == false) {
    body.writeln('if (value is Map<String, Object?>) {');
    for (final String key in required.cast<String>()) {
      body.writeln('if (!value.containsKey(${_literal(key)})) {');
      failure('required', 'Required property is missing.', path: pointer(key));
      body.writeln('}');
    }
    for (final MapEntry<String, String> entry in rule.properties.entries) {
      body.writeln(
        'if (value.containsKey(${_literal(entry.key)})) _validate${entry.value}(value[${_literal(entry.key)}], ${pointer(entry.key)}, errors);',
      );
    }
    if (rule.additional != null ||
        rule.constraints['additionalProperties'] == false) {
      body.writeln(
        'for (final entry in value.entries) { if (!const <String>{${rule.properties.keys.map(_literal).join(',')}}.contains(entry.key)) {',
      );
      const path =
          r"'$path/${entry.key.replaceAll('~', '~0').replaceAll('/', '~1')}'";
      if (rule.additional case final child?) {
        body.writeln('_validate$child(entry.value, $path, errors);');
      } else {
        failure('additionalProperties', 'Property is not allowed.', path: path);
      }
      body.writeln('}}');
    }
    body.writeln('}');
  }
  if (rule.items != null || rule.prefixItems.isNotEmpty) {
    body.writeln('if (value is List<Object?>) {');
    for (final (index, child) in rule.prefixItems.indexed) {
      body.writeln(
        "if (value.length > $index) _validate$child(value[$index], '\$path/$index', errors);",
      );
    }
    if (rule.items case final child?) {
      body.writeln(
        "for (var i = ${rule.prefixItems.length}; i < value.length; i++) { _validate$child(value[i], '\$path/\$i', errors); }",
      );
    }
    body.writeln('}');
  }
  for (final String child in rule.allOf) {
    body.writeln('_validate$child(value, path, errors);');
  }
  for (final (keyword, children) in [
    ('oneOf', rule.oneOf),
    ('anyOf', rule.anyOf),
  ]) {
    if (children.isEmpty) {
      continue;
    }
    body
      ..writeln(
        '{ final count = [${children.map((child) => 'if ($child(value)) 1').join(',')}].length;',
      )
      ..writeln('if (count ${keyword == 'oneOf' ? '!= 1' : '== 0'}) {');
    failure(
      keyword,
      keyword == 'oneOf'
          ? 'Exactly one branch must match.'
          : 'At least one branch must match.',
    );
    body.writeln('if (count == 0) {');
    for (final child in children) {
      body.writeln('_validate$child(value, path, errors);');
    }
    body.writeln('}}}');
  }
  for (final _ConstraintCheck check in _localChecks(
    rule,
  ).where((check) => check.keyword == 'type')) {
    body.writeln('if (!(${check.test})) {');
    failure(check.keyword, check.message);
    body.writeln('}');
  }
  return cb.Method(
    (m) => m
      ..name = '_validate${rule.name}'
      ..returns = cb.refer('void')
      ..requiredParameters.addAll([
        _matcherParameter('value', 'Object?'),
        _matcherParameter('path', 'String'),
        _matcherParameter('errors', 'List<$error>'),
      ])
      ..body = cb.Code(body.toString()),
  );
}
