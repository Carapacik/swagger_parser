// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'value_class.freezed.dart';
part 'value_class.g.dart';

@Freezed()
class ValueClass with _$ValueClass {
  const factory ValueClass({
    /// A test property
    required String testProp,
  }) = _ValueClass;

  factory ValueClass.fromJson(Map<String, Object?> json) =>
      _$ValueClassFromJson(json);
}
