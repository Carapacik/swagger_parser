// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'included_data.dart';

part 'get_api_v1_tagged_as_exclude_but_included_should_be_included_response.freezed.dart';
part 'get_api_v1_tagged_as_exclude_but_included_should_be_included_response.g.dart';

@Freezed()
class GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponse
    with _$GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponse {
  const factory GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponse({
    required String includedResponse,
    IncludedData? includedData,
  }) = _GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponse;

  factory GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponse.fromJson(
          Map<String, Object?> json) =>
      _$GetApiV1TaggedAsExcludeButIncludedShouldBeIncludedResponseFromJson(
          json);
}
