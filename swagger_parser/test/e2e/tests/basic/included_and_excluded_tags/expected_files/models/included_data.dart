// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'level.dart';

part 'included_data.freezed.dart';
part 'included_data.g.dart';

@Freezed()
class IncludedData with _$IncludedData {
  const factory IncludedData({
    String? dataField,
    Level? level,
    int? priority,
  }) = _IncludedData;

  factory IncludedData.fromJson(Map<String, Object?> json) =>
      _$IncludedDataFromJson(json);
}
