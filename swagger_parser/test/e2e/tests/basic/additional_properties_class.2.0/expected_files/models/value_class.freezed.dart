// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'value_class.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ValueClass {
  /// A test property
  String get testProp;

  /// Create a copy of ValueClass
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ValueClassCopyWith<ValueClass> get copyWith =>
      _$ValueClassCopyWithImpl<ValueClass>(this as ValueClass, _$identity);

  /// Serializes this ValueClass to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ValueClass &&
            (identical(other.testProp, testProp) ||
                other.testProp == testProp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, testProp);

  @override
  String toString() {
    return 'ValueClass(testProp: $testProp)';
  }
}

/// @nodoc
abstract mixin class $ValueClassCopyWith<$Res> {
  factory $ValueClassCopyWith(
          ValueClass value, $Res Function(ValueClass) _then) =
      _$ValueClassCopyWithImpl;
  @useResult
  $Res call({String testProp});
}

/// @nodoc
class _$ValueClassCopyWithImpl<$Res> implements $ValueClassCopyWith<$Res> {
  _$ValueClassCopyWithImpl(this._self, this._then);

  final ValueClass _self;
  final $Res Function(ValueClass) _then;

  /// Create a copy of ValueClass
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? testProp = null,
  }) {
    return _then(_self.copyWith(
      testProp: null == testProp
          ? _self.testProp
          : testProp // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [ValueClass].
extension ValueClassPatterns on ValueClass {
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
    TResult Function(_ValueClass value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ValueClass() when $default != null:
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
    TResult Function(_ValueClass value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ValueClass():
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
    TResult? Function(_ValueClass value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ValueClass() when $default != null:
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
    TResult Function(String testProp)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ValueClass() when $default != null:
        return $default(_that.testProp);
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
    TResult Function(String testProp) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ValueClass():
        return $default(_that.testProp);
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
    TResult? Function(String testProp)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ValueClass() when $default != null:
        return $default(_that.testProp);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ValueClass implements ValueClass {
  const _ValueClass({required this.testProp});
  factory _ValueClass.fromJson(Map<String, dynamic> json) =>
      _$ValueClassFromJson(json);

  /// A test property
  @override
  final String testProp;

  /// Create a copy of ValueClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ValueClassCopyWith<_ValueClass> get copyWith =>
      __$ValueClassCopyWithImpl<_ValueClass>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ValueClassToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ValueClass &&
            (identical(other.testProp, testProp) ||
                other.testProp == testProp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, testProp);

  @override
  String toString() {
    return 'ValueClass(testProp: $testProp)';
  }
}

/// @nodoc
abstract mixin class _$ValueClassCopyWith<$Res>
    implements $ValueClassCopyWith<$Res> {
  factory _$ValueClassCopyWith(
          _ValueClass value, $Res Function(_ValueClass) _then) =
      __$ValueClassCopyWithImpl;
  @override
  @useResult
  $Res call({String testProp});
}

/// @nodoc
class __$ValueClassCopyWithImpl<$Res> implements _$ValueClassCopyWith<$Res> {
  __$ValueClassCopyWithImpl(this._self, this._then);

  final _ValueClass _self;
  final $Res Function(_ValueClass) _then;

  /// Create a copy of ValueClass
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? testProp = null,
  }) {
    return _then(_ValueClass(
      testProp: null == testProp
          ? _self.testProp
          : testProp // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
