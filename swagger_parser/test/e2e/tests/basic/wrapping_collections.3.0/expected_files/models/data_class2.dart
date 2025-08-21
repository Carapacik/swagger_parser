// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'data_class1.dart';

part 'data_class2.freezed.dart';
part 'data_class2.g.dart';

@Freezed()
class DataClass2 with _$DataClass2 {
  const factory DataClass2({
    required List<Map<String, List<List<Map<String, DataClass1>>>>> errors,
    String? title,
  }) = _DataClass2;

  factory DataClass2.fromJson(Map<String, Object?> json) =>
      _$DataClass2FromJson(json);
}
