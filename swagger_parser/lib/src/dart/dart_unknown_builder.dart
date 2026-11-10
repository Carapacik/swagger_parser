part of 'dart_code_builder.dart';

cb.Code _openEnum(DartEnumModel model) {
  final DartOpenEnumNames names = model.openNames!;
  final String type = names.rawType;
  final Set<String> types = model.types.isEmpty
      ? const {'string', 'number', 'boolean'}
      : model.types;
  final String check = types
      .map(
        (t) => switch (t) {
          'string' => 'json is String',
          'integer' => 'json is int',
          'number' => '(json is num && json.isFinite)',
          'boolean' => 'json is bool',
          _ => 'false',
        },
      )
      .join(' || ');
  return cb.Code('''
enum ${names.values} {
  ${model.values.entries.map((e) => '${e.key}(${_literal(e.value)})').join(',')};
  const ${names.values}(this.value);
  final $type value;
}
sealed class ${model.name} {
  const ${model.name}();
  ${model.values.keys.map((key) => 'static const $key = ${names.known}(${names.values}.$key);').join()}
  factory ${model.name}.fromJson(Object? json) {
    if (!($check)) { throw ArgumentError.value(json, ${_literal(model.name)}); }
    for (final value in ${names.values}.values) {
      if (value.value == json) return ${names.known}(value);
    }
    return ${names.unknown}(json);
  }
  $type toJson();
}
final class ${names.known} extends ${model.name} {
  const ${names.known}(this.value);
  final ${names.values} value;
  @override
  $type toJson() => value.value;
  @override
  bool operator ==(Object other) => other is ${names.known} && other.value == value;
  @override
  int get hashCode => Object.hash(${names.known}, value);
}
final class ${names.unknown} extends ${model.name} {
  const ${names.unknown}(this.rawValue);
  final $type rawValue;
  @override
  $type toJson() => rawValue;
  @override
  bool operator ==(Object other) => other is ${names.unknown} && other.rawValue == rawValue;
  @override
  int get hashCode => Object.hash(${names.unknown}, rawValue);
}
''');
}

cb.Code _unknownUnion(DartUnionModel model) => cb.Code('''
final class ${model.unknownType} implements ${model.name} {
  ${model.unknownType}(Map<String, Object?> json)
      : rawJson = _freezeUnknownJson(json) as Map<String, Object?> {
    if (json[${_literal(model.propertyName)}] is! String) {
      throw ArgumentError(${_literal('Expected a string discriminator: ${model.propertyName}')});
    }
  }
  final Map<String, Object?> rawJson;
  @override
  Map<String, Object?> toJson() => _copyJson(rawJson) as Map<String, Object?>;
}
''');

cb.Code _freezeUnknownJson() => const cb.Code('''
Object? _freezeUnknownJson(Object? value) => switch(value) {
  Map<String, Object?>() => Map<String, Object?>.unmodifiable(
    value.map((key, item) => MapEntry(key, _freezeUnknownJson(item)))),
  List<Object?>() => List<Object?>.unmodifiable(value.map(_freezeUnknownJson)),
  null || String() || bool() => value,
  num() when value.isFinite => value,
  _ => throw ArgumentError('Expected a JSON value.'),
};
''');
