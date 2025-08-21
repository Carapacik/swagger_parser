// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'long_tag_response.freezed.dart';
part 'long_tag_response.g.dart';

@Freezed()
class LongTagResponse with _$LongTagResponse {
  const factory LongTagResponse({
    String? data,
    DateTime? timestamp,
  }) = _LongTagResponse;

  factory LongTagResponse.fromJson(Map<String, Object?> json) =>
      _$LongTagResponseFromJson(json);
}
