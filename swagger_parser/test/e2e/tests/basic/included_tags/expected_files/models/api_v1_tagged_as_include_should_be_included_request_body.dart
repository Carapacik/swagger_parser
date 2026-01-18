// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'nested_included.dart';
import 'anchor_reference.dart';

part 'api_v1_tagged_as_include_should_be_included_request_body.freezed.dart';
part 'api_v1_tagged_as_include_should_be_included_request_body.g.dart';

@Freezed()
class ApiV1TaggedAsIncludeShouldBeIncludedRequestBody
    with _$ApiV1TaggedAsIncludeShouldBeIncludedRequestBody {
  const factory ApiV1TaggedAsIncludeShouldBeIncludedRequestBody({
    /// This field should be included
    required String includedField,
    @JsonKey(includeIfNull: false) NestedIncluded? nestedIncluded,
    @JsonKey(includeIfNull: false) AnchorReference? anchorReference,
  }) = _ApiV1TaggedAsIncludeShouldBeIncludedRequestBody;

  factory ApiV1TaggedAsIncludeShouldBeIncludedRequestBody.fromJson(
          Map<String, Object?> json) =>
      _$ApiV1TaggedAsIncludeShouldBeIncludedRequestBodyFromJson(json);
}
