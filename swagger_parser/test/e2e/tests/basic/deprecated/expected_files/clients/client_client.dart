// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/pet.dart';

part 'client_client.g.dart';

@RestApi()
abstract class ClientClient {
  factory ClientClient(Dio dio, {String? baseUrl}) = _ClientClient;

  @GET('/pets')
  Future<List<Pet>> findPets({
    @Deprecated('This is marked as deprecated')
    @Query('deprecatedQueryParameter')
    required int deprecatedQueryParameter,
  });
}
