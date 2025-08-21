// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/new_pet_dto.dart';
import '../models/pet_dto.dart';

part 'fallback_client.g.dart';

@RestApi()
abstract class FallbackClient {
  factory FallbackClient(Dio dio, {String? baseUrl}) = _FallbackClient;

  /// Returns all pets from the system that the user has access to.
  ///
  /// [tags] - tags to filter by.
  ///
  /// [limit] - maximum number of results to return.
  @GET('/pets')
  Future<List<PetDto>> findPets({
    @Query('tags') List<String>? tags,
    @Query('limit') int? limit,
  });

  /// Creates a new pet in the store.  Duplicates are allowed.
  ///
  /// [pet] - PetDto to add to the store.
  @POST('/pets')
  Future<PetDto> addPet({
    @Body() required NewPetDto pet,
  });

  /// Returns a user based on a single ID, if the user does not have access to the pet.
  ///
  /// [id] - ID of pet to fetch.
  @GET('/pets/{id}')
  Future<PetDto> findPetById({
    @Path('id') required int id,
  });

  /// deletes a single pet based on the ID supplied.
  ///
  /// [id] - ID of pet to delete.
  @DELETE('/pets/{id}')
  Future<void> deletePet({
    @Path('id') required int id,
  });
}
