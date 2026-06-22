// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/get_pets_response_union.dart';

part 'pets_client.g.dart';

@RestApi()
abstract class PetsClient {
  factory PetsClient(Dio dio, {String? baseUrl}) = _PetsClient;

  /// List pets (discriminated union); the Cat variant nests its own union.
  @GET('/pets')
  Future<List<GetPetsResponseUnion>> getPets();
}
