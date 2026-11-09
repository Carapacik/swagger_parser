/// An explicitly present JSON value. JsonValue(null) differs from an absent
/// optional JsonValue field. Containers are copied and recursively immutable.
final class JsonValue(Object? value) {
  /// Copies a JSON value and freezes its nested lists and maps.
  this;

  /// The immutable value, including explicit JSON null.
  final Object? value = _freeze(value);

  /// Returns a detached JSON representation.
  Object? toJson() => _copy(value);

  static Object? _freeze(Object? value) => switch (value) {
    null || String() || bool() || int() => value,
    double() when value.isFinite => value,
    List<Object?>() => List<Object?>.unmodifiable(value.map(_freeze)),
    Map<String, Object?>() => Map<String, Object?>.unmodifiable(
      value.map((key, value) => MapEntry(key, _freeze(value))),
    ),
    _ => throw ArgumentError.value(
      value,
      'value',
      'Expected a finite JSON value',
    ),
  };

  static Object? _copy(Object? value) => switch (value) {
    List<Object?>() => value.map(_copy).toList(),
    Map<String, Object?>() => value.map(
      (key, value) => MapEntry(key, _copy(value)),
    ),
    _ => value,
  };
}
