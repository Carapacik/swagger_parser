part of 'dart_code_builder.dart';

void _addMatchers(
  cb.LibraryBuilder library,
  List<DartSchemaMatcher> rules,
  Set<String> roots,
) {
  library.body.addAll(rules.map(_buildMatcher));
  if (roots.isNotEmpty) {
    final Map<String, DartSchemaMatcher> byName = {
      for (final rule in rules) rule.name: rule,
    };
    final seen = <String>{};
    void visit(String name) {
      if (!seen.add(name)) {
        return;
      }
      final DartSchemaMatcher rule = byName[name]!;
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

    roots.forEach(visit);
    final Iterable<DartSchemaMatcher> projected = seen.map(
      (name) => byName[name]!,
    );
    library.body.addAll(projected.map(_buildProjection));
    if (projected.any(
      (rule) => rule.oneOf.isNotEmpty || rule.anyOf.isNotEmpty,
    )) {
      library.body.add(_intersectProjection());
    }
  }
  if (rules.any((rule) => rule.contains != null && rule.acceptsType('array'))) {
    library.body.add(_containsCountMethod());
  }
  final bool unique = rules.any((rule) => rule.checksUniqueItems);
  final bool multiples = rules.any((rule) => rule.multipleOf != null);
  if (!unique && !multiples) {
    return;
  }
  // Keep the SDK type accessible when a schema declares BigInt.
  library.directives.addAll([
    cb.Directive.import('dart:core'),
    cb.Directive.import('dart:core', as: '_core', show: const ['BigInt']),
  ]);
  library.body.addAll([
    _decimalPartsMethod(),
    if (unique) _uniqueItemsMethod(),
    if (multiples) _multipleOfMethod(),
  ]);
}

extension on DartSchemaMatcher {
  bool acceptsType(String type) =>
      !reject && (types.isEmpty || types.contains(type));

  bool get checksUniqueItems =>
      constraints['uniqueItems'] == true && acceptsType('array');

  num? get multipleOf => acceptsType('number') || acceptsType('integer')
      ? constraints['multipleOf'] as num?
      : null;
}

// Shared checks keep union predicates and public validators consistent.
typedef _ConstraintCheck = ({String keyword, String test, String message});

List<_ConstraintCheck> _localChecks(DartSchemaMatcher rule) {
  final checks = <_ConstraintCheck>[];
  void add(String keyword, String test, String message, [String? type]) {
    if (type != null &&
        !rule.acceptsType(type) &&
        !(type == 'number' && rule.acceptsType('integer'))) {
      return;
    }
    checks.add((
      keyword: keyword,
      test: type == null
          ? test
          : 'value is! ${_jsonDartTypes[type]} || ($test)',
      message: message,
    ));
  }

  final Map<String, Object?> c = rule.constraints;
  if (rule.reject) {
    add('falseSchema', 'false', 'The schema rejects this value.');
    return checks;
  }
  if (rule.types.isNotEmpty) {
    add(
      'type',
      rule.types.map((type) => '(${_typeCheck(type)})').join(' || '),
      'Expected ${rule.types.join(' or ')}.',
    );
  }
  if (c.containsKey('const')) {
    add(
      'const',
      'value == ${_literal(c['const'])}',
      'Must equal the schema constant.',
    );
  }
  if (c['enum'] case final List<Object?> values) {
    add(
      'enum',
      'const <Object?>[${values.map(_literal).join(',')}].contains(value)',
      'Must match an enum value.',
    );
  }
  if (rule.multipleOf case final divisor?) {
    add(
      'multipleOf',
      '_isMultipleOf(value, $divisor)',
      'Must be a multiple of $divisor.',
      'number',
    );
  }
  for (final (key, inclusive, strict, text) in [
    ('minimum', '>=', '>', 'greater'),
    ('maximum', '<=', '<', 'less'),
  ]) {
    final exclusiveKey = key == 'minimum'
        ? 'exclusiveMinimum'
        : 'exclusiveMaximum';
    final Object? exclusive = c[exclusiveKey];
    if (c[key] case final num bound) {
      add(
        exclusive == true ? exclusiveKey : key,
        'value ${exclusive == true ? strict : inclusive} $bound',
        'Must be $text than${exclusive == true ? '' : ' or equal to'} $bound.',
        'number',
      );
    }
    if (exclusive is num) {
      add(
        exclusiveKey,
        'value $strict $exclusive',
        'Must be $text than $exclusive.',
        'number',
      );
    }
  }
  for (final (type, suffix, field, unit) in [
    ('string', 'Length', 'value.runes.length', 'characters'),
    ('array', 'Items', 'value.length', 'items'),
    ('object', 'Properties', 'value.length', 'properties'),
  ]) {
    if (c['min$suffix'] case final int bound) {
      add(
        'min$suffix',
        '$field >= $bound',
        'Must contain at least $bound $unit.',
        type,
      );
    }
    if (c['max$suffix'] case final int bound) {
      add(
        'max$suffix',
        '$field <= $bound',
        'Must contain at most $bound $unit.',
        type,
      );
    }
  }
  if (c['pattern'] case final String pattern) {
    add(
      'pattern',
      'RegExp(${_literal(pattern)}, unicode: true).hasMatch(value)',
      'Must match the schema pattern.',
      'string',
    );
  }
  if (rule.checksUniqueItems) {
    add(
      'uniqueItems',
      '_hasUniqueItems(value)',
      'Items must be unique.',
      'array',
    );
  }
  if (rule.contains case final predicate?) {
    final int minimum = c['minContains'] as int? ?? 1;
    add(
      c.containsKey('minContains') ? 'minContains' : 'contains',
      '_matchesContains(value, $predicate, $minimum, null)',
      'At least $minimum items must match contains.',
      'array',
    );
    if (c['maxContains'] case final int maximum) {
      add(
        'maxContains',
        '_matchesContains(value, $predicate, 0, $maximum)',
        'At most $maximum items must match contains.',
        'array',
      );
    }
  }
  return checks;
}

cb.Method _buildMatcher(DartSchemaMatcher rule) {
  final Map<String, Object?> constraints = rule.constraints;
  final List<String> checks = [
    for (final check in _localChecks(rule))
      if (check.keyword != 'type') check.test,
  ];
  if (rule.items case final item?) {
    checks.add(
      'value is! List<Object?> || value.skip(${rule.prefixItems.length}).every($item)',
    );
  }
  for (final (index, child) in rule.prefixItems.indexed) {
    checks.add(
      'value is! List<Object?> || value.length <= $index || $child(value[$index])',
    );
  }
  final List<Object?> required =
      constraints['required'] as List<Object?>? ?? const [];
  for (final key in required) {
    checks.add(
      'value is! Map<String, Object?> || value.containsKey(${_literal(key)})',
    );
  }
  for (final MapEntry<String, String> p in rule.properties.entries) {
    checks.add(
      'value is! Map<String, Object?> || !value.containsKey(${_literal(p.key)}) || ${p.value}(value[${_literal(p.key)}])',
    );
  }
  final keys =
      'const <String>{${rule.properties.keys.map(_literal).join(',')}}';
  if (constraints['additionalProperties'] == false) {
    checks.add(
      'value is! Map<String, Object?> || value.keys.every($keys.contains)',
    );
  }
  if (rule.additional case final additional?) {
    checks.add(
      'value is! Map<String, Object?> || value.entries.every((entry) => $keys.contains(entry.key) || $additional(entry.value))',
    );
  }
  checks.addAll(rule.allOf.map((name) => '$name(value)'));
  if (rule.oneOf.isNotEmpty) {
    checks.add(
      '[${rule.oneOf.map((name) => 'if ($name(value)) 1').join(',')}].length == 1',
    );
  }
  if (rule.anyOf.isNotEmpty) {
    checks.add('(${rule.anyOf.map((name) => '$name(value)').join(' || ')})');
  }
  checks.addAll(
    _localChecks(rule)
        .where((check) => check.keyword == 'type')
        .map((check) => check.test),
  );
  return cb.Method(
    (m) => m
      ..name = rule.name
      ..returns = cb.refer('bool')
      ..requiredParameters.add(_matcherParameter('value', 'Object?'))
      ..lambda = rule.ignoredWireKeys.isEmpty
      ..body = cb.Code(
        '${rule.ignoredWireKeys.isEmpty ? '' : "if (value is Map<String, Object?>) { value = {for (final entry in value.entries) if (!const <String>{${rule.ignoredWireKeys.map(_literal).join(',')}}.contains(entry.key)) entry.key: entry.value}; } return "}${rule.reject
            ? 'false'
            : checks.isEmpty
            ? 'true'
            : checks.map((check) => '($check)').join(' && ')}${rule.ignoredWireKeys.isEmpty ? '' : ';'}',
      ),
  );
}

