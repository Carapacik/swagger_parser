// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'data_class1.freezed.dart';
part 'data_class1.g.dart';

@Freezed()
class DataClass1 with _$DataClass1 {
  const factory DataClass1({
    required String type,
    required String instance,
    required Map<String, List<String>> errors,
  }) = _DataClass1;

  factory DataClass1.fromJson(Map<String, Object?> json) =>
      _$DataClass1FromJson(json);
}
