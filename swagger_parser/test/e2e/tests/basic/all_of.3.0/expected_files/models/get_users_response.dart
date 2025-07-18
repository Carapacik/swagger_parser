// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'cursor_paginated_dto.dart';
import 'user_dto.dart';

part 'get_users_response.freezed.dart';
part 'get_users_response.g.dart';

@Freezed()
class GetUsersResponse with _$GetUsersResponse {
  const factory GetUsersResponse({
    required num? nextCursor,
    required String? previousCursor,
    required List<UserDto> data,
  }) = _GetUsersResponse;

  factory GetUsersResponse.fromJson(Map<String, Object?> json) =>
      _$GetUsersResponseFromJson(json);
}
