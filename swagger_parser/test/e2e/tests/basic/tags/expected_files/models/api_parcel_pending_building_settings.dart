// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_parcel_pending_building_settings.freezed.dart';
part 'api_parcel_pending_building_settings.g.dart';

@Freezed()
class ApiParcelPendingBuildingSettings with _$ApiParcelPendingBuildingSettings {
  const factory ApiParcelPendingBuildingSettings({
    required bool isDellaManaged,
    String? externalPropertyId,
    String? externalBuildingName,
  }) = _ApiParcelPendingBuildingSettings;

  factory ApiParcelPendingBuildingSettings.fromJson(
          Map<String, Object?> json) =>
      _$ApiParcelPendingBuildingSettingsFromJson(json);
}