cb.Method _buildProjection(DartSchemaMatcher rule) {
  final body = StringBuffer();
  for (final String child in rule.allOf) {
    body.writeln('value = _project$child(value);');
  }
  if (rule.properties.isNotEmpty ||
      rule.additional != null ||
      rule.ignoredWireKeys.isNotEmpty) {
    body.writeln(
      'if (value is Map<String, Object?>) { value = {for (final entry in value.entries)',
    );
    if (rule.ignoredWireKeys.isNotEmpty) {
      body.writeln(
        'if (!const <String>{${rule.ignoredWireKeys.map(_literal).join(',')}}.contains(entry.key))',
      );
    }
    body.writeln('entry.key: switch (entry.key) {');
    for (final MapEntry<String, String> entry in rule.properties.entries) {
      body.writeln(
        '${_literal(entry.key)} => _project${entry.value}(entry.value),',
      );
    }
    body.writeln(
      '_ => ${rule.additional == null ? 'entry.value' : '_project${rule.additional}(entry.value)'}, }}; }',
    );
  }
  if (rule.items != null || rule.prefixItems.isNotEmpty) {
    body.writeln(
      'if (value is List<Object?>) { value = [for (final (index, item) in value.indexed) switch (index) {',
    );
    for (final (index, child) in rule.prefixItems.indexed) {
      body.writeln('$index => _project$child(item),');
    }
    body.writeln(
      '_ => ${rule.items == null ? 'item' : '_project${rule.items}(item)'}, }]; }',
    );
  }
  for (final List<String> branches in [rule.oneOf, rule.anyOf]) {
    if (branches.isNotEmpty) {
      body.writeln(
        'value = _intersectProjection(value, <Object?>[${branches.map((child) => 'if ($child(value)) _project$child(value)').join(',')}]);',
      );
    }
  }
  body.writeln('return value;');
  return cb.Method(
    (m) => m
      ..name = '_project${rule.name}'
      ..returns = _jsonValue
      ..requiredParameters.add(_matcherParameter('value', 'Object?'))
      ..body = cb.Code(body.toString()),
  );
}

