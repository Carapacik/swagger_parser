// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_whats_new_items_response.freezed.dart';
part 'get_whats_new_items_response.g.dart';

@Freezed()
class GetWhatsNewItemsResponse with _$GetWhatsNewItemsResponse {
  const factory GetWhatsNewItemsResponse({
    @JsonKey(includeIfNull: false) String? id,
    @JsonKey(includeIfNull: false) String? title,
  }) = _GetWhatsNewItemsResponse;

  factory GetWhatsNewItemsResponse.fromJson(Map<String, Object?> json) =>
      _$GetWhatsNewItemsResponseFromJson(json);
}
