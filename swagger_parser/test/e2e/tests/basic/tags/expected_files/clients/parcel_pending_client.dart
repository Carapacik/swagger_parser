// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/api_parcel_pending_building_settings.dart';
import '../models/api_parcel_pending_building_settings_request.dart';
import '../models/get_parcel_pending_webhook_buildings_building_id_response.dart';

part 'parcel_pending_client.g.dart';

@RestApi()
abstract class ParcelPendingClient {
  factory ParcelPendingClient(Dio dio, {String? baseUrl}) =
      _ParcelPendingClient;

  /// get Parcel Pending webhook URL.
  ///
  /// [buildingId] - Identifier for an existing building.
  @GET('/parcel-pending-webhook/buildings/{buildingId}')
  Future<GetParcelPendingWebhookBuildingsBuildingIdResponse>
      getParcelPendingWebhookUrl({
    @Path('buildingId') required String buildingId,
  });

  /// Retrieve the ParcelPending settings of a building.
  ///
  /// [buildingId] - Identifier for an existing building.
  ///
  /// [projectId] - Identifier for an existing project.
  @GET('/projects/{projectId}/buildings/{buildingId}/parcel-pending/settings')
  Future<ApiParcelPendingBuildingSettings> getParcelPendingBuildingSettings({
    @Path('buildingId') required String buildingId,
    @Path('projectId') required String projectId,
  });

  /// Create or update ParcelPending settings of a building.
  ///
  /// [buildingId] - Identifier for an existing building.
  ///
  /// [projectId] - Identifier for an existing project.
  @POST('/projects/{projectId}/buildings/{buildingId}/parcel-pending/settings')
  Future<ApiParcelPendingBuildingSettings>
      createUpdateParcelPendingBuildingSettings({
    @Path('buildingId') required String buildingId,
    @Path('projectId') required String projectId,
    @Body() required ApiParcelPendingBuildingSettingsRequest body,
  });
}
