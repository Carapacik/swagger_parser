// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enum_class.dart';

part 'one_of_element.freezed.dart';
part 'one_of_element.g.dart';

@Freezed()
class OneOfElement with _$OneOfElement {
  const factory OneOfElement({
    required EnumClass allClass,
    required EnumClass oneClass,
    required int allType,
    required DateTime anyType,
    required EnumClass? nullableButRequiredClass,
    @Default([]) List<EnumClass>? nullableType,
    EnumClass? nullableClass,
    @Default(EnumClass.value1) EnumClass anyClass,
    @Default([]) List<EnumClass> oneType,
  }) = _OneOfElement;

  factory OneOfElement.fromJson(Map<String, Object?> json) =>
      _$OneOfElementFromJson(json);
}
