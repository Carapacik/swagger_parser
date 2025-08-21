// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'another_class.dart';

part 'class_name.freezed.dart';
part 'class_name.g.dart';

@Freezed()
class ClassName with _$ClassName {
  const factory ClassName({
    required int id,
    required AnotherClass another,
  }) = _ClassName;

  factory ClassName.fromJson(Map<String, Object?> json) =>
      _$ClassNameFromJson(json);
}
