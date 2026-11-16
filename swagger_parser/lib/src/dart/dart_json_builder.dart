part of 'dart_code_builder.dart';

String _literal(Object? value) => jsonEncode(value).replaceAll(r'$', r'\$');

final cb.Reference _jsonMap = cb.refer('Map<String, Object?>');
final cb.Reference _jsonValue = cb.refer('Object?');

final class _JsonBuilder(
  final Set<String> objectTypes,
  final Set<String> wrappedTypes, {
  required final bool matchIntegers,
  final Set<String> qualified = const {},
  final Set<String> metadataEnums = const {},
}) {
  bool usesIntegerReader = false;
  void addParameters(DartDtoModel dto, cb.ConstructorBuilder constructor) {
    if (dto.extraValueType != null) {
      constructor.optionalParameters.add(
        _defaultField('additionalProperties', 'const {}'),
      );
    }
  }

  cb.Parameter _defaultField(String name, String value) => cb.Parameter(
    (p) => p
      ..name = name
      ..named = true
      ..toThis = true
      ..defaultTo = cb.Code(value),
  );

  cb.Field _field(String name, cb.Reference type) => cb.Field(
    (f) => f
      ..name = name
      ..type = type
      ..modifier = cb.FieldModifier.final$,
  );

  cb.Constructor _fromJson(
    cb.Reference input,
    String body, {
    bool lambda = false,
  }) => cb.Constructor(
    (c) => c
      ..name = 'fromJson'
      ..factory = true
      ..lambda = lambda
      ..requiredParameters.add(
        cb.Parameter(
          (p) => p
            ..name = 'json'
            ..type = input,
        ),
      )
      ..body = cb.Code(body),
  );

  cb.Method _toJson(cb.Reference output, String expression) => cb.Method(
    (m) => m
      ..name = 'toJson'
      ..returns = output
      ..lambda = true
      ..body = cb.Code(expression),
  );

  void addSerialization(DartDtoModel dto, cb.ClassBuilder type) {
    final List<String> keys = [
      for (final f in dto.fields) _literal(f.wireName ?? f.name),
      ...dto.ignoredWireKeys.map(_literal),
    ];
    const known = '_knownKeys';
    if (keys.isNotEmpty) {
      type.fields.add(
        cb.Field(
          (f) => f
            ..name = known
            ..static = true
            ..modifier = cb.FieldModifier.constant
            ..assignment = cb.Code('<String>{${keys.join(',')}}'),
        ),
      );
    }
    final body = StringBuffer(_fixedChecks(dto));
    final args = <String>[];
    String? extraArgument;
    final entries = <String>[];
    if (dto.extraValueType case final extra?) {
      final map = DartTypeReference(
        symbol: 'Map',
        typeArguments: [_stringType, extra],
      );
      type.fields.add(_field('additionalProperties', _buildType(map)));
      final guard = keys.isEmpty ? '' : 'if (!$known.contains(entry.key))';
      extraArgument =
          'additionalProperties: {for (final entry in json.entries) $guard entry.key: ${_decode(extra, 'entry.value')}}';
      entries.add(
        'for (final entry in additionalProperties.entries) $guard entry.key: ${_encode(extra, 'entry.value')}',
      );
    } else {
      body.writeln(
        "if (${keys.isEmpty ? 'json.isNotEmpty' : 'json.keys.any((key) => !$known.contains(key))'}) { throw ArgumentError('Unexpected JSON property.'); }",
      );
    }
    for (final DartFieldModel field in dto.fields) {
      final String key = _literal(field.wireName ?? field.name);
      if (field.fixedValue case final fixed?) {
        entries.add('$key: ${_literal(fixed.value)}');
        continue;
      }
      final present = 'json.containsKey($key)';
      if (field.isRequired &&
          (field.acceptsNull || wrappedTypes.contains(field.type.symbol))) {
        body.writeln(
          "if (!$present) { throw ArgumentError(${_literal('Missing required property: ${field.wireName ?? field.name}')}); }",
        );
      }
      final value = 'json[$key]';
      final String read = _decode(
        field.type,
        value,
        nullable: field.acceptsNull,
      );
      final access = 'this.${field.name}';
      if (field.tracksPresence) {
        args.add('${field.name}: $present ? (value: $read) : null');
        entries.add(
          'if ($access case final record?) $key: ${_encode(field.type, 'record.value')}',
        );
      } else {
        args.add(
          '${field.name}: ${field.isRequired ? read : '$present ? $read : ${field.defaultExpression ?? 'null'}'}',
        );
        if (field.isRequired ||
            field.defaultValue != null ||
            field.type.symbol != 'Null') {
          entries.add(
            "${field.isRequired || field.defaultValue != null ? '' : 'if ($access != null)'} $key: ${_encode(field.type, access)}",
          );
        }
      }
    }
    if (extraArgument != null) {
      args.add(extraArgument);
    }
    final constructor = '${dto.name}(${args.join(',')})';
    type.constructors.add(
      body.isEmpty
          ? _fromJson(_jsonMap, constructor, lambda: true)
          : _fromJson(_jsonMap, '${body}return $constructor;'),
    );
    type.methods.add(
      _checkedToJson(dto, _toJson(_jsonMap, '{${entries.join(',')}}')),
    );
  }

  cb.Constructor get _valueConstructor => cb.Constructor(
    (c) => c
      ..constant = true
      ..requiredParameters.add(
        cb.Parameter(
          (p) => p
            ..name = 'value'
            ..toThis = true,
        ),
      ),
  );

  cb.Class buildValue(
    DartValueModel model, [
    List<String> interfaces = const [],
  ]) => cb.Class(
    (c) => c
      ..name = model.name
      ..implements.addAll(interfaces.map(cb.refer))
      ..fields.add(_field('value', _buildType(model.type)))
      ..constructors.addAll([
        _valueConstructor,
        _fromJson(
          _jsonValue,
          'return ${model.name}(${_decode(model.type, 'json')});',
        ),
      ])
      ..methods.add(
        _toJson(
          model.type.scalarCodec?.wireType == 'Map<String, Object?>' &&
                  !model.type.isNullable
              ? _jsonMap
              : _jsonValue,
          _encode(model.type, 'value'),
        ),
      ),
  );

  cb.Class buildUnion(DartUnionModel union) {
    final body = StringBuffer(
      'switch (json[${_literal(union.propertyName)}]) {',
    );
    for (final MapEntry<String, String> entry in union.mapping.entries) {
      body.write(
        'case ${_literal(entry.key)}: return ${entry.value}.fromJson(json);',
      );
    }
    if (union.defaultType case final fallback?) {
      body.write('default: return $fallback.fromJson(json);');
    } else if (union.unknownType case final unknown?) {
      body.write(
        'default: if (json[${_literal(union.propertyName)}] is! String) { throw ArgumentError(${_literal('Expected a string discriminator: ${union.propertyName}')}); } return $unknown(json);',
      );
    } else {
      final String error = _literal(
        'Missing or unknown discriminator: ${union.propertyName}',
      );
      body.write(
        'default: throw FormatException($error, json[${_literal(union.propertyName)}]);',
      );
    }
    body.write('}');
    return cb.Class(
      (type) => type
        ..name = union.name
        ..sealed = true
        ..constructors.add(_fromJson(_jsonMap, body.toString()))
        ..methods.add(
          cb.Method(
            (method) => method
              ..name = 'toJson'
              ..returns = _jsonMap,
          ),
        ),
    );
  }

  cb.Enum buildEnum(DartEnumModel model) => model.hasMetadata
      ? _buildEnhancedEnum(model)
      : cb.Enum(
          (e) => e
            ..name = model.name
            ..values.addAll(
              model.values.entries.map(
                (entry) => cb.EnumValue(
                  (v) => v
                    ..name = entry.key
                    ..arguments.add(
                      cb.CodeExpression(cb.Code(_literal(entry.value))),
                    ),
                ),
              ),
            )
            ..fields.add(_field('value', cb.refer('Object')))
            ..constructors.addAll([
              _valueConstructor,
              _fromJson(
                _jsonValue,
                "return values.firstWhere((item) => item.value == json, orElse: () => throw FormatException(${_literal('Unknown ${model.name} value.')}, json));",
              ),
            ])
            ..methods.add(_toJson(cb.refer('Object'), 'value')),
        );

  cb.Enum _buildEnhancedEnum(DartEnumModel model) {
    final String scalarType = switch (model.values.values.first) {
      final bool _ => 'bool',
      final int _ => 'int',
      _ => 'String',
    };
    final cb.Reference wireType = cb.refer(scalarType);
    return cb.Enum((e) {
      e
        ..name = model.name
        ..values.addAll(
          model.values.entries.map((entry) {
            final String wire = _literal(entry.value);
            final Map<String, Object> metadata =
                model.metadataValues[entry.value.toString()]!;
            final String arguments = [
              wire,
              for (final String field in model.metadataFields.keys)
                '$field: ${_literal(metadata[field])}',
            ].join(', ');
            return cb.EnumValue(
              (v) => v
                ..name = entry.key
                ..arguments.add(cb.CodeExpression(cb.Code(arguments))),
            );
          }),
        )
        ..fields.add(_field('wireValue', wireType))
        ..fields.addAll(
          model.metadataFields.entries.map(
            (entry) => _field(
              entry.key,
              cb.refer(switch (entry.value) {
                'integer' => 'int',
                'number' => 'double',
                'boolean' => 'bool',
                _ => 'String',
              }),
            ),
          ),
        )
        ..constructors.add(
          cb.Constructor((c) {
            c
              ..constant = true
              ..requiredParameters.add(
                cb.Parameter(
                  (p) => p
                    ..name = 'wireValue'
                    ..toThis = true
                    ..type = wireType,
                ),
              )
              ..optionalParameters.addAll(
                model.metadataFields.entries.map(
                  (entry) => cb.Parameter(
                    (p) => p
                      ..name = entry.key
                      ..named = true
                      ..required = true
                      ..toThis = true
                      ..type = cb.refer(switch (entry.value) {
                        'integer' => 'int',
                        'number' => 'double',
                        'boolean' => 'bool',
                        _ => 'String',
                      }),
                  ),
                ),
              );
          }),
        )
        ..constructors.add(
          _fromJson(
            _jsonValue,
            'if (json is! $scalarType) { throw ArgumentError.value(json, ${_literal(model.name)}); } '
            'return values.firstWhere((item) => item.wireValue == json, orElse: () => throw ArgumentError.value(json, ${_literal(model.name)}));',
          ),
        )
        ..methods.add(_toJson(wireType, 'wireValue'))
        ..methods.add(
          cb.Method(
            (m) => m
              ..name = 'tryFromJson'
              ..static = true
              ..returns = cb.refer('${model.name}?')
              ..requiredParameters.add(
                cb.Parameter(
                  (p) => p
                    ..name = 'json'
                    ..type = _jsonValue,
                ),
              )
              ..body = cb.Code(
                'if (json is! $scalarType) return null; '
                'for (final value in values) { '
                'if (value.wireValue == json) return value; } '
                'return null;',
              ),
          ),
        );
    });
  }

  String _decode(DartTypeReference type, String value, {bool? nullable}) {
    final bool permitsNull = nullable ?? type.isNullable;
    if (type.scalarCodec case final codec?) {
      final read = '${codec.adapter}.read($value)';
      return permitsNull
          ? 'switch ($value) { null => null, final item => ${codec.adapter}.read(item) }'
          : read;
    }
    if (matchIntegers && type.symbol == 'int') {
      usesIntegerReader = true;
      final read = '_readJsonInteger($value)';
      return permitsNull ? '$value == null ? null : $read' : read;
    }
    if (const {
      'Object',
      'int',
      'bool',
      'String',
      'num',
      'Null',
      'Never',
    }.contains(type.symbol)) {
      if (type.symbol == 'Object' && permitsNull) {
        return value;
      }
      final suffix = permitsNull && type.symbol != 'Null' ? '?' : '';
      return '$value as ${type.symbol}$suffix';
    }
    final String name = qualified.contains(type.symbol)
        ? 'models.${type.symbol}'
        : type.symbol;
    final enumDecoder =
        type.isMetadataEnum || metadataEnums.contains(type.symbol)
        ? (permitsNull ? 'tryFromJson' : 'fromJson')
        : 'fromJson';
    final String read = switch (type.symbol) {
      'DateTime' => 'DateTime.parse($value as String).toUtc()',
      'List' =>
        "($value as List<Object?>).map((item) => ${_decode(type.typeArguments.single, 'item')}).toList()",
      'Map' =>
        "($value as Map<String, Object?>).map((key, item) => MapEntry(key, ${_decode(type.typeArguments.last, 'item')}))",
      _ when objectTypes.contains(type.symbol) =>
        '$name.fromJson($value as Map<String, Object?>)',
      _ => '$name.$enumDecoder($value)',
    };
    return permitsNull && type.symbol != 'Null'
        ? '$value == null ? null : $read'
        : read;
  }
}

String _encode(DartTypeReference type, String value) {
  if (type.scalarCodec case final codec?) {
    final write = '${codec.adapter}.write($value)';
    return type.isNullable
        ? 'switch ($value) { null => null, final item => ${codec.adapter}.write(item) }'
        : write;
  }
  final access = type.isNullable ? '?.' : '.';
  return switch (type.symbol) {
    'DateTime' => '$value${access}toUtc().toIso8601String()',
    'List' =>
      "$value${access}map((item) => ${_encode(type.typeArguments.single, 'item')}).toList()",
    'Map' =>
      "$value${access}map((key, item) => MapEntry(key, ${_encode(type.typeArguments.last, 'item')}))",
    'Object' ||
    'int' ||
    'num' ||
    'bool' ||
    'String' ||
    'Null' ||
    'Never' => value,
    _ => '$value${access}toJson()',
  };
}

final _stringType = DartTypeReference(symbol: 'String');
