// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'nested_included.dart';
import 'metadata.dart';

part 'object0.freezed.dart';
part 'object0.g.dart';

@Freezed()
class Object0 with _$Object0 {
  const factory Object0({
    /// This field should be included
    required String includedField,
    @JsonKey(includeIfNull: false) NestedIncluded? nestedIncluded,
    @JsonKey(includeIfNull: false) Metadata? metadata,
  }) = _Object0;

  factory Object0.fromJson(Map<String, Object?> json) =>
      _$Object0FromJson(json);
}
