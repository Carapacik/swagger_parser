// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'included_nested.dart';
import 'audit_data.dart';

part 'api_v1_tagged_as_exclude_but_included_should_be_included_request_body.freezed.dart';
part 'api_v1_tagged_as_exclude_but_included_should_be_included_request_body.g.dart';

@Freezed()
class ApiV1TaggedAsExcludeButIncludedShouldBeIncludedRequestBody
    with _$ApiV1TaggedAsExcludeButIncludedShouldBeIncludedRequestBody {
  const factory ApiV1TaggedAsExcludeButIncludedShouldBeIncludedRequestBody({
    /// This field should be included (include tag wins)
    required String includedField,
    @JsonKey(includeIfNull: false) IncludedNested? includedNested,
    @JsonKey(includeIfNull: false) AuditData? auditData,
  }) = _ApiV1TaggedAsExcludeButIncludedShouldBeIncludedRequestBody;

  factory ApiV1TaggedAsExcludeButIncludedShouldBeIncludedRequestBody.fromJson(
          Map<String, Object?> json) =>
      _$ApiV1TaggedAsExcludeButIncludedShouldBeIncludedRequestBodyFromJson(
          json);
}
