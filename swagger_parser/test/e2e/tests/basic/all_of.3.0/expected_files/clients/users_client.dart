// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_users_response.dart';

part 'users_client.g.dart';

@RestApi()
abstract class UsersClient {
  factory UsersClient(Dio dio, {String? baseUrl}) = _UsersClient;

  /// Get all users.
  ///
  /// [limit] - The number of items to return.
  ///
  /// [after] - The cursor to start the pagination from.
  ///
  /// [before] - The cursor to end the pagination to.
  @GET('/users')
  Future<GetUsersResponse> getUsers({
    @Query('limit') required num limit,
    @Query('after') String? after,
    @Query('before') String? before,
  });
}
