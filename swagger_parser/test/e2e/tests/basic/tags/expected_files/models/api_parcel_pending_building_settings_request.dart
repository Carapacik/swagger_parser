// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_parcel_pending_building_settings_request.freezed.dart';
part 'api_parcel_pending_building_settings_request.g.dart';

@Freezed()
class ApiParcelPendingBuildingSettingsRequest
    with _$ApiParcelPendingBuildingSettingsRequest {
  const factory ApiParcelPendingBuildingSettingsRequest({
    required bool isDellaManaged,
    String? externalPropertyId,
    String? externalBuildingName,
  }) = _ApiParcelPendingBuildingSettingsRequest;

  factory ApiParcelPendingBuildingSettingsRequest.fromJson(
          Map<String, Object?> json) =>
      _$ApiParcelPendingBuildingSettingsRequestFromJson(json);
}
