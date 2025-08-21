// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'another_class.freezed.dart';
part 'another_class.g.dart';

@Freezed()
class AnotherClass with _$AnotherClass {
  const factory AnotherClass({
    required int id,
    required String name,
  }) = _AnotherClass;

  factory AnotherClass.fromJson(Map<String, Object?> json) =>
      _$AnotherClassFromJson(json);
}