cb.Method _intersectProjection() => cb.Method(
  (m) => m
    ..name = '_intersectProjection'
    ..returns = _jsonValue
    ..requiredParameters.addAll([
      _matcherParameter('value', 'Object?'),
      _matcherParameter('views', 'List<Object?>'),
    ])
    ..body = const cb.Code('''
if (views.isEmpty) return value;
if (value is Map<String, Object?> && views.every((v) => v is Map<String, Object?>)) {
  final maps = views.cast<Map<String, Object?>>();
  return {for (final entry in value.entries)
    if (maps.every((m) => m.containsKey(entry.key)))
      entry.key: _intersectProjection(entry.value, [for (final m in maps) m[entry.key]])};
}
if (value is List<Object?> && views.every((v) => v is List<Object?> && v.length == value.length)) {
  final lists = views.cast<List<Object?>>();
  return [for (var i = 0; i < value.length; i++)
    _intersectProjection(value[i], [for (final list in lists) list[i]])];
}
return value;
'''),
);

String _typeCheck(String type) => switch (type) {
  'string' => 'value is String',
  'integer' => 'value is num && (value is int || (value.isFinite && value == value.truncateToDouble()))',
  'number' => '(value is num && value.isFinite)',
  'boolean' => 'value is bool',
  'null' => 'value == null',
  'array' => 'value is List<Object?>',
  'object' => 'value is Map<String, Object?>',
  _ => throw ArgumentError.value(type, 'type'),
};

