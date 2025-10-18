// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum_class.dart';

part 'one_of_element.freezed.dart';
part 'one_of_element.g.dart';

@Freezed()
class OneOfElement with _$OneOfElement {
  const factory OneOfElement({
    @JsonKey(includeIfNull: true) required EnumClass? nullableButRequiredClass,
    @JsonKey(includeIfNull: true)
    required List<int>? requiredNullableListNonNullItems,
    @JsonKey(includeIfNull: true)
    required List<int?>? requiredNullableListNullableItems,
    @Default(EnumClass.value1) EnumClass anyClass,
    @Default([]) List<EnumClass> oneType,
    @JsonKey(includeIfNull: true) @Default([]) List<EnumClass>? nullableType,
    @JsonKey(includeIfNull: false) EnumClass? allClass,
    @JsonKey(includeIfNull: false) EnumClass? oneClass,
    @JsonKey(includeIfNull: false) int? allType,
    @JsonKey(includeIfNull: false) DateTime? anyType,
    @JsonKey(includeIfNull: false) EnumClass? nullableClass,
    @JsonKey(includeIfNull: false) List<int>? nullableListNonNullItems,
    @JsonKey(includeIfNull: false) List<int?>? nullableListNullableItems,
  }) = _OneOfElement;

  factory OneOfElement.fromJson(Map<String, Object?> json) =>
      _$OneOfElementFromJson(json);
}
