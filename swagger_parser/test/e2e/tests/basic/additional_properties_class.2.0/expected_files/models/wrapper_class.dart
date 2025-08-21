// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'value_class.dart';

part 'wrapper_class.freezed.dart';
part 'wrapper_class.g.dart';

@Freezed()
class WrapperClass with _$WrapperClass {
  const factory WrapperClass({
    required Map<String, ValueClass> map,
  }) = _WrapperClass;

  factory WrapperClass.fromJson(Map<String, Object?> json) =>
      _$WrapperClassFromJson(json);
}
