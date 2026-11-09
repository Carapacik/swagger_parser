part of 'dart_code_builder.dart';

extension on _JsonBuilder {
  cb.Class buildTuple(DartTupleModel tuple) => cb.Class((c) {
    c.name = tuple.name;
    final cb.Reference list = cb.refer('List<Object?>');
    final field = tuple.arrayOnly ? '_items' : '_json';
    final cb.Reference output = tuple.arrayOnly ? list : _jsonValue;
    c.fields.add(_field(field, output));
    c.constructors.add(
      cb.Constructor(
        (ctor) => ctor
          ..name = '_'
          ..requiredParameters.add(
            cb.Parameter(
              (p) => p
                ..name = field
                ..toThis = true,
            ),
          ),
      ),
    );
    final guard = tuple.arrayOnly ? 'json is! List<Object?> || ' : '';
    final copy = tuple.arrayOnly
        ? 'json.map(_copyJson).toList()'
        : '_copyJson(json)';
    c.constructors.add(
      _fromJson(_jsonValue, '''
${tuple.project ? 'json = _project${tuple.matcher}(json);' : ''}
if ($guard!${tuple.matcher}(json)) { throw const FormatException(${_literal('Invalid ${tuple.name} value.')}); }
return ${tuple.name}._($copy);
'''),
    );
    if (!tuple.arrayOnly) {
      c.methods.add(
        _tupleGetter(
          '_items',
          list,
          'switch (_json) { List<Object?> items => items, _ => const <Object?>[] }',
        ),
      );
    }
    for (final (index, type) in tuple.positions.indexed) {
      final int number = index + 1;
      final bool optional = index >= tuple.requiredCount;
      if (optional) {
        c.methods.add(
          _tupleGetter(
            'hasItem$number',
            cb.refer('bool'),
            '_items.length >= $number',
          ),
        );
      }
      final cb.TypeReference result = _buildType(type).rebuild((t) {
        if (optional && type.symbol == 'Never') {
          t.symbol = 'Null';
        }
        t.isNullable = t.symbol != 'Null' && (optional || type.isNullable);
      });
      final String read = _readTupleItem(type, '_items[$index]');
      final getter = 'item$number';
      if (!optional || type.symbol == 'Never') {
        c.methods.add(_tupleGetter(getter, result, optional ? 'null' : read));
      } else {
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = getter
              ..type = cb.MethodType.getter
              ..returns = result
              ..body = cb.Code(
                'if (!hasItem$number) return null; return $read;',
              ),
          ),
        );
      }
    }
    if (tuple.restType case final type?) {
      final result = DartTypeReference(symbol: 'List', typeArguments: [type]);
      final convert = type.symbol == 'Object' && type.isNullable
          ? '_copyJson'
          : "(item) => ${_readTupleItem(type, 'item')}";
      c.methods.add(
        _tupleGetter(
          'rest',
          _buildType(result),
          '_items.skip(${tuple.positions.length}).map($convert).toList()',
        ),
      );
    }
    c.methods.add(
      _toJson(
        output,
        tuple.arrayOnly ? '_items.map(_copyJson).toList()' : '_copyJson(_json)',
      ),
    );
  });

  String _readTupleItem(DartTypeReference type, String value) {
    if (const {
      'bool',
      'String',
      'int',
      'num',
      'Never',
      'Null',
    }.contains(type.symbol)) {
      return _decode(type, value);
    }
    final copy = '_copyJson($value)';
    if (type.symbol == 'Object' && type.isNullable) {
      return copy;
    }
    final String read = _decode(type, copy, nullable: false);
    return type.isNullable ? '$value == null ? null : $read' : read;
  }
}

cb.Method _tupleGetter(String name, cb.Reference type, String expression) =>
    cb.Method(
      (m) => m
        ..name = name
        ..type = cb.MethodType.getter
        ..returns = type
        ..lambda = true
        ..body = cb.Code(expression),
    );
