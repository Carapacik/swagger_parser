// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wrapper_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WrapperClass {
  Map<String, ValueClass> get map;

  /// Create a copy of WrapperClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WrapperClassCopyWith<WrapperClass> get copyWith =>
      _$WrapperClassCopyWithImpl<WrapperClass>(
          this as WrapperClass, _$identity);

  /// Serializes this WrapperClass to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WrapperClass &&
            const DeepCollectionEquality().equals(other.map, map));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(map));

  @override
  String toString() {
    return 'WrapperClass(map: $map)';
  }
}

/// @nodoc
abstract mixin class $WrapperClassCopyWith<$Res> {
  factory $WrapperClassCopyWith(
          WrapperClass value, $Res Function(WrapperClass) _then) =
      _$WrapperClassCopyWithImpl;
  @useResult
  $Res call({Map<String, ValueClass> map});
}

/// @nodoc
class _$WrapperClassCopyWithImpl<$Res> implements $WrapperClassCopyWith<$Res> {
  _$WrapperClassCopyWithImpl(this._self, this._then);

  final WrapperClass _self;
  final $Res Function(WrapperClass) _then;

  /// Create a copy of WrapperClass
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? map = null,
  }) {
    return _then(_self.copyWith(
      map: null == map
          ? _self.map
          : map // ignore: cast_nullable_to_non_nullable
              as Map<String, ValueClass>,
    ));
  }
}

/// Adds pattern-matching-related methods to [WrapperClass].
extension WrapperClassPatterns on WrapperClass {
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
    TResult Function(_WrapperClass value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WrapperClass() when $default != null:
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
    TResult Function(_WrapperClass value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WrapperClass():
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
    TResult? Function(_WrapperClass value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WrapperClass() when $default != null:
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
    TResult Function(Map<String, ValueClass> map)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WrapperClass() when $default != null:
        return $default(_that.map);
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
    TResult Function(Map<String, ValueClass> map) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WrapperClass():
        return $default(_that.map);
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
    TResult? Function(Map<String, ValueClass> map)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WrapperClass() when $default != null:
        return $default(_that.map);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WrapperClass implements WrapperClass {
  const _WrapperClass({required final Map<String, ValueClass> map})
      : _map = map;
  factory _WrapperClass.fromJson(Map<String, dynamic> json) =>
      _$WrapperClassFromJson(json);

  final Map<String, ValueClass> _map;
  @override
  Map<String, ValueClass> get map {
    if (_map is EqualUnmodifiableMapView) return _map;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_map);
  }

  /// Create a copy of WrapperClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WrapperClassCopyWith<_WrapperClass> get copyWith =>
      __$WrapperClassCopyWithImpl<_WrapperClass>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WrapperClassToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WrapperClass &&
            const DeepCollectionEquality().equals(other._map, _map));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_map));

  @override
  String toString() {
    return 'WrapperClass(map: $map)';
  }
}

/// @nodoc
abstract mixin class _$WrapperClassCopyWith<$Res>
    implements $WrapperClassCopyWith<$Res> {
  factory _$WrapperClassCopyWith(
          _WrapperClass value, $Res Function(_WrapperClass) _then) =
      __$WrapperClassCopyWithImpl;
  @override
  @useResult
  $Res call({Map<String, ValueClass> map});
}

/// @nodoc
class __$WrapperClassCopyWithImpl<$Res>
    implements _$WrapperClassCopyWith<$Res> {
  __$WrapperClassCopyWithImpl(this._self, this._then);

  final _WrapperClass _self;
  final $Res Function(_WrapperClass) _then;

  /// Create a copy of WrapperClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? map = null,
  }) {
    return _then(_WrapperClass(
      map: null == map
          ? _self._map
          : map // ignore: cast_nullable_to_non_nullable
              as Map<String, ValueClass>,
    ));
  }
}

// dart format on
