// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'basic_group_type.dart';

part 'basic_group.freezed.dart';
part 'basic_group.g.dart';

@Freezed()
class BasicGroup with _$BasicGroup {
  const factory BasicGroup({
    required BasicGroupType type,
    required String name,
  }) = _BasicGroup;

  factory BasicGroup.fromJson(Map<String, Object?> json) =>
      _$BasicGroupFromJson(json);
}
