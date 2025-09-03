// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'example_parsable.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExampleParsable {
  /// data
  Map<String, Example> get data;

  /// Create a copy of ExampleParsable
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExampleParsableCopyWith<ExampleParsable> get copyWith =>
      _$ExampleParsableCopyWithImpl<ExampleParsable>(
          this as ExampleParsable, _$identity);

  /// Serializes this ExampleParsable to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExampleParsable &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(data));

  @override
  String toString() {
    return 'ExampleParsable(data: $data)';
  }
}

/// @nodoc
abstract mixin class $ExampleParsableCopyWith<$Res> {
  factory $ExampleParsableCopyWith(
          ExampleParsable value, $Res Function(ExampleParsable) _then) =
      _$ExampleParsableCopyWithImpl;
  @useResult
  $Res call({Map<String, Example> data});
}

/// @nodoc
class _$ExampleParsableCopyWithImpl<$Res>
    implements $ExampleParsableCopyWith<$Res> {
  _$ExampleParsableCopyWithImpl(this._self, this._then);

  final ExampleParsable _self;
  final $Res Function(ExampleParsable) _then;

  /// Create a copy of ExampleParsable
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? data = null,
  }) {
    return _then(_self.copyWith(
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, Example>,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExampleParsable].
extension ExampleParsablePatterns on ExampleParsable {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ExampleParsable value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExampleParsable() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ExampleParsable value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExampleParsable():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ExampleParsable value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExampleParsable() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(Map<String, Example> data)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExampleParsable() when $default != null:
        return $default(_that.data);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(Map<String, Example> data) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExampleParsable():
        return $default(_that.data);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(Map<String, Example> data)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExampleParsable() when $default != null:
        return $default(_that.data);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ExampleParsable implements ExampleParsable {
  const _ExampleParsable({required final Map<String, Example> data})
      : _data = data;
  factory _ExampleParsable.fromJson(Map<String, dynamic> json) =>
      _$ExampleParsableFromJson(json);

  /// data
  final Map<String, Example> _data;

  /// data
  @override
  Map<String, Example> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  /// Create a copy of ExampleParsable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExampleParsableCopyWith<_ExampleParsable> get copyWith =>
      __$ExampleParsableCopyWithImpl<_ExampleParsable>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExampleParsableToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExampleParsable &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_data));

  @override
  String toString() {
    return 'ExampleParsable(data: $data)';
  }
}

/// @nodoc
abstract mixin class _$ExampleParsableCopyWith<$Res>
    implements $ExampleParsableCopyWith<$Res> {
  factory _$ExampleParsableCopyWith(
          _ExampleParsable value, $Res Function(_ExampleParsable) _then) =
      __$ExampleParsableCopyWithImpl;
  @override
  @useResult
  $Res call({Map<String, Example> data});
}

/// @nodoc
class __$ExampleParsableCopyWithImpl<$Res>
    implements _$ExampleParsableCopyWith<$Res> {
  __$ExampleParsableCopyWithImpl(this._self, this._then);

  final _ExampleParsable _self;
  final $Res Function(_ExampleParsable) _then;

  /// Create a copy of ExampleParsable
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? data = null,
  }) {
    return _then(_ExampleParsable(
      data: null == data
          ? _self._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, Example>,
    ));
  }
}

// dart format on
