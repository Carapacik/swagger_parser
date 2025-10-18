// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'nested_included.freezed.dart';
part 'nested_included.g.dart';

@Freezed()
class NestedIncluded with _$NestedIncluded {
  const factory NestedIncluded({
    @JsonKey(includeIfNull: false) String? innerField,
  }) = _NestedIncluded;

  factory NestedIncluded.fromJson(Map<String, Object?> json) =>
      _$NestedIncludedFromJson(json);
}
