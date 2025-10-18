// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'fruits.dart';

part 'nullable_enum_in_object.freezed.dart';
part 'nullable_enum_in_object.g.dart';

@Freezed()
class NullableEnumInObject with _$NullableEnumInObject {
  const factory NullableEnumInObject({
    @JsonKey(includeIfNull: false) Fruits? fruits,
  }) = _NullableEnumInObject;

  factory NullableEnumInObject.fromJson(Map<String, Object?> json) =>
      _$NullableEnumInObjectFromJson(json);
}
