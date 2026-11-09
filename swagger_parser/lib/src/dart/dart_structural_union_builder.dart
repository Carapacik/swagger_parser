part of 'dart_code_builder.dart';

extension on _JsonBuilder {
  Iterable<cb.Class> buildStructuralUnion(DartStructuralUnion union) sync* {
    final body = StringBuffer();
    if (union.projectionMatcher case final projection?) {
      body.write(
        'if (!$projection(json)) { throw FormatException(${_literal('Invalid ${union.name} value.')}); }',
      );
    }
    if (union.commonMatcher case final common?) {
      body.write(
        "if (!$common(json)) { throw const FormatException(${_literal('Invalid ${union.name} value.')}); }",
      );
    }
    if (union.exclusive) {
      final List<String> alternatives = [
        for (final branch in union.branches)
          'if (${branch.matcher}(json)) ${_literal(branch.label)}',
      ];
      body
        ..write('final matches = <String>[${alternatives.join(',')}];')
        ..write(
          "if (matches.length != 1) { throw FormatException(${_literal('Expected exactly one ${union.name} variant. Matches: ')} + matches.toString()); }",
        );
      for (final DartMatchBranch branch in union.branches) {
        final String value = _decode(branch.type, 'json');
        final String variant = branch.implementation!;
        final expression = variant == branch.type.symbol
            ? value
            : '$variant($value)';
        if (branch == union.branches.last) {
          body.write('return $expression;');
        } else {
          body.write(
            'if (matches.single == ${_literal(branch.label)}) { return $expression; }',
          );
        }
      }
      yield cb.Class(
        (c) => c
          ..name = union.name
          ..sealed = true
          ..constructors.add(_fromJson(_jsonValue, body.toString()))
          ..methods.add(
            cb.Method(
              (m) => m
                ..name = 'toJson'
                ..returns = _jsonValue,
            ),
          ),
      );
      for (final DartMatchBranch branch in union.branches) {
        if (branch.implementation != branch.type.symbol) {
          yield cb.Class(
            (c) => c
              ..name = branch.implementation
              ..implements.add(cb.refer(union.name))
              ..fields.add(_field('value', _buildType(branch.type)))
              ..constructors.add(_valueConstructor)
              ..methods.add(_toJson(_jsonValue, _encode(branch.type, 'value'))),
          );
        }
      }
      return;
    }

    final List<String> flags = [
      for (final branch in union.branches) 'has${branch.label}',
    ];
    for (final DartMatchBranch branch in union.branches) {
      body.write('final has${branch.label} = ${branch.matcher}(json);');
    }
    body
      ..write(
        "if (!(${flags.join(' || ')})) { throw const FormatException(${_literal('No matching ${union.name} variant.')}); }",
      )
      ..write(
        'return ${union.name}._(_copyJson(${union.projectionMatcher == null ? 'json' : '_project${union.projectionMatcher}(json)'}), ${flags.join(',')});',
      );
    yield cb.Class((c) {
      c.name = union.name;
      c.fields.add(_field('_json', _jsonValue));
      for (final flag in flags) {
        c.fields.add(_field(flag, cb.refer('bool')));
      }
      c.constructors.add(
        cb.Constructor(
          (ctor) => ctor
            ..name = '_'
            ..requiredParameters.addAll([
              for (final field in ['_json', ...flags])
                cb.Parameter(
                  (p) => p
                    ..name = field
                    ..toThis = true,
                ),
            ]),
        ),
      );
      c.constructors.add(_fromJson(_jsonValue, body.toString()));
      for (final DartMatchBranch branch in union.branches) {
        final cb.TypeReference type = _buildType(branch.type)
            .rebuild((t) => t.isNullable = branch.type.symbol != 'Null');
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = 'as${branch.label}'
              ..type = cb.MethodType.getter
              ..returns = type
              ..body = cb.Code(
                'if (!has${branch.label}) { return null; } '
                'final json = _copyJson(_json); return ${_decode(branch.type, 'json')};',
              ),
          ),
        );
      }
      c.methods.add(_toJson(_jsonValue, '_copyJson(_json)'));
    });
  }
}

cb.Method _copyJsonMethod() => cb.Method(
  (m) => m
    ..name = '_copyJson'
    ..returns = _jsonValue
    ..requiredParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'value'
          ..type = _jsonValue,
      ),
    )
    ..body = const cb.Code("""
return switch (value) {
  Map<String, Object?> map => map.map((key, item) => MapEntry(key, _copyJson(item))),
  List<Object?> list => list.map(_copyJson).toList(),
  null || bool() || String() || int() => value,
  double() when value.isFinite => value,
  _ => throw const FormatException('Expected a JSON value.'),
};
"""),
);

cb.Method _integerReader() => cb.Method(
  (m) => m
    ..name = '_readJsonInteger'
    ..returns = cb.refer('int')
    ..requiredParameters.add(
      cb.Parameter(
        (p) => p
          ..name = 'value'
          ..type = _jsonValue,
      ),
    )
    ..body = const cb.Code("""
if (value is int) { return value; }
if (value is double && value.isFinite && value == value.toInt()) { return value.toInt(); }
throw FormatException('Expected a JSON integer.', value);
"""),
);
