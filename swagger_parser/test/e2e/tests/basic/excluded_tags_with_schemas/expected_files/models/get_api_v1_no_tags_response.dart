// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_api_v1_no_tags_response.freezed.dart';
part 'get_api_v1_no_tags_response.g.dart';

@Freezed()
class GetApiV1NoTagsResponse with _$GetApiV1NoTagsResponse {
  const factory GetApiV1NoTagsResponse({
    @JsonKey(includeIfNull: false) String? result,
  }) = _GetApiV1NoTagsResponse;

  factory GetApiV1NoTagsResponse.fromJson(Map<String, Object?> json) =>
      _$GetApiV1NoTagsResponseFromJson(json);
}
