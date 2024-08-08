// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'example.dart';

part 'object1.freezed.dart';
part 'object1.g.dart';

@Freezed()
class Object1 with _$Object1 {
  const factory Object1({
    required List<Example> list1,
    required List<Map<String, Example>> list2,
    required String? name,
    required String lastname,
  }) = _Object1;

  factory Object1.fromJson(Map<String, Object?> json) =>
      _$Object1FromJson(json);
}
