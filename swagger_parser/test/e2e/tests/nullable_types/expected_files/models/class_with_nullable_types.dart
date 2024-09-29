// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'object1.dart';
import 'object2.dart';
import 'object3.dart';
import 'object4.dart';
import 'p3.dart';
import 'p3n.dart';

part 'class_with_nullable_types.freezed.dart';
part 'class_with_nullable_types.g.dart';

@Freezed()
class ClassWithNullableTypes with _$ClassWithNullableTypes {
  const factory ClassWithNullableTypes({
    required String p1,
    required List<String> p2,
    @JsonKey(name: 'p2_null') required List<String>? p2Null,
    @JsonKey(name: 'p2_null_item') required List<List<String?>> p2NullItem,
    @JsonKey(name: 'p2_null_all') required List<String?>? p2NullAll,
    required P3 p3,
    @JsonKey(name: 'p1_list') required String? p1List,
    @JsonKey(name: 'p2_list') required List<String?>? p2List,
    @JsonKey(name: 'p3_list') required Object1? p3List,
    @JsonKey(name: 'nonNull_anyOf') required dynamic nonNullAnyOf,
    @JsonKey(name: 'required_null_anyOf') required String? requiredNullAnyOf,
    @JsonKey(name: 'p1_anyOf') required String? p1AnyOf,
    @JsonKey(name: 'p2_anyOf') required List<String?>? p2AnyOf,
    @JsonKey(name: 'p3_anyOf') required Object2? p3AnyOf,
    @JsonKey(name: 'p1_oneOf') required String? p1OneOf,
    @JsonKey(name: 'p2_oneOf') required List<String?>? p2OneOf,
    @JsonKey(name: 'p3_oneOf') required Object3? p3OneOf,
    @JsonKey(name: 'p1_allOf') required String? p1AllOf,
    @JsonKey(name: 'p2_allOf') required List<String?>? p2AllOf,
    @JsonKey(name: 'p3_allOf') required Object4? p3AllOf,
    @JsonKey(name: 'p1_n') String? p1N,
    @JsonKey(name: 'p2_n') List<String?>? p2N,
    @JsonKey(name: 'p3_n') P3n? p3N,
    @JsonKey(name: 'optional_null_anyOf') String? optionalNullAnyOf,
  }) = _ClassWithNullableTypes;

  factory ClassWithNullableTypes.fromJson(Map<String, Object?> json) =>
      _$ClassWithNullableTypesFromJson(json);
}
