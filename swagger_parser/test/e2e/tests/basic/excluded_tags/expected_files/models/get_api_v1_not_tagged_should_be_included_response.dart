// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'included_data.dart';

part 'get_api_v1_not_tagged_should_be_included_response.freezed.dart';
part 'get_api_v1_not_tagged_should_be_included_response.g.dart';

@Freezed()
class GetApiV1NotTaggedShouldBeIncludedResponse
    with _$GetApiV1NotTaggedShouldBeIncludedResponse {
  const factory GetApiV1NotTaggedShouldBeIncludedResponse({
    required String includedResponse,
    @JsonKey(includeIfNull: false) IncludedData? includedData,
  }) = _GetApiV1NotTaggedShouldBeIncludedResponse;

  factory GetApiV1NotTaggedShouldBeIncludedResponse.fromJson(
          Map<String, Object?> json) =>
      _$GetApiV1NotTaggedShouldBeIncludedResponseFromJson(json);
}
