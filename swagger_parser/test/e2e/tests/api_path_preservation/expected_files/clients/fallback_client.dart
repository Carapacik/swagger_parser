// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_api_v1_app_user_point_transactions_response.dart';
import '../models/user_point_balance.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Get user point balance.
  ///
  /// This endpoint path should remain as /api/v1/app/user_point_balance (snake_case).
  /// even though the schema name is UserPointBalance (PascalCase).
  @GET('/api/v1/app/user_point_balance')
  Future<UserPointBalance> getUserPointBalance();

  /// Get user point transactions.
  ///
  /// This endpoint path should remain as /api/v1/app/user_point_transactions (snake_case).
  /// even though the schema includes UserPointTransaction (PascalCase).
  @GET('/api/v1/app/user_point_transactions')
  Future<GetApiV1AppUserPointTransactionsResponse> getUserPointTransactions({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit = 20,
  });
}