const _jsonDartTypes = {
  'number': 'num',
  'string': 'String',
  'array': 'List<Object?>',
  'object': 'Map<String, Object?>',
};

cb.Parameter _matcherParameter(String name, String type) => cb.Parameter(
  (p) => p
    ..name = name
    ..type = cb.refer(type),
);

cb.Method _containsCountMethod() => cb.Method(
  (m) => m
    ..name = '_matchesContains'
    ..returns = cb.refer('bool')
    ..requiredParameters.addAll([
      _matcherParameter('items', 'List<Object?>'),
      _matcherParameter('matches', 'bool Function(Object?)'),
      _matcherParameter('minimum', 'int'),
      _matcherParameter('maximum', 'int?'),
    ])
    ..body = const cb.Code('''
final count = items.where(matches).length;
return count >= minimum && (maximum == null || count <= maximum);
'''),
);

cb.Method _decimalPartsMethod() => cb.Method(
  (m) => m
    ..name = '_decimalParts'
    ..returns = cb.refer('(_core.BigInt, int)')
    ..requiredParameters.add(_matcherParameter('value', 'num'))
    ..body = const cb.Code("""
final parts = value.toString().split('e');
final mantissa = parts.first;
final point = mantissa.indexOf('.');
var exponent = parts.length == 2 ? int.parse(parts.last) : 0;
if (point >= 0) exponent -= mantissa.length - point - 1;
var coefficient = _core.BigInt.parse(mantissa.replaceAll('.', ''));
if (coefficient == _core.BigInt.zero) return (_core.BigInt.zero, 0);
final ten = _core.BigInt.from(10);
while (coefficient.remainder(ten) == _core.BigInt.zero) {
  coefficient ~/= ten;
  exponent++;
}
return (coefficient, exponent);
"""),
);

cb.Method _multipleOfMethod() => cb.Method(
  (m) => m
    ..name = '_isMultipleOf'
    ..returns = cb.refer('bool')
    ..requiredParameters.addAll([
      _matcherParameter('value', 'num'),
      _matcherParameter('divisor', 'num'),
    ])
    ..body = const cb.Code('''
if (!value.isFinite) return false;
if (value == 0) return true;
final (coefficient, exponent) = _decimalParts(value);
final (step, stepExponent) = _decimalParts(divisor);
if (exponent < stepExponent) return false;
final scaled = coefficient * _core.BigInt.from(10).pow(exponent - stepExponent);
return scaled.remainder(step) == _core.BigInt.zero;
'''),
);

cb.Method _uniqueItemsMethod() => cb.Method(
  (m) => m
    ..name = '_hasUniqueItems'
    ..returns = cb.refer('bool')
    ..requiredParameters.add(_matcherParameter('items', 'List<Object?>'))
    ..body = cb.Code.scope((allocate) {
      final String encode = allocate(cb.refer('jsonEncode', 'dart:convert'));
      return """
Object? canonical(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: canonical(value[key])};
  }
  if (value is List<Object?>) return value.map(canonical).toList();
  if (value is num && value.isFinite) {
    final (coefficient, exponent) = _decimalParts(value);
    return 'n:\${coefficient}e\$exponent';
  }
  if (value is String) return 's:\$value';
  if (value == null || value is bool) return value;
  throw const FormatException('Expected a JSON value.');
}
final seen = <String>{};
return items.every((item) => seen.add($encode(canonical(item))));
""";
    }),
);
