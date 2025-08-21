// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/fallback_client.dart';
import 'clients/client2_client.dart';
import 'clients/parcel_pending_client.dart';

///  `v0.0.0 (v1)`
class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '0.0.0 (v1)';

  FallbackClient? _fallback;
  Client2Client? _client2;
  ParcelPendingClient? _parcelPending;

  FallbackClient get fallback =>
      _fallback ??= FallbackClient(_dio, baseUrl: _baseUrl);

  Client2Client get client2 =>
      _client2 ??= Client2Client(_dio, baseUrl: _baseUrl);

  ParcelPendingClient get parcelPending =>
      _parcelPending ??= ParcelPendingClient(_dio, baseUrl: _baseUrl);
}
