// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_parcel_pending_webhook_buildings_building_id_response.freezed.dart';
part 'get_parcel_pending_webhook_buildings_building_id_response.g.dart';

@Freezed()
class GetParcelPendingWebhookBuildingsBuildingIdResponse
    with _$GetParcelPendingWebhookBuildingsBuildingIdResponse {
  const factory GetParcelPendingWebhookBuildingsBuildingIdResponse({
    @JsonKey(name: 'webhookURL') String? webhookUrl,
  }) = _GetParcelPendingWebhookBuildingsBuildingIdResponse;

  factory GetParcelPendingWebhookBuildingsBuildingIdResponse.fromJson(
          Map<String, Object?> json) =>
      _$GetParcelPendingWebhookBuildingsBuildingIdResponseFromJson(json);
}
