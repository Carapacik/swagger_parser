part of 'dart_code_builder.dart';

extension on _JsonBuilder {
  Iterable<cb.Class> buildStructuralUnion(
    DartStructuralUnion union, {
    bool freezed = false,
  }) sync* {
    final body = StringBuffer();
    final snapshot = union.projectionMatcher == null
        ? 'json'
        : '_project${union.projectionMatcher}(json)';
    if (union.projectionMatcher case final projection?
        when union.unknownType == null) {
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
      body.write('final matches = <String>[${alternatives.join(',')}];');
      if (union.unknownType case final unknown?) {
        body.write('if (matches.isEmpty) { return $unknown($snapshot); }');
      }
      body.write(
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
      if (union.unknownType != null) {
        yield _unknownStructuralUnion(union, freezed: freezed);
      }
      return;
    }

    final List<String> flags = [
      for (final branch in union.branches) 'has${branch.label}',
    ];
    for (final DartMatchBranch branch in union.branches) {
      body.write('final has${branch.label} = ${branch.matcher}(json);');
    }
    final unmatched = union.unknownType == null
        ? 'throw const FormatException(${_literal('No matching ${union.name} variant.')});'
        : 'return ${union.unknownType}($snapshot);';
    body
      ..write('if (!(${flags.join(' || ')})) { $unmatched }')
      ..write(
        'return ${union.name}._(_copyJson($snapshot), ${flags.join(',')});',
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
    if (union.unknownType != null) {
      yield _unknownStructuralUnion(union, freezed: freezed);
    }
  }

  cb.Class _unknownStructuralUnion(
    DartStructuralUnion union, {
    bool freezed = false,
  }) => cb.Class((c) {
    c
      ..name = union.unknownType
      ..modifier = cb.ClassModifier.final$;
    if (union.exclusive) {
      c.implements.add(cb.refer(union.name));
      c.fields.add(_field('rawJson', _jsonValue));
    } else {
      c.extend = cb.refer(union.name);
      if (freezed) {
        c.fields.add(_field('rawJson', _jsonValue));
      } else {
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = 'rawJson'
              ..type = cb.MethodType.getter
              ..returns = _jsonValue
              ..lambda = true
              ..body = const cb.Code('_json'),
          ),
        );
      }
    }
    if (freezed && !union.exclusive) {
      // Freezed compares declared fields. Share the frozen snapshot with the base.
      c.constructors.addAll([
        cb.Constructor(
          (ctor) => ctor
            ..factory = true
            ..requiredParameters.add(
              cb.Parameter(
                (p) => p
                  ..name = 'json'
                  ..type = _jsonValue,
              ),
            )
            ..lambda = true
            ..body = cb.Code(
              '${union.unknownType}._(_freezeUnknownJson(json))',
            ),
        ),
        cb.Constructor(
          (ctor) => ctor
            ..name = '_'
            ..requiredParameters.add(
              cb.Parameter(
                (p) => p
                  ..name = 'rawJson'
                  ..toThis = true,
              ),
            )
            ..initializers.add(
              cb.Code(
                'super._(rawJson, ${union.branches.map((_) => 'false').join(', ')})',
              ),
            ),
        ),
      ]);
      return;
    }
    c.constructors.add(
      cb.Constructor(
        (ctor) => ctor
          ..requiredParameters.add(
            cb.Parameter(
              (p) => p
                ..name = 'json'
                ..type = _jsonValue,
            ),
          )
          ..initializers.add(
            cb.Code(
              union.exclusive
                  ? 'rawJson = _freezeUnknownJson(json)'
                  : 'super._(_freezeUnknownJson(json), ${union.branches.map((_) => 'false').join(', ')})',
            ),
          ),
      ),
    );
    if (union.exclusive) {
      c.methods.add(_toJson(_jsonValue, '_copyJson(rawJson)'));
    }
  });
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
  null || bool() || String() => value,
  num() when value.isFinite => value,
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
