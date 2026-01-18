// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'nested_included.dart';
import 'metadata.dart';

part 'api_v1_not_tagged_should_be_included_request_body.freezed.dart';
part 'api_v1_not_tagged_should_be_included_request_body.g.dart';

@Freezed()
class ApiV1NotTaggedShouldBeIncludedRequestBody
    with _$ApiV1NotTaggedShouldBeIncludedRequestBody {
  const factory ApiV1NotTaggedShouldBeIncludedRequestBody({
    /// This field should be included
    required String includedField,
    @JsonKey(includeIfNull: false) NestedIncluded? nestedIncluded,
    @JsonKey(includeIfNull: false) Metadata? metadata,
  }) = _ApiV1NotTaggedShouldBeIncludedRequestBody;

  factory ApiV1NotTaggedShouldBeIncludedRequestBody.fromJson(
          Map<String, Object?> json) =>
      _$ApiV1NotTaggedShouldBeIncludedRequestBodyFromJson(json);
}
