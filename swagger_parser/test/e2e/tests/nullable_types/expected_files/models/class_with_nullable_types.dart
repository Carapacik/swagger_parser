// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'p3.dart';
import 'p3_all_of.dart';
import 'p3_any_of.dart';
import 'p3_list.dart';
import 'p3_one_of.dart';
import 'p3n.dart';

part 'class_with_nullable_types.freezed.dart';
part 'class_with_nullable_types.g.dart';

@Freezed()
class ClassWithNullableTypes with _$ClassWithNullableTypes {
  const factory ClassWithNullableTypes({
    @JsonKey(name: 'valid_int') required int validInt,
    @JsonKey(name: 'valid_string') required String validString,
    @JsonKey(name: 'valid_array') required List<String> validArray,
    required String p1,
    required List<String> p2,
    @JsonKey(name: 'p2_null') required List<String>? p2Null,
    @JsonKey(name: 'p2_null_item') required List<List<String?>> p2NullItem,
    @JsonKey(name: 'p2_null_all') required List<String?>? p2NullAll,
    required P3 p3,
    @JsonKey(name: 'p1_list') required String? p1List,
    @JsonKey(name: 'p2_list') required List<String?>? p2List,
    @JsonKey(name: 'p3_list') required P3List? p3List,
    @JsonKey(name: 'nonNull_anyOf') required dynamic nonNullAnyOf,
    @JsonKey(name: 'required_null_anyOf') required String? requiredNullAnyOf,
    @JsonKey(name: 'p1_anyOf') required String? p1AnyOf,
    @JsonKey(name: 'p2_anyOf') required List<String?>? p2AnyOf,
    @JsonKey(name: 'p3_anyOf') required P3AnyOf? p3AnyOf,
    @JsonKey(name: 'p1_oneOf') required String? p1OneOf,
    @JsonKey(name: 'p2_oneOf') required List<String?>? p2OneOf,
    @JsonKey(name: 'p3_oneOf') required P3OneOf? p3OneOf,
    @JsonKey(name: 'p1_allOf') required String? p1AllOf,
    @JsonKey(name: 'p2_allOf') required List<String?>? p2AllOf,
    @JsonKey(name: 'p3_allOf') required P3AllOf? p3AllOf,
    @JsonKey(name: 'p1_n') String? p1N,
    @JsonKey(name: 'p2_n') List<String?>? p2N,
    @JsonKey(name: 'p3_n') P3n? p3N,
    @JsonKey(name: 'optional_null_anyOf') String? optionalNullAnyOf,
  }) = _ClassWithNullableTypes;

  factory ClassWithNullableTypes.fromJson(Map<String, Object?> json) =>
      _$ClassWithNullableTypesFromJson(json);
  static const int validIntMin = 0;
  static const int validIntMax = 100;
  static const int validStringMinLength = 0;
  static const int validStringMaxLength = 100;
  static const String validStringPattern = r"^[a-zA-Z0-9]*$";
  static const int validArrayMinItems = 0;
  static const int validArrayMaxItems = 100;
  static const bool validArrayUniqueItems = true;
}

extension ClassWithNullableTypesValidationX on ClassWithNullableTypes {
  bool validate() {
    try {
      if (validInt < ClassWithNullableTypes.validIntMin) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (validInt > ClassWithNullableTypes.validIntMax) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (validString.length < ClassWithNullableTypes.validStringMinLength) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (validString.length > ClassWithNullableTypes.validStringMaxLength) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (!RegExp(ClassWithNullableTypes.validStringPattern)
          .hasMatch(validString)) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (validArray.length < ClassWithNullableTypes.validArrayMinItems) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (validArray.length > ClassWithNullableTypes.validArrayMaxItems) {
        return false;
      }
    } catch (e) {
      return false;
    }
    try {
      if (ClassWithNullableTypes.validArrayUniqueItems &&
          validArray.toSet().length != validArray.length) {
        return false;
      }
    } catch (e) {
      return false;
    }
    return true;
  }
}
