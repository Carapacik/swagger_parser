// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'category.dart';

part 'included_data.freezed.dart';
part 'included_data.g.dart';

@Freezed()
class IncludedData with _$IncludedData {
  const factory IncludedData({
    @JsonKey(includeIfNull: false) String? dataField,
    @JsonKey(includeIfNull: false) Category? category,
    @JsonKey(includeIfNull: false) int? count,
  }) = _IncludedData;

  factory IncludedData.fromJson(Map<String, Object?> json) =>
      _$IncludedDataFromJson(json);
}
