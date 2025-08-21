// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'included_nested.freezed.dart';
part 'included_nested.g.dart';

@Freezed()
class IncludedNested with _$IncludedNested {
  const factory IncludedNested({
    String? includedInner,
  }) = _IncludedNested;

  factory IncludedNested.fromJson(Map<String, Object?> json) =>
      _$IncludedNestedFromJson(json);
}
