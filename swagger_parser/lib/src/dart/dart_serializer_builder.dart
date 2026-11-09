part of 'dart_code_builder.dart';

final class _SerializerBuilder(
  final DtoSerializer serializer,
  final _JsonBuilder json,
  final DartLibraryModel model,
) {
  this {
    if (serializer != DtoSerializer.freezed &&
        serializer != DtoSerializer.dartMappable) {
      return;
    }
    final owners = <String, int>{};
    for (final DartUnionModel union in model.unions) {
      for (final String name in union.mapping.values.toSet()) {
        owners[name] = (owners[name] ?? 0) + 1;
      }
    }
    for (final DartUnionModel union in model.unions) {
      final Map<String, String> variants = {
        for (final entry in union.mapping.entries) entry.value: entry.key,
      };
      // Package union builders do not escape dollars in diagnostic strings.
      if (union.unknownType != null ||
          union.name.contains(r'$') ||
          variants.length < 2 ||
          variants.keys.any((n) => !dtos.containsKey(n) || owners[n] != 1) ||
          !RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(union.propertyName) ||
          variants.values.any(
            (tag) => !RegExp(r'^[a-zA-Z0-9_./-]+$').hasMatch(tag),
          )) {
        continue;
      }
      tags[union.name] = variants;
      variantTags.addAll(variants);
    }
  }

  final bool hasMappableEnums = model.enums.any((e) => e.openNames == null);
  final Set<String> nativeEnums = {
    for (final e in model.enums)
      if (e.openNames == null &&
          e.values.values.every((v) => v is String || v is int))
        e.name,
  };
  final Map<String, DartDtoModel> dtos = {
    for (final dto in model.dtos) dto.name: dto,
  };
  final tags = <String, Map<String, String>>{};
  final variantTags = <String, String>{};

  void addDirectives(cb.LibraryBuilder library, String path) {
    final bool hasObjects = dtos.values.any((dto) => dto.json);
    if (serializer == DtoSerializer.plain ||
        (!hasObjects &&
            nativeEnums.isEmpty &&
            (serializer != DtoSerializer.dartMappable || !hasMappableEnums))) {
      return;
    }
    final String stem = path
        .split('/')
        .last
        .replaceFirst(RegExp(r'\.dart$'), '');
    final String package = switch (serializer) {
      DtoSerializer.freezed => 'freezed_annotation',
      DtoSerializer.dartMappable => 'dart_mappable',
      _ => 'json_annotation',
    };
    library.directives.addAll([
      cb.Directive.import('package:$package/$package.dart'),
      if (serializer == DtoSerializer.freezed && hasObjects)
        cb.Directive.part('$stem.freezed.dart'),
      cb.Directive.part(
        serializer == DtoSerializer.dartMappable
            ? '$stem.mapper.dart'
            : '$stem.g.dart',
      ),
    ]);
  }

  cb.Class buildUnion(DartUnionModel union) {
    final Map<String, String>? variants = tags[union.name];
    if (variants == null) {
      final cb.Class base = json.buildUnion(union);
      if (serializer != DtoSerializer.freezed || union.unknownType == null) {
        return base;
      }
      return base.rebuild((c) {
        for (final String name in union.mapping.values.toSet()) {
          final DartDtoModel? dto = dtos[name];
          if (dto == null) {
            continue;
          }
          c.constructors.add(
            cb.Constructor((b) {
              b
                ..name = 'as$name'
                ..factory = true
                ..constant = true
                ..redirect = cb.refer(name);
              for (final DartFieldModel f in dto.fields.where(
                (f) => f.fixedValue == null,
              )) {
                b.optionalParameters.add(
                  cb.Parameter(
                    (p) => p
                      ..name = f.name
                      ..named = true
                      ..required = f.isRequired
                      ..type = _fieldType(f),
                  ),
                );
              }
            }),
          );
        }
      });
    }
    final String name = union.name;
    final String key = _literal(union.propertyName);
    final frozen = serializer == DtoSerializer.freezed;
    return cb.Class((c) {
      c
        ..name = name
        ..sealed = true;
      if (frozen) {
        c.annotations.add(
          cb.refer('Freezed(unionKey: $key, fromJson: true, toJson: false)'),
        );
        c.mixins.add(cb.refer('_\$$name'));
        for (final MapEntry<String, String> variant in variants.entries) {
          final DartDtoModel dto = dtos[variant.key]!;
          c.constructors.add(
            cb.Constructor((b) {
              b
                ..name = 'as${dto.name}'
                ..constant = true
                ..factory = true
                ..annotations.add(
                  cb.refer('FreezedUnionValue(${_literal(variant.value)})'),
                )
                ..redirect = cb.refer(dto.name);
              for (final DartFieldModel f in dto.fields.where(
                (f) => f.fixedValue == null,
              )) {
                b.optionalParameters.add(
                  cb.Parameter((p) {
                    p
                      ..name = f.name
                      ..type = _fieldType(f)
                      ..named = true
                      ..required = f.isRequired;
                    if (f.defaultExpression case final value?) {
                      p.annotations.add(cb.refer('Default($value)'));
                    }
                  }),
                );
              }
            }),
          );
        }
        final decode = '_\$${name}FromJson(json)';
        final body = StringBuffer('switch (json[$key]) {');
        for (final MapEntry<String, String> entry in union.mapping.entries) {
          if (variants[entry.value] != entry.key) {
            body.write(
              'case ${_literal(entry.key)}: return ${entry.value}.fromJson(json);',
            );
          }
        }
        if (union.defaultType case final fallback?) {
          for (final String tag in variants.values) {
            body.write('case ${_literal(tag)}:');
          }
          body.write(
            'return $decode; default: return $fallback.fromJson(json);',
          );
        } else {
          body.write('default: return $decode;');
        }
        c.constructors.add(json._fromJson(_jsonMap, '$body}'));
      } else {
        final List<String> aliases = [
          for (final entry in union.mapping.entries)
            if (variants[entry.value] != entry.key)
              '${_literal(entry.key)}: ${entry.value}._fromWire',
        ];
        final String canonical = variants.values.map(_literal).join(',');
        final fallback = union.defaultType == null
            ? 'null'
            : '${union.defaultType}._fromWire';
        c.annotations.add(
          cb.refer(
            "MappableClass(discriminatorKey: $key, generateMethods: GenerateMethods.decode, hook: _TagAliases($key, {${aliases.join(',')}}, {$canonical}, $fallback))",
          ),
        );
        c.mixins.add(cb.refer('${name}Mappable'));
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = 'toMap'
              ..returns = _jsonMap
              ..lambda = true
              ..body = const cb.Code('toJson()'),
          ),
        );
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = 'fromJson'
              ..static = true
              ..returns = cb.refer(name)
              ..requiredParameters.add(_arg('json', _jsonMap))
              ..lambda = true
              ..body = cb.Code('${name}Mapper.fromMap(json)'),
          ),
        );
      }
      c.methods.add(
        cb.Method(
          (m) => m
            ..name = 'toJson'
            ..returns = _jsonMap,
        ),
      );
    });
  }

  cb.Spec annotatedDto(DartDtoModel dto, List<String> interfaces) {
    final declaration = cb.Class((c) {
      final String name = dto.name;
      final frozen = serializer == DtoSerializer.freezed;
      c.name = name;
      c.implements.addAll(interfaces.map(cb.refer));
      if (frozen) {
        c.annotations.add(cb.refer('Freezed(fromJson: false, toJson: false)'));
        c.mixins.add(cb.refer('_\$$name'));
      }
      c.annotations.add(
        cb.refer(
          'JsonSerializable(explicitToJson: true, includeIfNull: true, disallowUnrecognizedKeys: ${dto.extraValueType == null})',
        ),
      );
      final constructor = cb.ConstructorBuilder()..constant = true;
      void property(
        String field,
        cb.Reference type,
        List<String> options, {
        bool required = false,
        String? fallback,
      }) {
        final cb.Reference? annotation = options.isEmpty
            ? null
            : cb.refer("JsonKey(${options.join(', ')})");
        constructor.optionalParameters.add(
          cb.Parameter((p) {
            p
              ..name = field
              ..named = true
              ..required = required
              ..toThis = true;
            if (fallback != null) {
              p.defaultTo = cb.Code(fallback);
            }
          }),
        );
        c.fields.add(
          cb.Field((f) {
            f
              ..name = field
              ..type = type
              ..modifier = cb.FieldModifier.final$;
            if (annotation != null) {
              f.annotations.add(annotation);
            }
          }),
        );
      }

      for (final DartFieldModel field in dto.fields) {
        if (field.fixedValue != null) {
          c.methods.add(
            _fixedGetter(field).rebuild(
              (m) => m.annotations.add(
                cb.refer(
                  'JsonKey(includeFromJson: false, includeToJson: false)',
                ),
              ),
            ),
          );
          continue;
        }
        final String key = field.wireName ?? field.name;
        final bool wrapped = json.wrappedTypes.contains(field.type.symbol);
        final bool distinguishNull =
            field.tracksPresence || (!field.isRequired && wrapped);
        final options = [
          if (key != field.name) 'name: ${_literal(key)}',
          if (field.isRequired) 'required: true',
          if (!field.acceptsNull && !wrapped) 'disallowNullValue: true',
          if (!field.isRequired &&
              field.defaultValue == null &&
              !distinguishNull)
            'includeIfNull: false',
        ];
        if (field.defaultValue != null ||
            field.tracksPresence ||
            !_nativeJson(field.type)) {
          final read = '_read_${field.name}';
          final write = '_write_${field.name}';
          final String decoded = json._decode(
            field.type,
            field.defaultValue == null ? 'value' : 'data',
            nullable: field.acceptsNull,
          );
          final cb.Reference inner = field.tracksPresence
              ? cb.RecordType(
                  (r) => r.namedFieldTypes['value'] = _buildType(field.type),
                )
              : _buildType(field.type);
          options.addAll([
            if (field.defaultValue != null) 'readValue: $name._presentValue',
            if (distinguishNull && field.defaultValue == null)
              'explicitJsonNullWhenNonNullField: true',
            'fromJson: $name.$read',
            'toJson: $name.$write',
          ]);
          c.methods.addAll([
            _converter(
              read,
              field.defaultValue == null ? _jsonValue : cb.refer('Object'),
              inner,
              field.tracksPresence
                  ? '(value: $decoded)'
                  : field.defaultValue == null &&
                        !field.isRequired &&
                        !field.acceptsNull &&
                        !wrapped
                  ? 'value == null ? null : $decoded'
                  : decoded,
              prefix: field.defaultValue == null
                  ? null
                  : 'final data = (value as ({Object? value})).value;',
            ),
            _converter(
              write,
              inner,
              _jsonValue,
              _encode(
                field.type,
                field.tracksPresence ? 'value.value' : 'value',
              ),
            ),
          ]);
        }
        property(
          field.name,
          _fieldType(field),
          options,
          required: field.isRequired,
          fallback: field.defaultExpression,
        );
      }
      if (dto.fields.any((f) => f.defaultValue != null)) {
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = '_presentValue'
              ..static = true
              ..returns = _jsonValue
              ..requiredParameters.addAll([
                _arg('json', cb.refer('Map')),
                _arg('key', cb.refer('String')),
              ])
              ..lambda = true
              ..body = const cb.Code(
                'json.containsKey(key) ? (value: json[key]) : null',
              ),
          ),
        );
      }
      var encoded = '_\$${name}ToJson(this)';
      if (dto.extraValueType case final extra?) {
        c.fields.add(
          cb.Field(
            (f) => f
              ..name = '_knownKeys'
              ..static = true
              ..modifier = cb.FieldModifier.constant
              ..assignment = cb.Code(
                "<String>{${[...dto.fields.map((f) => _literal(f.wireName ?? f.name)), ...dto.ignoredWireKeys.map(_literal)].join(',')}}",
              ),
          ),
        );
        c.methods.add(
          cb.Method(
            (m) => m
              ..name = '_extras'
              ..static = true
              ..returns = _jsonValue
              ..lambda = true
              ..requiredParameters.addAll([
                _arg('map', cb.refer('Map')),
                _arg('_', cb.refer('String')),
              ])
              ..body = const cb.Code(
                '{for (final entry in map.entries) if (!_knownKeys.contains(entry.key)) entry.key as String: entry.value}',
              ),
          ),
        );
        final map = DartTypeReference(
          symbol: 'Map',
          typeArguments: [_stringType, extra],
        );
        c.methods.add(
          _converter(
            '_readExtras',
            _jsonValue,
            _buildType(map),
            json._decode(map, 'value'),
          ),
        );
        property('additionalProperties', _buildType(map), [
          'readValue: $name._extras',
          'fromJson: $name._readExtras',
          'includeToJson: false',
        ], fallback: 'const {}');
        encoded =
            "{for (final entry in additionalProperties.entries) if (!_knownKeys.contains(entry.key)) entry.key: ${_encode(extra, 'entry.value')}, ...$encoded}";
      }
      final Set<String> excluded = {
        ...dto.ignoredWireKeys,
        for (final field in dto.fields)
          if (field.fixedValue != null) field.wireName ?? field.name,
      };
      final input = excluded.isEmpty
          ? 'json'
          : "{for (final entry in json.entries) if (!const <String>{${excluded.map(_literal).join(',')}}.contains(entry.key)) entry.key: entry.value}";
      final String checks = _fixedChecks(dto);
      final decode = '_\$${name}FromJson($input)';
      final List<String> fixedEntries = [
        for (final field in dto.fields)
          if (field.fixedValue case final fixed?)
            '${_literal(field.wireName ?? field.name)}: ${_literal(fixed.value)}',
      ];
      if (fixedEntries.isNotEmpty) {
        encoded = '{...$encoded, ${fixedEntries.join(',')}}';
      }
      c.constructors.addAll([
        constructor.build(),
        json._fromJson(
          _jsonMap,
          checks.isEmpty ? decode : '${checks}return $decode;',
          lambda: checks.isEmpty,
        ),
      ]);
      c.methods.add(_checkedToJson(dto, json._toJson(_jsonMap, encoded)));
    });
    return serializer == DtoSerializer.freezed
        ? _primaryDto(_documentClass(declaration, model))
        : declaration;
  }

  bool _nativeJson(DartTypeReference type) => switch (type.symbol) {
    'List' || 'Map' => _nativeJson(type.typeArguments.last),
    'String' || 'bool' || 'num' || 'Object' => true,
    _ =>
      nativeEnums.contains(type.symbol) ||
          json.objectTypes.contains(type.symbol),
  };

  cb.Spec buildEnum(DartEnumModel model) {
    if (model.openNames != null) {
      return _openEnum(model);
    }
    final cb.Enum plain = json.buildEnum(model);
    if (serializer == DtoSerializer.dartMappable) {
      return plain.rebuild((e) {
        e.annotations.add(cb.refer('MappableEnum()'));
        e.values.replace(
          plain.values.map(
            (v) => v.rebuild(
              (b) => b.annotations.add(
                cb.refer('MappableValue(${_literal(model.values[v.name])})'),
              ),
            ),
          ),
        );
      });
    }
    if (serializer != DtoSerializer.plain && nativeEnums.contains(model.name)) {
      return plain.rebuild((e) {
        e.annotations.add(
          cb.refer("JsonEnum(alwaysCreate: true, valueField: 'value')"),
        );
        final map = '_\$${model.name}EnumMap';
        e.constructors.replace(
          plain.constructors.map(
            (ctor) => ctor.name == 'fromJson'
                ? json._fromJson(
                    _jsonValue,
                    '\$enumDecode($map, json)',
                    lambda: true,
                  )
                : ctor,
          ),
        );
        e.methods.replace([json._toJson(cb.refer('Object'), '$map[this]!')]);
      });
    }
    return plain;
  }

  cb.Parameter _arg(String name, cb.Reference type) => cb.Parameter(
    (p) => p
      ..name = name
      ..type = type,
  );

  cb.Method _converter(
    String name,
    cb.Reference input,
    cb.Reference output,
    String body, {
    String? prefix,
  }) => cb.Method(
    (m) => m
      ..name = name
      ..static = true
      ..returns = output
      ..lambda = prefix == null
      ..requiredParameters.add(_arg('value', input))
      ..body = cb.Code(prefix == null ? body : '$prefix return $body;'),
  );

  cb.Class mappedDto(cb.Class plain) => plain.rebuild((c) {
    final String name = plain.name;
    c.annotations.add(
      cb.refer(
        'MappableClass(${variantTags.containsKey(name) ? 'discriminatorValue: ${_literal(variantTags[name])}, ' : ''}hook: _WireCodec($name._fromWire), generateMethods: GenerateMethods.all & ~GenerateMethods.encode)',
      ),
    );
    c.mixins.add(cb.refer('${name}Mappable'));
    c.implements.add(cb.refer('_WireObject'));
    c.constructors.replace(
      plain.constructors.map(
        (constructor) => constructor.name == 'fromJson'
            ? constructor.rebuild((b) => b.name = '_fromWire')
            : constructor,
      ),
    );
    c.constructors.add(
      json._fromJson(_jsonMap, '${name}Mapper.fromMap(json)', lambda: true),
    );
    c.methods.replace(
      plain.methods.map(
        (method) => method.name == 'toJson'
            ? method.rebuild((m) => m.name = '_toWire')
            : method,
      ),
    );
    c.methods.add(json._toJson(_jsonMap, 'toMap()'));
    c.methods.add(
      cb.Method(
        (m) => m
          ..name = 'toMap'
          ..returns = _jsonMap
          ..lambda = true
          ..body = cb.Code(
            '${name}Mapper.ensureInitialized().encodeMap<$name>(this)',
          ),
      ),
    );
  });

  void addMappers(cb.LibraryBuilder library, DartLibraryModel model) {
    if (!model.dtos.any((dto) => dto.json)) {
      return;
    }
    if (tags.isNotEmpty) {
      library.body.add(
        const cb.Code('''
class _TagAliases extends MappingHook {
  const _TagAliases(this.key, this.aliases, this.tags, this.fallback);
  final String key;
  final Map<String, _WireObject Function(Map<String, Object?>)> aliases;
  final Set<String> tags;
  final _WireObject Function(Map<String, Object?>)? fallback;

  @override
  Object? beforeDecode(Object? value) {
    final json = value as Map<String, Object?>;
    final tag = json[key];
    if (tags.contains(tag)) {
      return json;
    }
    final decode = aliases[tag] ?? fallback;
    return decode == null ? json : decode(json);
  }
}
'''),
      );
    }
    library.body.add(
      const cb.Code('''
abstract interface class _WireObject {
  Map<String, Object?> _toWire();
}

class _WireCodec extends MappingHook {
  const _WireCodec(this.read);
  final _WireObject Function(Map<String, Object?>) read;

  @override
  Object? beforeDecode(Object? value) => read(value as Map<String, Object?>);

  @override
  Object? beforeEncode(Object? value) => (value as _WireObject)._toWire();
}
'''),
    );
  }
}
