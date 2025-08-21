// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/pet.dart';

part 'pets_client.g.dart';

@RestApi()
abstract class PetsClient {
  factory PetsClient(Dio dio, {String? baseUrl}) = _PetsClient;

  @GET('/api/v1/pets')
  Future<List<Pet>> getPets();
}
