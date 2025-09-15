// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_api_v1_no_tags_endpoint_response.freezed.dart';
part 'get_api_v1_no_tags_endpoint_response.g.dart';

@Freezed()
class GetApiV1NoTagsEndpointResponse with _$GetApiV1NoTagsEndpointResponse {
  const factory GetApiV1NoTagsEndpointResponse({
    @JsonKey(includeIfNull: false) String? noTagsField,
  }) = _GetApiV1NoTagsEndpointResponse;

  factory GetApiV1NoTagsEndpointResponse.fromJson(Map<String, Object?> json) =>
      _$GetApiV1NoTagsEndpointResponseFromJson(json);
}
