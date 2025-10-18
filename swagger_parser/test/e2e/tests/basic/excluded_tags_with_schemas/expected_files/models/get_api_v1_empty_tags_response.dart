// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_api_v1_empty_tags_response.freezed.dart';
part 'get_api_v1_empty_tags_response.g.dart';

@Freezed()
class GetApiV1EmptyTagsResponse with _$GetApiV1EmptyTagsResponse {
  const factory GetApiV1EmptyTagsResponse({
    @JsonKey(includeIfNull: false) String? value,
  }) = _GetApiV1EmptyTagsResponse;

  factory GetApiV1EmptyTagsResponse.fromJson(Map<String, Object?> json) =>
      _$GetApiV1EmptyTagsResponseFromJson(json);
}
