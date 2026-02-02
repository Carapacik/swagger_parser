// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_point_transaction.dart';

part 'get_api_v1_app_user_point_transactions_response.freezed.dart';
part 'get_api_v1_app_user_point_transactions_response.g.dart';

@Freezed()
class GetApiV1AppUserPointTransactionsResponse
    with _$GetApiV1AppUserPointTransactionsResponse {
  const factory GetApiV1AppUserPointTransactionsResponse({
    required List<UserPointTransaction> data,
    @JsonKey(name: 'next_cursor') String? nextCursor,
  }) = _GetApiV1AppUserPointTransactionsResponse;

  factory GetApiV1AppUserPointTransactionsResponse.fromJson(
          Map<String, Object?> json) =>
      _$GetApiV1AppUserPointTransactionsResponseFromJson(json);
}
