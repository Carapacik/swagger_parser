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
    @Query('offsetRequiredTrueWithoutDefault')
    required int offsetRequiredTrueWithoutDefault,
    @Query('offsetRequiredFalseWithoutDefault')
    int? offsetRequiredFalseWithoutDefault,
    @Query('offsetNoRequiredWithoutDefault')
    int? offsetNoRequiredWithoutDefault,
    @Query('offsetRequiredFalseWithDefault')
    int? offsetRequiredFalseWithDefault = 0,
    @Query('offsetNoRequiredWithDefault') int? offsetNoRequiredWithDefault = 0,
    @Query('offsetRequiredTrueWithDefault')
    required int offsetRequiredTrueWithDefault,
  });
}
